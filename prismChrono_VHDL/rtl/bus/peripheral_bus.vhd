library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Bus périphérique simplifié de type Wishbone pour PrismChrono
-- Permet de connecter les périphériques (UART, SPI, I²C) au système
entity peripheral_bus is
    generic (
        N_SLAVES : integer := 4  -- Nombre d'esclaves (UART + SPI + I²C + PLIC)
    );
    port (
        -- Signaux système
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface maître (depuis le pont bus)
        m_addr      : in  std_logic_vector(31 downto 0);  -- Adresse
        m_data_in   : in  std_logic_vector(23 downto 0);  -- Données entrantes
        m_data_out  : out std_logic_vector(23 downto 0);  -- Données sortantes
        m_we        : in  std_logic;                      -- Write enable
        m_re        : in  std_logic;                      -- Read enable
        m_ready     : out std_logic;                      -- Prêt pour transaction
        
        -- Interface esclaves
        s_addr      : out std_logic_vector(N_SLAVES*4-1 downto 0);    -- Adresses locales
        s_data_in   : in  std_logic_vector(N_SLAVES*24-1 downto 0);   -- Données des esclaves
        s_data_out  : out std_logic_vector(N_SLAVES*24-1 downto 0);   -- Données vers esclaves
        s_we        : out std_logic_vector(N_SLAVES-1 downto 0);      -- Write enables
        s_re        : out std_logic_vector(N_SLAVES-1 downto 0);      -- Read enables
        s_ready     : in  std_logic_vector(N_SLAVES-1 downto 0)       -- Ready des esclaves
    );
end entity peripheral_bus;

architecture rtl of peripheral_bus is
    -- Décodage d'adresse pour les périphériques
    -- Base: 0xF000_0000
    -- UART: 0xF000_0000 - 0xF000_000F
    -- SPI:  0xF000_0010 - 0xF000_001F
    -- I2C:  0xF000_0020 - 0xF000_002F
    -- PLIC: 0xF000_0030 - 0xF000_003F
    constant ADDR_MASK    : std_logic_vector(31 downto 0) := x"F0000030";
    constant ADDR_UART    : std_logic_vector(31 downto 0) := x"F0000000";
    constant ADDR_SPI     : std_logic_vector(31 downto 0) := x"F0000010";
    constant ADDR_I2C     : std_logic_vector(31 downto 0) := x"F0000020";
    constant ADDR_PLIC    : std_logic_vector(31 downto 0) := x"F0000030";
    
    -- Signaux internes
    signal slave_sel   : integer range 0 to N_SLAVES-1;
    signal addr_match  : std_logic;
    signal local_addr  : std_logic_vector(3 downto 0);
    
begin
    -- Décodage d'adresse
    process(m_addr)
    begin
        addr_match <= '0';
        slave_sel <= 0;
        local_addr <= m_addr(3 downto 0);
        
        case m_addr(31 downto 4) is
            when ADDR_UART(31 downto 4) =>
                addr_match <= '1';
                slave_sel <= 0;
            when ADDR_SPI(31 downto 4) =>
                addr_match <= '1';
                slave_sel <= 1;
            when ADDR_I2C(31 downto 4) =>
                addr_match <= '1';
                slave_sel <= 2;
            when ADDR_PLIC(31 downto 4) =>
                addr_match <= '1';
                slave_sel <= 3;
            when others =>
                addr_match <= '0';
        end case;
    end process;
    
    -- Distribution des signaux aux esclaves
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            s_we <= (others => '0');
            s_re <= (others => '0');
            s_data_out <= (others => '0');
            s_addr <= (others => '0');
            m_ready <= '0';
            m_data_out <= (others => '0');
        elsif rising_edge(clk) then
            -- Par défaut, désactiver tous les signaux
            s_we <= (others => '0');
            s_re <= (others => '0');
            
            if addr_match = '1' then
                -- Propager l'adresse locale au périphérique sélectionné
                s_addr(slave_sel*4+3 downto slave_sel*4) <= local_addr;
                
                -- Propager les données et signaux de contrôle
                if m_we = '1' then
                    s_we(slave_sel) <= '1';
                    s_data_out(slave_sel*24+23 downto slave_sel*24) <= m_data_in;
                elsif m_re = '1' then
                    s_re(slave_sel) <= '1';
                end if;
                
                -- Retourner les données du périphérique sélectionné
                m_data_out <= s_data_in(slave_sel*24+23 downto slave_sel*24);
                m_ready <= s_ready(slave_sel);
            else
                -- Aucun périphérique sélectionné
                m_ready <= '1';
                m_data_out <= (others => '0');
            end if;
        end if;
    end process;
    
end architecture rtl;