library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Package pour les types et constantes spécifiques au projet
library work;
use work.prismchrono_types_pkg.all;

entity tb_l1_cache_separate is
end entity tb_l1_cache_separate;

architecture testbench of tb_l1_cache_separate is
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signaux communs
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    
    -- Signaux pour I-Cache
    signal if_addr     : std_logic_vector(31 downto 0) := (others => '0');
    signal if_rd_en    : std_logic := '0';
    signal if_data     : std_logic_vector(31 downto 0);
    signal if_hit      : std_logic;
    signal if_valid    : std_logic;
    signal imem_addr   : std_logic_vector(31 downto 0);
    signal imem_rd_en  : std_logic;
    signal imem_data   : std_logic_vector(255 downto 0) := (others => '0');
    signal imem_valid  : std_logic := '0';
    signal imem_ready  : std_logic := '1';
    
    -- Signaux pour D-Cache
    signal mem_addr    : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_rd_en   : std_logic := '0';
    signal mem_wr_en   : std_logic := '0';
    signal mem_wr_data : std_logic_vector(31 downto 0) := (others => '0');
    signal mem_wr_mask : std_logic_vector(3 downto 0) := (others => '0');
    signal mem_rd_data : std_logic_vector(31 downto 0);
    signal mem_hit     : std_logic;
    signal mem_valid   : std_logic;
    signal ext_addr    : std_logic_vector(31 downto 0);
    signal ext_rd_en   : std_logic;
    signal ext_wr_en   : std_logic;
    signal ext_wr_data : std_logic_vector(255 downto 0);
    signal ext_rd_data : std_logic_vector(255 downto 0) := (others => '0');
    signal ext_valid   : std_logic := '0';
    signal ext_ready   : std_logic := '1';
    
    -- Composants
    component l1_icache is
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            if_addr     : in  std_logic_vector(31 downto 0);
            if_rd_en    : in  std_logic;
            if_data     : out std_logic_vector(31 downto 0);
            if_hit      : out std_logic;
            if_valid    : out std_logic;
            mem_addr    : out std_logic_vector(31 downto 0);
            mem_rd_en   : out std_logic;
            mem_data    : in  std_logic_vector(255 downto 0);
            mem_valid   : in  std_logic;
            mem_ready   : in  std_logic
        );
    end component;
    
    component l1_dcache is
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            mem_addr    : in  std_logic_vector(31 downto 0);
            mem_rd_en   : in  std_logic;
            mem_wr_en   : in  std_logic;
            mem_wr_data : in  std_logic_vector(31 downto 0);
            mem_wr_mask : in  std_logic_vector(3 downto 0);
            mem_rd_data : out std_logic_vector(31 downto 0);
            mem_hit     : out std_logic;
            mem_valid   : out std_logic;
            ext_addr    : out std_logic_vector(31 downto 0);
            ext_rd_en   : out std_logic;
            ext_wr_en   : out std_logic;
            ext_wr_data : out std_logic_vector(255 downto 0);
            ext_rd_data : in  std_logic_vector(255 downto 0);
            ext_valid   : in  std_logic;
            ext_ready   : in  std_logic
        );
    end component;
    
begin
    -- Instanciation des caches
    i_cache: l1_icache
        port map (
            clk         => clk,
            rst_n       => rst_n,
            if_addr     => if_addr,
            if_rd_en    => if_rd_en,
            if_data     => if_data,
            if_hit      => if_hit,
            if_valid    => if_valid,
            mem_addr    => imem_addr,
            mem_rd_en   => imem_rd_en,
            mem_data    => imem_data,
            mem_valid   => imem_valid,
            mem_ready   => imem_ready
        );
    
    d_cache: l1_dcache
        port map (
            clk         => clk,
            rst_n       => rst_n,
            mem_addr    => mem_addr,
            mem_rd_en   => mem_rd_en,
            mem_wr_en   => mem_wr_en,
            mem_wr_data => mem_wr_data,
            mem_wr_mask => mem_wr_mask,
            mem_rd_data => mem_rd_data,
            mem_hit     => mem_hit,
            mem_valid   => mem_valid,
            ext_addr    => ext_addr,
            ext_rd_en   => ext_rd_en,
            ext_wr_en   => ext_wr_en,
            ext_wr_data => ext_wr_data,
            ext_rd_data => ext_rd_data,
            ext_valid   => ext_valid,
            ext_ready   => ext_ready
        );
    
    -- Génération de l'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Process de test principal
    process
        -- Procédure pour simuler un accès mémoire externe
        procedure simulate_memory_access(signal valid: out std_logic;
                                       signal data: out std_logic_vector;
                                       constant delay: in integer) is
        begin
            wait for CLK_PERIOD * delay;
            data <= (others => '1');  -- Données de test
            valid <= '1';
            wait for CLK_PERIOD;
            valid <= '0';
        end procedure;
        
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;
        
        -- Test 1: I-Cache cold miss
        report "Test 1: I-Cache cold miss";
        if_addr <= x"00001000";
        if_rd_en <= '1';
        wait for CLK_PERIOD;
        assert if_hit = '0' report "Expected cold miss" severity error;
        simulate_memory_access(imem_valid, imem_data, 2);
        wait for CLK_PERIOD;
        assert if_valid = '1' report "Data should be valid" severity error;
        if_rd_en <= '0';
        
        -- Test 2: I-Cache hit
        report "Test 2: I-Cache hit";
        wait for CLK_PERIOD * 2;
        if_addr <= x"00001004";  -- Même ligne de cache
        if_rd_en <= '1';
        wait for CLK_PERIOD;
        assert if_hit = '1' report "Expected cache hit" severity error;
        if_rd_en <= '0';
        
        -- Test 3: D-Cache write miss
        report "Test 3: D-Cache write miss";
        mem_addr <= x"00002000";
        mem_wr_en <= '1';
        mem_wr_data <= x"DEADBEEF";
        mem_wr_mask <= "1111";
        wait for CLK_PERIOD;
        assert mem_hit = '0' report "Expected cold miss" severity error;
        simulate_memory_access(ext_valid, ext_rd_data, 2);
        wait for CLK_PERIOD;
        assert mem_valid = '1' report "Write should complete" severity error;
        mem_wr_en <= '0';
        
        -- Test 4: D-Cache read hit
        report "Test 4: D-Cache read hit";
        wait for CLK_PERIOD * 2;
        mem_addr <= x"00002000";
        mem_rd_en <= '1';
        wait for CLK_PERIOD;
        assert mem_hit = '1' report "Expected cache hit" severity error;
        assert mem_rd_data = x"DEADBEEF" report "Invalid read data" severity error;
        mem_rd_en <= '0';
        
        -- Test 5: D-Cache write-back
        report "Test 5: D-Cache write-back";
        mem_addr <= x"00003000";  -- Nouvelle ligne, forçant un write-back
        mem_wr_en <= '1';
        mem_wr_data <= x"CAFEBABE";
        mem_wr_mask <= "1111";
        wait for CLK_PERIOD;
        simulate_memory_access(ext_valid, ext_rd_data, 2);
        wait for CLK_PERIOD;
        assert mem_valid = '1' report "Write should complete" severity error;
        mem_wr_en <= '0';
        
        -- Test 6: Accès concurrent I-Cache et D-Cache
        report "Test 6: Accès concurrent I-Cache et D-Cache";
        if_addr <= x"00004000";
        if_rd_en <= '1';
        mem_addr <= x"00005000";
        mem_rd_en <= '1';
        wait for CLK_PERIOD;
        simulate_memory_access(imem_valid, imem_data, 2);
        simulate_memory_access(ext_valid, ext_rd_data, 2);
        wait for CLK_PERIOD;
        assert if_valid = '1' and mem_valid = '1' 
            report "Both caches should complete access" severity error;
        if_rd_en <= '0';
        mem_rd_en <= '0';
        
        -- Test 7: Test des conditions limites
        report "Test 7: Test des conditions limites";
        -- Test avec adresse maximale
        if_addr <= x"FFFFFFFF";
        if_rd_en <= '1';
        wait for CLK_PERIOD;
        simulate_memory_access(imem_valid, imem_data, 2);
        wait for CLK_PERIOD;
        assert if_valid = '1' report "Access to max address should work" severity error;
        if_rd_en <= '0';
        
        -- Test 8: Test de masque d'écriture partiel
        report "Test 8: Test de masque d'écriture partiel";
        mem_addr <= x"00006000";
        mem_wr_en <= '1';
        mem_wr_data <= x"12345678";
        mem_wr_mask <= "1010";  -- Écriture partielle
        wait for CLK_PERIOD;
        simulate_memory_access(ext_valid, ext_rd_data, 2);
        wait for CLK_PERIOD;
        assert mem_valid = '1' report "Partial write should complete" severity error;
        mem_wr_en <= '0';
        
        -- Fin des tests
        report "Tests terminés";
        wait;
    end process;
    
end architecture testbench;