library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Testbench pour l'unité atomique
entity tb_atomics is
end entity tb_atomics;

architecture sim of tb_atomics is
    -- Signaux pour atomic_unit
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal op_atomic   : std_logic := '0';
    signal op_lr       : std_logic := '0';
    signal op_sc       : std_logic := '0';
    signal addr        : std_logic_vector(31 downto 0);
    signal data_in     : std_logic_vector(11 downto 0);
    signal data_out    : std_logic_vector(11 downto 0);
    
    -- Interface cache simulée
    signal cache_ready : std_logic := '1';
    signal cache_valid : std_logic := '1';
    signal cache_we    : std_logic;
    signal cache_addr  : std_logic_vector(31 downto 0);
    signal cache_wdata : std_logic_vector(11 downto 0);
    signal cache_rdata : std_logic_vector(11 downto 0) := x"000";
    
    -- Contrôle et status
    signal busy        : std_logic;
    signal success     : std_logic;
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
begin
    -- Instanciation de l'unité atomique
    atomic_inst : entity work.atomic_unit
    port map (
        clk         => clk,
        rst_n       => rst_n,
        op_atomic   => op_atomic,
        op_lr       => op_lr,
        op_sc       => op_sc,
        addr        => addr,
        data_in     => data_in,
        data_out    => data_out,
        cache_ready => cache_ready,
        cache_valid => cache_valid,
        cache_we    => cache_we,
        cache_addr  => cache_addr,
        cache_wdata => cache_wdata,
        cache_rdata => cache_rdata,
        busy        => busy,
        success     => success
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
        
        -- Test 1: LR.T suivi de SC.T réussi
        -- Load Reserved
        addr <= x"00000100";
        op_atomic <= '1';
        op_lr <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_lr <= '0';
        
        -- Attente que LR.T termine
        wait until busy = '0';
        
        -- Store Conditional
        data_in <= x"ABC";
        op_atomic <= '1';
        op_sc <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_sc <= '0';
        
        -- Vérification du succès
        wait until busy = '0';
        assert success = '1' report "SC.T failed unexpectedly" severity error;
        
        -- Test 2: LR.T suivi d'une écriture concurrente puis SC.T échoué
        -- Load Reserved
        addr <= x"00000200";
        op_atomic <= '1';
        op_lr <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_lr <= '0';
        
        -- Simulation d'une écriture concurrente
        wait for CLK_PERIOD * 2;
        cache_valid <= '1';
        cache_rdata <= x"DEF";
        
        -- Store Conditional qui devrait échouer
        data_in <= x"123";
        op_atomic <= '1';
        op_sc <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_sc <= '0';
        
        -- Vérification de l'échec
        wait until busy = '0';
        assert success = '0' report "SC.T succeeded unexpectedly" severity error;
        
        -- Test 3: LR.T suivi d'un autre LR.T sur la même adresse
        -- Premier Load Reserved
        addr <= x"00000300";
        op_atomic <= '1';
        op_lr <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_lr <= '0';
        wait until busy = '0';
        
        -- Deuxième Load Reserved sur la même adresse
        op_atomic <= '1';
        op_lr <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_lr <= '0';
        wait until busy = '0';
        
        -- Store Conditional qui devrait réussir
        data_in <= x"456";
        op_atomic <= '1';
        op_sc <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_sc <= '0';
        wait until busy = '0';
        assert success = '1' report "SC.T failed after second LR.T" severity error;
        
        -- Test 4: Vérification du timeout de réservation
        -- Load Reserved
        addr <= x"00000400";
        op_atomic <= '1';
        op_lr <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_lr <= '0';
        wait until busy = '0';
        
        -- Attente longue pour simuler un timeout
        wait for CLK_PERIOD * 100;
        
        -- Store Conditional qui devrait échouer
        data_in <= x"789";
        op_atomic <= '1';
        op_sc <= '1';
        wait for CLK_PERIOD;
        op_atomic <= '0';
        op_sc <= '0';
        wait until busy = '0';
        assert success = '0' report "SC.T succeeded after timeout" severity error;
        
        -- Fin des tests
        wait for CLK_PERIOD * 10;
        assert false report "Test completed successfully" severity note;
        wait;
    end process;
    
end architecture sim;