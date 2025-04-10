library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Pont entre le bus mémoire principal et le bus périphérique
-- Permet d'isoler les accès aux périphériques des accès mémoire
entity bus_bridge is
    port (
        -- Signaux système
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface bus mémoire (côté processeur)
        m_addr      : in  std_logic_vector(31 downto 0);  -- Adresse
        m_data_in   : in  std_logic_vector(23 downto 0);  -- Données entrantes
        m_data_out  : out std_logic_vector(23 downto 0);  -- Données sortantes
        m_we        : in  std_logic;                      -- Write enable
        m_re        : in  std_logic;                      -- Read enable
        m_ready     : out std_logic;                      -- Prêt pour transaction
        
        -- Interface bus périphérique
        p_addr      : out std_logic_vector(31 downto 0);  -- Adresse
        p_data_in   : in  std_logic_vector(23 downto 0);  -- Données du périphérique
        p_data_out  : out std_logic_vector(23 downto 0);  -- Données vers périphérique
        p_we        : out std_logic;                      -- Write enable
        p_re        : out std_logic;                      -- Read enable
        p_ready     : in  std_logic                       -- Prêt pour transaction
    );
end entity bus_bridge;

architecture rtl of bus_bridge is
    -- Plage d'adresses pour les périphériques (0xF000_0000 - 0xF000_FFFF)
    constant PERIPH_BASE_ADDR : std_logic_vector(31 downto 0) := x"F0000000";
    constant PERIPH_MASK     : std_logic_vector(31 downto 0) := x"FFF00000";
    
    -- États de la machine d'états
    type state_t is (IDLE, WAIT_PERIPH);
    signal state : state_t := IDLE;
    
    -- Signaux internes
    signal is_periph_access : std_logic;
    signal addr_reg    : std_logic_vector(31 downto 0);
    signal data_reg    : std_logic_vector(23 downto 0);
    signal we_reg      : std_logic;
    signal re_reg      : std_logic;
    
begin
    -- Détection accès périphérique
    is_periph_access <= '1' when (m_addr and PERIPH_MASK) = PERIPH_BASE_ADDR else '0';
    
    -- Machine d'états
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            addr_reg <= (others => '0');
            data_reg <= (others => '0');
            we_reg <= '0';
            re_reg <= '0';
            m_ready <= '1';
            p_we <= '0';
            p_re <= '0';
            p_addr <= (others => '0');
            p_data_out <= (others => '0');
            m_data_out <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if (m_we = '1' or m_re = '1') and is_periph_access = '1' then
                        -- Mémoriser la requête
                        addr_reg <= m_addr;
                        data_reg <= m_data_in;
                        we_reg <= m_we;
                        re_reg <= m_re;
                        
                        -- Propager la requête au bus périphérique
                        p_addr <= m_addr;
                        p_data_out <= m_data_in;
                        p_we <= m_we;
                        p_re <= m_re;
                        
                        -- Indiquer que le pont est occupé
                        m_ready <= '0';
                        state <= WAIT_PERIPH;
                    else
                        -- Pas d'accès périphérique, pont libre
                        m_ready <= '1';
                        p_we <= '0';
                        p_re <= '0';
                    end if;
                
                when WAIT_PERIPH =>
                    if p_ready = '1' then
                        -- Transaction périphérique terminée
                        if re_reg = '1' then
                            m_data_out <= p_data_in;
                        end if;
                        
                        -- Libérer le pont
                        m_ready <= '1';
                        p_we <= '0';
                        p_re <= '0';
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
    
end architecture rtl;