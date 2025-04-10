library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity csr_registers is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        -- Interface d'accès aux CSRs
        csr_addr        : in  std_logic_vector(11 downto 0); -- Adresse du CSR (12 bits)
        csr_write_data  : in  EncodedWord;                   -- Données à écrire dans le CSR
        csr_read_data   : out EncodedWord;                   -- Données lues du CSR
        csr_write_en    : in  std_logic;                     -- Signal d'écriture CSR
        csr_read_en     : in  std_logic;                     -- Signal de lecture CSR
        csr_set_en      : in  std_logic;                     -- Signal pour l'opération SET (CSRRS)
        csr_clear_en    : in  std_logic;                     -- Signal pour l'opération CLEAR (CSRRC)
        -- Niveau de privilège courant
        current_privilege : in std_logic_vector(1 downto 0);  -- Niveau de privilège (00: U, 01: S, 11: M)
        -- Signaux pour la MMU et le TLB
        tlb_flush       : out std_logic;                     -- Signal pour vider le TLB (lors de l'écriture dans satp_t)
        -- Signaux de debug
        debug_mstatus   : out EncodedWord                    -- Valeur de mstatus pour debug
    );
end entity csr_registers;

architecture rtl of csr_registers is
    -- Constantes pour les adresses des CSRs mode Machine (M-mode)
    constant CSR_MSTATUS_ADDR    : std_logic_vector(11 downto 0) := X"300"; -- Machine status register
    constant CSR_MISA_ADDR       : std_logic_vector(11 downto 0) := X"301"; -- Machine ISA register
    constant CSR_MEDELEG_ADDR    : std_logic_vector(11 downto 0) := X"302"; -- Machine exception delegation register
    constant CSR_MIDELEG_ADDR    : std_logic_vector(11 downto 0) := X"303"; -- Machine interrupt delegation register
    constant CSR_MIE_ADDR        : std_logic_vector(11 downto 0) := X"304"; -- Machine interrupt enable register
    constant CSR_MTVEC_ADDR      : std_logic_vector(11 downto 0) := X"305"; -- Machine trap vector register
    constant CSR_MSCRATCH_ADDR   : std_logic_vector(11 downto 0) := X"340"; -- Machine scratch register
    constant CSR_MEPC_ADDR       : std_logic_vector(11 downto 0) := X"341"; -- Machine exception program counter
    constant CSR_MCAUSE_ADDR     : std_logic_vector(11 downto 0) := X"342"; -- Machine cause register
    constant CSR_MTVAL_ADDR      : std_logic_vector(11 downto 0) := X"343"; -- Machine trap value register
    constant CSR_MIP_ADDR        : std_logic_vector(11 downto 0) := X"344"; -- Machine interrupt pending register
    
    -- Constantes pour les adresses des CSRs mode Superviseur (S-mode)
    constant CSR_SSTATUS_ADDR    : std_logic_vector(11 downto 0) := X"100"; -- Supervisor status register
    constant CSR_SIE_ADDR        : std_logic_vector(11 downto 0) := X"104"; -- Supervisor interrupt enable register
    constant CSR_STVEC_ADDR      : std_logic_vector(11 downto 0) := X"105"; -- Supervisor trap handler base address
    constant CSR_SSCRATCH_ADDR   : std_logic_vector(11 downto 0) := X"140"; -- Supervisor scratch register
    constant CSR_SEPC_ADDR       : std_logic_vector(11 downto 0) := X"141"; -- Supervisor exception program counter
    constant CSR_SCAUSE_ADDR     : std_logic_vector(11 downto 0) := X"142"; -- Supervisor cause register
    constant CSR_STVAL_ADDR      : std_logic_vector(11 downto 0) := X"143"; -- Supervisor trap value register
    constant CSR_SIP_ADDR        : std_logic_vector(11 downto 0) := X"144"; -- Supervisor interrupt pending register
    constant CSR_SATP_ADDR       : std_logic_vector(11 downto 0) := X"180"; -- Supervisor address translation and protection register
    
    -- Registres CSR mode Machine (M-mode)
    signal mstatus_reg   : EncodedWord := (others => '0'); -- Machine status register
    signal misa_reg      : EncodedWord := (others => '0'); -- Machine ISA register
    signal medeleg_reg   : EncodedWord := (others => '0'); -- Machine exception delegation register
    signal mideleg_reg   : EncodedWord := (others => '0'); -- Machine interrupt delegation register
    signal mie_reg       : EncodedWord := (others => '0'); -- Machine interrupt enable register
    signal mtvec_reg     : EncodedWord := (others => '0'); -- Machine trap vector register
    signal mscratch_reg  : EncodedWord := (others => '0'); -- Machine scratch register
    signal mepc_reg      : EncodedWord := (others => '0'); -- Machine exception program counter
    signal mcause_reg    : EncodedWord := (others => '0'); -- Machine cause register
    signal mtval_reg     : EncodedWord := (others => '0'); -- Machine trap value register
    signal mip_reg       : EncodedWord := (others => '0'); -- Machine interrupt pending register
    
    -- Registres CSR mode Superviseur (S-mode)
    signal sstatus_reg   : EncodedWord := (others => '0'); -- Supervisor status register
    signal sie_reg       : EncodedWord := (others => '0'); -- Supervisor interrupt enable register
    signal stvec_reg     : EncodedWord := (others => '0'); -- Supervisor trap handler base address
    signal sscratch_reg  : EncodedWord := (others => '0'); -- Supervisor scratch register
    signal sepc_reg      : EncodedWord := (others => '0'); -- Supervisor exception program counter
    signal scause_reg    : EncodedWord := (others => '0'); -- Supervisor cause register
    signal stval_reg     : EncodedWord := (others => '0'); -- Supervisor trap value register
    signal sip_reg       : EncodedWord := (others => '0'); -- Supervisor interrupt pending register
    signal satp_reg      : EncodedWord := (others => '0'); -- Supervisor address translation and protection register
    
    -- Signal pour le flush du TLB
    signal tlb_flush_internal : std_logic := '0';
    
    -- Fonction pour effectuer l'opération MAX ternaire bit à bit
    function ternary_max(a, b : EncodedWord) return EncodedWord is
        variable result : EncodedWord;
    begin
        for i in 0 to 23 loop
            -- Pour chaque trit, on prend le maximum
            if a(i*2+1 downto i*2) = TRIT_P or b(i*2+1 downto i*2) = TRIT_P then
                result(i*2+1 downto i*2) := TRIT_P;
            elsif a(i*2+1 downto i*2) = TRIT_Z or b(i*2+1 downto i*2) = TRIT_Z then
                result(i*2+1 downto i*2) := TRIT_Z;
            else
                result(i*2+1 downto i*2) := TRIT_N;
            end if;
        end loop;
        return result;
    end function;
    
    -- Fonction pour effectuer l'opération MIN ternaire bit à bit
    function ternary_min(a, b : EncodedWord) return EncodedWord is
        variable result : EncodedWord;
    begin
        for i in 0 to 23 loop
            -- Pour chaque trit, on prend le minimum
            if a(i*2+1 downto i*2) = TRIT_N or b(i*2+1 downto i*2) = TRIT_N then
                result(i*2+1 downto i*2) := TRIT_N;
            elsif a(i*2+1 downto i*2) = TRIT_Z or b(i*2+1 downto i*2) = TRIT_Z then
                result(i*2+1 downto i*2) := TRIT_Z;
            else
                result(i*2+1 downto i*2) := TRIT_P;
            end if;
        end loop;
        return result;
    end function;
    
begin
    -- Processus synchrone pour mettre à jour les registres CSR
    process(clk, rst)
        variable write_data : EncodedWord;
    begin
        if rst = '1' then
            -- Réinitialisation des registres CSR M-mode
            mstatus_reg  <= (others => '0');
            misa_reg     <= (others => '0');
            medeleg_reg  <= (others => '0');
            mideleg_reg  <= (others => '0');
            mie_reg      <= (others => '0');
            mtvec_reg    <= (others => '0');
            mscratch_reg <= (others => '0');
            mepc_reg     <= (others => '0');
            mcause_reg   <= (others => '0');
            mtval_reg    <= (others => '0');
            mip_reg      <= (others => '0');
            
            -- Réinitialisation des registres CSR S-mode
            sstatus_reg  <= (others => '0');
            sie_reg      <= (others => '0');
            stvec_reg    <= (others => '0');
            sscratch_reg <= (others => '0');
            sepc_reg     <= (others => '0');
            scause_reg   <= (others => '0');
            stval_reg    <= (others => '0');
            sip_reg      <= (others => '0');
            satp_reg     <= (others => '0');
            
            -- Réinitialisation du signal de flush TLB
            tlb_flush_internal <= '0';
        elsif rising_edge(clk) then
            -- Écriture dans les registres CSR
            if csr_write_en = '1' or csr_set_en = '1' or csr_clear_en = '1' then
                -- Vérification du niveau de privilège
                -- Pour simplifier, on suppose que tous les CSRs nécessitent le niveau M
                if current_privilege = "11" then
                    -- Vérification du niveau de privilège pour l'accès aux CSRs
                    -- Pour les CSRs M-mode, il faut être en M-mode
                    -- Pour les CSRs S-mode, il faut être en M-mode ou S-mode
                    if (csr_addr(11 downto 10) = "11" and current_privilege = "11") or -- M-mode CSRs
                       (csr_addr(11 downto 10) = "01" and (current_privilege = "11" or current_privilege = "01")) then -- S-mode CSRs
                        
                        -- Détermination de la valeur à écrire
                        if csr_write_en = '1' then
                            write_data := csr_write_data;
                        elsif csr_set_en = '1' then
                            -- Pour CSRRS, on utilise l'opération MAX ternaire
                            case csr_addr is
                                -- M-mode CSRs
                                when CSR_MSTATUS_ADDR  => write_data := ternary_max(mstatus_reg, csr_write_data);
                                when CSR_MISA_ADDR     => write_data := ternary_max(misa_reg, csr_write_data);
                                when CSR_MEDELEG_ADDR  => write_data := ternary_max(medeleg_reg, csr_write_data);
                                when CSR_MIDELEG_ADDR  => write_data := ternary_max(mideleg_reg, csr_write_data);
                                when CSR_MIE_ADDR      => write_data := ternary_max(mie_reg, csr_write_data);
                                when CSR_MTVEC_ADDR    => write_data := ternary_max(mtvec_reg, csr_write_data);
                                when CSR_MSCRATCH_ADDR => write_data := ternary_max(mscratch_reg, csr_write_data);
                                when CSR_MEPC_ADDR     => write_data := ternary_max(mepc_reg, csr_write_data);
                                when CSR_MCAUSE_ADDR   => write_data := ternary_max(mcause_reg, csr_write_data);
                                when CSR_MTVAL_ADDR    => write_data := ternary_max(mtval_reg, csr_write_data);
                                when CSR_MIP_ADDR      => write_data := ternary_max(mip_reg, csr_write_data);
                                
                                -- S-mode CSRs
                                when CSR_SSTATUS_ADDR  => write_data := ternary_max(sstatus_reg, csr_write_data);
                                when CSR_SIE_ADDR      => write_data := ternary_max(sie_reg, csr_write_data);
                                when CSR_STVEC_ADDR    => write_data := ternary_max(stvec_reg, csr_write_data);
                                when CSR_SSCRATCH_ADDR => write_data := ternary_max(sscratch_reg, csr_write_data);
                                when CSR_SEPC_ADDR     => write_data := ternary_max(sepc_reg, csr_write_data);
                                when CSR_SCAUSE_ADDR   => write_data := ternary_max(scause_reg, csr_write_data);
                                when CSR_STVAL_ADDR    => write_data := ternary_max(stval_reg, csr_write_data);
                                when CSR_SIP_ADDR      => write_data := ternary_max(sip_reg, csr_write_data);
                                when CSR_SATP_ADDR     => write_data := ternary_max(satp_reg, csr_write_data);
                                
                                when others            => write_data := (others => '0');
                            end case;
                        else -- csr_clear_en = '1'
                            -- Pour CSRRC, on utilise l'opération MIN ternaire
                            case csr_addr is
                                -- M-mode CSRs
                                when CSR_MSTATUS_ADDR  => write_data := ternary_min(mstatus_reg, not csr_write_data);
                                when CSR_MISA_ADDR     => write_data := ternary_min(misa_reg, not csr_write_data);
                                when CSR_MEDELEG_ADDR  => write_data := ternary_min(medeleg_reg, not csr_write_data);
                                when CSR_MIDELEG_ADDR  => write_data := ternary_min(mideleg_reg, not csr_write_data);
                                when CSR_MIE_ADDR      => write_data := ternary_min(mie_reg, not csr_write_data);
                                when CSR_MTVEC_ADDR    => write_data := ternary_min(mtvec_reg, not csr_write_data);
                                when CSR_MSCRATCH_ADDR => write_data := ternary_min(mscratch_reg, not csr_write_data);
                                when CSR_MEPC_ADDR     => write_data := ternary_min(mepc_reg, not csr_write_data);
                                when CSR_MCAUSE_ADDR   => write_data := ternary_min(mcause_reg, not csr_write_data);
                                when CSR_MTVAL_ADDR    => write_data := ternary_min(mtval_reg, not csr_write_data);
                                when CSR_MIP_ADDR      => write_data := ternary_min(mip_reg, not csr_write_data);
                                
                                -- S-mode CSRs
                                when CSR_SSTATUS_ADDR  => write_data := ternary_min(sstatus_reg, not csr_write_data);
                                when CSR_SIE_ADDR      => write_data := ternary_min(sie_reg, not csr_write_data);
                                when CSR_STVEC_ADDR    => write_data := ternary_min(stvec_reg, not csr_write_data);
                                when CSR_SSCRATCH_ADDR => write_data := ternary_min(sscratch_reg, not csr_write_data);
                                when CSR_SEPC_ADDR     => write_data := ternary_min(sepc_reg, not csr_write_data);
                                when CSR_SCAUSE_ADDR   => write_data := ternary_min(scause_reg, not csr_write_data);
                                when CSR_STVAL_ADDR    => write_data := ternary_min(stval_reg, not csr_write_data);
                                when CSR_SIP_ADDR      => write_data := ternary_min(sip_reg, not csr_write_data);
                                when CSR_SATP_ADDR     => write_data := ternary_min(satp_reg, not csr_write_data);
                                
                                when others            => write_data := (others => '0');
                            end case;
                        end if;
                        
                        -- Écriture dans le registre approprié
                        case csr_addr is
                            -- M-mode CSRs
                            when CSR_MSTATUS_ADDR  => mstatus_reg  <= write_data;
                            when CSR_MISA_ADDR     => misa_reg     <= write_data;
                            when CSR_MEDELEG_ADDR  => medeleg_reg  <= write_data;
                            when CSR_MIDELEG_ADDR  => mideleg_reg  <= write_data;
                            when CSR_MIE_ADDR      => mie_reg      <= write_data;
                            when CSR_MTVEC_ADDR    => mtvec_reg    <= write_data;
                            when CSR_MSCRATCH_ADDR => mscratch_reg <= write_data;
                            when CSR_MEPC_ADDR     => mepc_reg     <= write_data;
                            when CSR_MCAUSE_ADDR   => mcause_reg   <= write_data;
                            when CSR_MTVAL_ADDR    => mtval_reg    <= write_data;
                            when CSR_MIP_ADDR      => mip_reg      <= write_data;
                            
                            -- S-mode CSRs
                            when CSR_SSTATUS_ADDR  => sstatus_reg  <= write_data;
                            when CSR_SIE_ADDR      => sie_reg      <= write_data;
                            when CSR_STVEC_ADDR    => stvec_reg    <= write_data;
                            when CSR_SSCRATCH_ADDR => sscratch_reg <= write_data;
                            when CSR_SEPC_ADDR     => sepc_reg     <= write_data;
                            when CSR_SCAUSE_ADDR   => scause_reg   <= write_data;
                            when CSR_STVAL_ADDR    => stval_reg    <= write_data;
                            when CSR_SIP_ADDR      => sip_reg      <= write_data;
                            when CSR_SATP_ADDR     => 
                                -- Lors de l'écriture dans satp_t, on doit vider le TLB
                                satp_reg <= write_data;
                                tlb_flush_internal <= '1';
                            when others            => null
                end if;
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour la lecture des registres CSR
    process(csr_addr, csr_read_en, current_privilege,
            -- M-mode CSRs
            mstatus_reg, misa_reg, medeleg_reg, mideleg_reg, mie_reg,
            mtvec_reg, mscratch_reg, mepc_reg, mcause_reg, mtval_reg, mip_reg,
            -- S-mode CSRs
            sstatus_reg, sie_reg, stvec_reg, sscratch_reg, sepc_reg,
            scause_reg, stval_reg, sip_reg, satp_reg)
    begin
        -- Par défaut, données de lecture à zéro
        csr_read_data <= (others => '0');
        
        -- Lecture des registres CSR
        if csr_read_en = '1' then
            -- Vérification du niveau de privilège pour l'accès aux CSRs
            -- Pour les CSRs M-mode, il faut être en M-mode
            -- Pour les CSRs S-mode, il faut être en M-mode ou S-mode
            if (csr_addr(11 downto 10) = "11" and current_privilege = "11") or -- M-mode CSRs
               (csr_addr(11 downto 10) = "01" and (current_privilege = "11" or current_privilege = "01")) then -- S-mode CSRs
                
                case csr_addr is
                    -- M-mode CSRs
                    when CSR_MSTATUS_ADDR  => csr_read_data <= mstatus_reg;
                    when CSR_MISA_ADDR     => csr_read_data <= misa_reg;
                    when CSR_MEDELEG_ADDR  => csr_read_data <= medeleg_reg;
                    when CSR_MIDELEG_ADDR  => csr_read_data <= mideleg_reg;
                    when CSR_MIE_ADDR      => csr_read_data <= mie_reg;
                    when CSR_MTVEC_ADDR    => csr_read_data <= mtvec_reg;
                    when CSR_MSCRATCH_ADDR => csr_read_data <= mscratch_reg;
                    when CSR_MEPC_ADDR     => csr_read_data <= mepc_reg;
                    when CSR_MCAUSE_ADDR   => csr_read_data <= mcause_reg;
                    when CSR_MTVAL_ADDR    => csr_read_data <= mtval_reg;
                    when CSR_MIP_ADDR      => csr_read_data <= mip_reg;
                    
                    -- S-mode CSRs
                    when CSR_SSTATUS_ADDR  => csr_read_data <= sstatus_reg;
                    when CSR_SIE_ADDR      => csr_read_data <= sie_reg;
                    when CSR_STVEC_ADDR    => csr_read_data <= stvec_reg;
                    when CSR_SSCRATCH_ADDR => csr_read_data <= sscratch_reg;
                    when CSR_SEPC_ADDR     => csr_read_data <= sepc_reg;
                    when CSR_SCAUSE_ADDR   => csr_read_data <= scause_reg;
                    when CSR_STVAL_ADDR    => csr_read_data <= stval_reg;
                    when CSR_SIP_ADDR      => csr_read_data <= sip_reg;
                    when CSR_SATP_ADDR     => csr_read_data <= satp_reg;
                    
                    when others            => csr_read_data <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- Connexion du signal de flush TLB à la sortie
    tlb_flush <= tlb_flush_internal;
    
    -- Assignation des signaux de debug
    debug_mstatus <= mstatus_reg;
    
end architecture rtl;