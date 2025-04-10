library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Contrôleur SPI maître pour PrismChrono
-- Supporte les modes SPI 0-3 (CPOL/CPHA)
-- Interface MMIO pour configuration et données
entity spi_controller is
    port (
        -- Signaux système
        clk         : in  std_logic;  -- Horloge système
        rst_n       : in  std_logic;  -- Reset asynchrone actif bas
        
        -- Interface MMIO
        addr        : in  std_logic_vector(3 downto 0);   -- Adresse registre
        data_in     : in  std_logic_vector(23 downto 0);  -- Données entrantes
        data_out    : out std_logic_vector(23 downto 0);  -- Données sortantes
        we          : in  std_logic;                      -- Write enable
        re          : in  std_logic;                      -- Read enable
        ready       : out std_logic;                      -- Prêt pour transaction
        
        -- Interface SPI
        spi_sclk    : out std_logic;  -- Horloge SPI
        spi_mosi    : out std_logic;  -- Master Out Slave In
        spi_miso    : in  std_logic;  -- Master In Slave Out
        spi_cs_n    : out std_logic   -- Chip Select (actif bas)
    );
end entity spi_controller;

architecture rtl of spi_controller is
    -- Registres de configuration et contrôle
    type registers_t is record
        ctrl    : std_logic_vector(23 downto 0);  -- Registre de contrôle
        status  : std_logic_vector(23 downto 0);  -- Registre de statut
        divider : std_logic_vector(23 downto 0);  -- Diviseur d'horloge
        tx_data : std_logic_vector(23 downto 0);  -- Données à transmettre
        rx_data : std_logic_vector(23 downto 0);  -- Données reçues
    end record;
    
    signal regs : registers_t := (
        ctrl    => (others => '0'),
        status  => (others => '0'),
        divider => (others => '0'),
        tx_data => (others => '0'),
        rx_data => (others => '0')
    );
    
    -- Bits du registre de contrôle
    constant CTRL_ENABLE    : integer := 0;  -- Active le contrôleur
    constant CTRL_CPOL     : integer := 1;  -- Polarité horloge
    constant CTRL_CPHA     : integer := 2;  -- Phase horloge
    constant CTRL_CS       : integer := 3;  -- Contrôle manuel CS
    constant CTRL_LSB      : integer := 4;  -- LSB first
    constant CTRL_IE       : integer := 5;  -- Interrupt enable
    
    -- Bits du registre de statut
    constant STAT_BUSY     : integer := 0;  -- Transmission en cours
    constant STAT_RX_VALID : integer := 1;  -- Données reçues valides
    constant STAT_TX_EMPTY : integer := 2;  -- Buffer TX vide
    
    -- États de la machine d'états
    type state_t is (IDLE, SETUP, SHIFT, HOLD);
    signal state : state_t := IDLE;
    
    -- Compteurs et registres internes
    signal bit_counter   : integer range 0 to 23 := 0;
    signal clk_counter   : integer range 0 to 1023 := 0;
    signal shift_reg_tx  : std_logic_vector(23 downto 0);
    signal shift_reg_rx  : std_logic_vector(23 downto 0);
    signal sclk_internal : std_logic := '0';
    signal cs_internal   : std_logic := '1';
    
begin
    -- Processus de lecture/écriture des registres MMIO
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            regs <= (
                ctrl    => (others => '0'),
                status  => (others => '0'),
                divider => (others => '0'),
                tx_data => (others => '0'),
                rx_data => (others => '0')
            );
        elsif rising_edge(clk) then
            -- Écriture registres
            if we = '1' then
                case addr is
                    when "0000" => regs.ctrl    <= data_in;
                    when "0001" => regs.divider <= data_in;
                    when "0010" => regs.tx_data <= data_in;
                    when others => null;
                end case;
            end if;
            
            -- Mise à jour statut
            regs.status(STAT_BUSY) <= '0' when state = IDLE else '1';
            regs.status(STAT_TX_EMPTY) <= '1' when state = IDLE else '0';
            
            -- Lecture données reçues
            if state = IDLE and regs.status(STAT_RX_VALID) = '1' then
                if re = '1' and addr = "0011" then
                    regs.status(STAT_RX_VALID) <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Processus de génération d'horloge SPI
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_counter <= 0;
            sclk_internal <= regs.ctrl(CTRL_CPOL);
        elsif rising_edge(clk) then
            if state /= IDLE then
                if clk_counter = 0 then
                    clk_counter <= to_integer(unsigned(regs.divider));
                    sclk_internal <= not sclk_internal;
                else
                    clk_counter <= clk_counter - 1;
                end if;
            else
                sclk_internal <= regs.ctrl(CTRL_CPOL);
            end if;
        end if;
    end process;
    
    -- Machine d'états principale
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            bit_counter <= 0;
            shift_reg_tx <= (others => '0');
            shift_reg_rx <= (others => '0');
            cs_internal <= '1';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if regs.ctrl(CTRL_ENABLE) = '1' and regs.status(STAT_BUSY) = '0' then
                        state <= SETUP;
                        shift_reg_tx <= regs.tx_data;
                        bit_counter <= 23;
                        cs_internal <= '0';
                    end if;
                
                when SETUP =>
                    if clk_counter = 0 then
                        state <= SHIFT;
                    end if;
                
                when SHIFT =>
                    if sclk_internal'event then
                        if regs.ctrl(CTRL_CPHA) = '0' then
                            -- Mode 0,2: Échantillonner sur front montant
                            if sclk_internal = '1' then
                                shift_reg_rx <= shift_reg_rx(22 downto 0) & spi_miso;
                            end if;
                        else
                            -- Mode 1,3: Échantillonner sur front descendant
                            if sclk_internal = '0' then
                                shift_reg_rx <= shift_reg_rx(22 downto 0) & spi_miso;
                            end if;
                        end if;
                        
                        if bit_counter = 0 then
                            state <= HOLD;
                        else
                            bit_counter <= bit_counter - 1;
                            shift_reg_tx <= shift_reg_tx(22 downto 0) & '0';
                        end if;
                    end if;
                
                when HOLD =>
                    if clk_counter = 0 then
                        state <= IDLE;
                        cs_internal <= '1';
                        regs.rx_data <= shift_reg_rx;
                        regs.status(STAT_RX_VALID) <= '1';
                    end if;
            end case;
        end if;
    end process;
    
    -- Sorties
    ready <= '1' when state = IDLE else '0';
    data_out <= regs.rx_data when addr = "0011" else
                regs.status when addr = "0100" else
                (others => '0');
    
    -- Interface SPI
    spi_sclk <= sclk_internal;
    spi_cs_n <= cs_internal when regs.ctrl(CTRL_CS) = '0' else regs.ctrl(3);
    spi_mosi <= shift_reg_tx(23) when regs.ctrl(CTRL_LSB) = '0' else shift_reg_tx(0);
    
end architecture rtl;