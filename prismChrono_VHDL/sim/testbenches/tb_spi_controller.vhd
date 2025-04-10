library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le contrôleur SPI
entity tb_spi_controller is
end entity tb_spi_controller;

architecture sim of tb_spi_controller is
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signaux pour le DUT
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal addr        : std_logic_vector(3 downto 0) := (others => '0');
    signal data_in     : std_logic_vector(23 downto 0) := (others => '0');
    signal data_out    : std_logic_vector(23 downto 0);
    signal we          : std_logic := '0';
    signal re          : std_logic := '0';
    signal ready       : std_logic;
    signal spi_sclk    : std_logic;
    signal spi_mosi    : std_logic;
    signal spi_miso    : std_logic := '0';
    signal spi_cs_n    : std_logic;
    
    -- Procédure pour écrire dans un registre
    procedure write_reg(
        constant reg_addr : in std_logic_vector(3 downto 0);
        constant reg_data : in std_logic_vector(23 downto 0);
        signal clk       : in std_logic;
        signal addr      : out std_logic_vector(3 downto 0);
        signal data_in   : out std_logic_vector(23 downto 0);
        signal we        : out std_logic;
        signal ready     : in std_logic
    ) is
    begin
        wait until rising_edge(clk);
        addr <= reg_addr;
        data_in <= reg_data;
        we <= '1';
        wait until rising_edge(clk);
        we <= '0';
        wait until ready = '1';
    end procedure;
    
    -- Procédure pour lire un registre
    procedure read_reg(
        constant reg_addr : in std_logic_vector(3 downto 0);
        signal clk       : in std_logic;
        signal addr      : out std_logic_vector(3 downto 0);
        signal re        : out std_logic;
        signal ready     : in std_logic
    ) is
    begin
        wait until rising_edge(clk);
        addr <= reg_addr;
        re <= '1';
        wait until rising_edge(clk);
        re <= '0';
        wait until ready = '1';
    end procedure;
    
begin
    -- Instanciation du DUT
    dut: entity work.spi_controller
    port map (
        clk         => clk,
        rst_n       => rst_n,
        addr        => addr,
        data_in     => data_in,
        data_out    => data_out,
        we          => we,
        re          => re,
        ready       => ready,
        spi_sclk    => spi_sclk,
        spi_mosi    => spi_mosi,
        spi_miso    => spi_miso,
        spi_cs_n    => spi_cs_n
    );
    
    -- Génération de l'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Process de test principal
    process
        variable test_data : std_logic_vector(23 downto 0);
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 5;
        rst_n <= '1';
        wait for CLK_PERIOD * 5;
        
        -- Test 1: Configuration mode 0 (CPOL=0, CPHA=0)
        report "Test 1: Configuration mode 0";
        write_reg(x"0", x"000001", clk, addr, data_in, we, ready);  -- Enable
        write_reg(x"1", x"000004", clk, addr, data_in, we, ready);  -- Divider=4
        
        -- Test 2: Envoi de données en mode 0
        report "Test 2: Envoi de données en mode 0";
        test_data := x"A5B6C7";
        write_reg(x"2", test_data, clk, addr, data_in, we, ready);  -- TX Data
        wait for CLK_PERIOD * 50;  -- Attendre la fin de la transmission
        
        -- Test 3: Configuration mode 1 (CPOL=0, CPHA=1)
        report "Test 3: Configuration mode 1";
        write_reg(x"0", x"000005", clk, addr, data_in, we, ready);  -- Enable + CPHA
        
        -- Test 4: Envoi de données en mode 1
        report "Test 4: Envoi de données en mode 1";
        test_data := x"123456";
        write_reg(x"2", test_data, clk, addr, data_in, we, ready);  -- TX Data
        wait for CLK_PERIOD * 50;  -- Attendre la fin de la transmission
        
        -- Test 5: Configuration mode 2 (CPOL=1, CPHA=0)
        report "Test 5: Configuration mode 2";
        write_reg(x"0", x"000003", clk, addr, data_in, we, ready);  -- Enable + CPOL
        
        -- Test 6: Envoi de données en mode 2
        report "Test 6: Envoi de données en mode 2";
        test_data := x"ABCDEF";
        write_reg(x"2", test_data, clk, addr, data_in, we, ready);  -- TX Data
        wait for CLK_PERIOD * 50;  -- Attendre la fin de la transmission
        
        -- Test 7: Configuration mode 3 (CPOL=1, CPHA=1)
        report "Test 7: Configuration mode 3";
        write_reg(x"0", x"000007", clk, addr, data_in, we, ready);  -- Enable + CPOL + CPHA
        
        -- Test 8: Envoi de données en mode 3
        report "Test 8: Envoi de données en mode 3";
        test_data := x"789ABC";
        write_reg(x"2", test_data, clk, addr, data_in, we, ready);  -- TX Data
        wait for CLK_PERIOD * 50;  -- Attendre la fin de la transmission
        
        -- Test 9: Vérification du statut
        report "Test 9: Vérification du statut";
        read_reg(x"4", clk, addr, re, ready);
        
        -- Fin des tests
        report "Fin des tests SPI";
        wait;
    end process;
    
    -- Process de simulation du périphérique SPI esclave
    process
    begin
        wait until spi_cs_n = '0';  -- Attendre sélection
        
        -- Simuler des données de retour
        for i in 0 to 23 loop
            wait until spi_sclk'event;
            spi_miso <= not spi_mosi;  -- Inverser les données reçues
        end loop;
        
        wait until spi_cs_n = '1';  -- Attendre désélection
    end process;
    
end architecture sim;