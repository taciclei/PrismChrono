library ieee;
use ieee.std_logic_1164.all;
use work.prismchrono_types_pkg.all;

entity mmu_t is
  port (
    -- Signaux de contrôle
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    enable        : in  std_logic;
    
    -- Interface CPU
    va_in         : in  std_logic_vector(23 downto 0);  -- Adresse virtuelle (24 trits)
    access_type   : in  std_logic_vector(1 downto 0);   -- 00:Read, 01:Write, 10:Execute
    priv_mode     : in  std_logic_vector(1 downto 0);   -- 00:U, 01:S, 10:M
    satp_t        : in  std_logic_vector(23 downto 0);  -- Registre SATP ternaire
    
    -- Sorties
    pa_out        : out std_logic_vector(23 downto 0);  -- Adresse physique traduite
    valid         : out std_logic;                      -- '1' si traduction valide
    fault         : out std_logic;                      -- '1' si faute de page
    fault_cause   : out std_logic_vector(2 downto 0);   -- Type de faute
    
    -- Interface mémoire pour Page Table Walk
    mem_addr      : out std_logic_vector(23 downto 0);  -- Adresse pour lire PTE
    mem_data_in   : in  std_logic_vector(23 downto 0);  -- Données lues (PTE)
    mem_req       : out std_logic;                      -- Requête mémoire
    mem_ack       : in  std_logic                       -- Acquittement mémoire
  );
end entity mmu_t;

architecture rtl of mmu_t is
  -- États du Page Table Walker
  type ptw_state_t is (IDLE, LOOKUP_PTE1, WAIT_PTE1, LOOKUP_PTE0, WAIT_PTE0, DONE, FAULT);
  signal ptw_state : ptw_state_t;
  
  -- TLB (simplifié pour l'instant - direct mapped)
  type tlb_entry_t is record
    va_tag  : std_logic_vector(17 downto 0);  -- Tag (18 trits)
    pa_base : std_logic_vector(17 downto 0);  -- Base PA (18 trits)
    valid   : std_logic;                      -- Entrée valide
    rwx     : std_logic_vector(2 downto 0);   -- Permissions R/W/X
  end record;
  
  type tlb_array_t is array(0 to 7) of tlb_entry_t;  -- 8 entrées
  signal tlb : tlb_array_t;
  
  -- Signaux internes
  signal tlb_hit        : std_logic;
  signal tlb_pa         : std_logic_vector(23 downto 0);
  signal pte_valid      : std_logic;
  signal current_level  : integer range 0 to 1;
  signal temp_pa        : std_logic_vector(23 downto 0);
  
begin
  -- Processus principal
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      ptw_state <= IDLE;
      valid <= '0';
      fault <= '0';
      mem_req <= '0';
      
      -- Reset TLB
      for i in tlb'range loop
        tlb(i).valid <= '0';
      end loop;
      
    elsif rising_edge(clk) then
      case ptw_state is
        when IDLE =>
          if enable = '1' then
            -- Vérifier TLB d'abord
            if tlb_hit = '1' then
              pa_out <= tlb_pa;
              valid <= '1';
              fault <= '0';
            else
              -- Démarrer Page Table Walk
              ptw_state <= LOOKUP_PTE1;
              current_level <= 1;
              mem_req <= '1';
              valid <= '0';
            end if;
          end if;
          
        when LOOKUP_PTE1 =>
          if mem_ack = '1' then
            mem_req <= '0';
            ptw_state <= WAIT_PTE1;
          end if;
          
        when WAIT_PTE1 =>
          if pte_valid = '1' then
            ptw_state <= LOOKUP_PTE0;
            current_level <= 0;
            mem_req <= '1';
          else
            ptw_state <= FAULT;
            fault <= '1';
            fault_cause <= "001";  -- PTE invalide
          end if;
          
        when LOOKUP_PTE0 =>
          if mem_ack = '1' then
            mem_req <= '0';
            ptw_state <= WAIT_PTE0;
          end if;
          
        when WAIT_PTE0 =>
          if pte_valid = '1' then
            ptw_state <= DONE;
            pa_out <= temp_pa;
            valid <= '1';
            -- Mettre à jour TLB
            tlb(0).va_tag <= va_in(23 downto 6);
            tlb(0).pa_base <= temp_pa(23 downto 6);
            tlb(0).valid <= '1';
            tlb(0).rwx <= mem_data_in(2 downto 0);
          else
            ptw_state <= FAULT;
            fault <= '1';
            fault_cause <= "001";  -- PTE invalide
          end if;
          
        when DONE =>
          ptw_state <= IDLE;
          
        when FAULT =>
          ptw_state <= IDLE;
          
      end case;
    end if;
  end process;
  
  -- Logique TLB hit
  process(va_in, tlb)
  begin
    tlb_hit <= '0';
    tlb_pa <= (others => '0');
    
    for i in tlb'range loop
      if tlb(i).valid = '1' and tlb(i).va_tag = va_in(23 downto 6) then
        tlb_hit <= '1';
        tlb_pa <= tlb(i).pa_base & va_in(5 downto 0);
        exit;
      end if;
    end loop;
  end process;
  
  -- Calcul adresse PTE
  mem_addr <= satp_t(23 downto 6) & va_in(23 downto 18) & "000000" when current_level = 1 else
              temp_pa(23 downto 6) & va_in(17 downto 12) & "000000";
  
  -- Vérification validité PTE
  pte_valid <= '1' when mem_data_in(23) = '1' else '0';
  
  -- Stockage PA temporaire
  temp_pa <= mem_data_in when current_level = 0 else
             mem_data_in(23 downto 6) & va_in(5 downto 0);
  
end architecture rtl;