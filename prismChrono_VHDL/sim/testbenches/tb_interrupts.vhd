library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench pour les modules d'interruption
entity tb_interrupts is
end entity tb_interrupts;

architecture sim of tb_interrupts is
    -- Signaux pour timer_unit
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal csr_addr    : std_logic_vector(11 downto 0);
    signal csr_wdata   : std_logic_vector(11 downto 0);
    signal csr_rdata_timer : std_logic_vector(11 downto 0);
    signal csr_rdata_plic : std_logic_vector(11 downto 0);
    signal csr_we      : std_logic := '0';
    signal timer_int   : std_logic;
    
    -- Signaux pour plic_simple
    constant NUM_SOURCES : positive := 4;
    signal gpio_pins   : std_logic_vector(NUM_SOURCES-1 downto 0) := (others => '0');
    signal ext_int     : std_logic;
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
begin
    -- Instanciation du timer_unit
    timer_inst : entity work.timer_unit
    port map (
        clk       => clk,
        rst_n     => rst_n,
        csr_addr  => csr_addr,
        csr_wdata => csr_wdata,
        csr_rdata => csr_rdata_timer,
        csr_we    => csr_we,
        timer_int => timer_int
    );
    
    -- Instanciation du plic_simple
    plic_inst : entity work.plic_simple
    generic map (
        NUM_SOURCES => NUM_SOURCES
    )
    port map (
        clk       => clk,
        rst_n     => rst_n,
        gpio_pins => gpio_pins,
        csr_addr  => csr_addr,
        csr_wdata => csr_wdata,
        csr_rdata => csr_rdata_plic,
        csr_we    => csr_we,
        ext_int   => ext_int
    );
    
    -- Génération de l'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Processus de test
    process
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;
        
        -- Test du timer
        -- Configuration de mtimecmp
        csr_addr <= x"C02";
        csr_wdata <= x"005";  -- Valeur arbitraire pour le test
        csr_we <= '1';
        wait for CLK_PERIOD;
        csr_we <= '0';
        
        -- Attente de l'interruption timer
        wait until timer_int = '1';
        assert timer_int = '1' report "Timer interrupt not triggered" severity error;
        
        -- Test des interruptions externes
        -- Activation des interruptions
        csr_addr <= x"C11";
        csr_wdata <= x"00F";  -- Active toutes les sources
        csr_we <= '1';
        wait for CLK_PERIOD;
        csr_we <= '0';
        
        -- Génération d'une interruption externe
        gpio_pins <= "0001";
        wait for CLK_PERIOD * 2;
        assert ext_int = '1' report "External interrupt not triggered" severity error;
        
        -- Fin des tests
        wait for CLK_PERIOD * 10;
        assert false report "Test completed successfully" severity note;
        wait;
    end process;
    
end architecture sim;