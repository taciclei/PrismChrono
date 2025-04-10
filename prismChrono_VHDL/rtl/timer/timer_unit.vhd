library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Timer Unit pour PrismChrono
-- Implémente un compteur mtime et un comparateur mtimecmp
-- Génère une interruption timer (MTIP/STIP) quand mtime >= mtimecmp
entity timer_unit is
    port (
        -- Signaux de base
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface CSR
        csr_addr    : in  std_logic_vector(11 downto 0);
        csr_wdata   : in  std_logic_vector(11 downto 0);  -- 12 bits = 4 trits
        csr_rdata   : out std_logic_vector(11 downto 0);
        csr_we      : in  std_logic;
        
        -- Sorties interruption
        timer_int   : out std_logic  -- '1' quand mtime >= mtimecmp
    );
end entity timer_unit;

architecture rtl of timer_unit is
    -- Registres internes (représentation ternaire)
    signal mtime    : unsigned(11 downto 0);  -- Compteur de temps
    signal mtimecmp : unsigned(11 downto 0);  -- Valeur de comparaison
    
    -- Constantes pour les adresses CSR
    constant CSR_MTIME_ADDR    : std_logic_vector(11 downto 0) := x"C01";
    constant CSR_MTIMECMP_ADDR : std_logic_vector(11 downto 0) := x"C02";
    
begin
    -- Processus de mise à jour du compteur et comparaison
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            mtime    <= (others => '0');
            mtimecmp <= (others => '1');  -- Valeur max par défaut
            timer_int <= '0';
        elsif rising_edge(clk) then
            -- Incrémentation du compteur
            mtime <= mtime + 1;
            
            -- Écriture CSR
            if csr_we = '1' then
                case csr_addr is
                    when CSR_MTIME_ADDR =>
                        mtime <= unsigned(csr_wdata);
                    when CSR_MTIMECMP_ADDR =>
                        mtimecmp <= unsigned(csr_wdata);
                    when others =>
                        null;
                end case;
            end if;
            
            -- Génération de l'interruption
            if mtime >= mtimecmp then
                timer_int <= '1';
            else
                timer_int <= '0';
            end if;
        end if;
    end process;
    
    -- Lecture CSR
    process(csr_addr, mtime, mtimecmp)
    begin
        case csr_addr is
            when CSR_MTIME_ADDR =>
                csr_rdata <= std_logic_vector(mtime);
            when CSR_MTIMECMP_ADDR =>
                csr_rdata <= std_logic_vector(mtimecmp);
            when others =>
                csr_rdata <= (others => '0');
        end case;
    end process;
    
end architecture rtl;