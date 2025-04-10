library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_pipelined_core is
end entity tb_pipelined_core;

architecture testbench of tb_pipelined_core is
    -- Signaux pour le composant sous test
    signal clk              : std_logic := '0';
    signal rst              : std_logic := '0';
    signal instruction      : EncodedWord := (others => '0');
    signal pc              : EncodedAddress := (others => '0');
    signal mem_read_data   : EncodedWord := (others => '0');
    signal mem_write_data  : EncodedWord := (others => '0');
    signal mem_address     : EncodedAddress := (others => '0');
    signal mem_write_en    : std_logic := '0';
    signal mem_read_en     : std_logic := '0';
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Mémoire simulée
    type memory_type is array (0 to 1023) of EncodedWord;
    signal memory : memory_type := (others => (others => '0'));
    
    -- Signaux pour le debug pipeline
    signal if_id_valid     : std_logic;
    signal id_ex_valid     : std_logic;
    signal ex_mem_valid    : std_logic;
    signal mem_wb_valid    : std_logic;
    signal forward_ex_ex   : std_logic;
    signal forward_mem_ex  : std_logic;
    signal forward_wb_ex   : std_logic;
    signal stall_pipeline  : std_logic;
    signal flush_pipeline  : std_logic;
    
    -- Procédure pour charger le programme de test
    procedure load_test_program is
    begin
        -- Test 1: Instructions indépendantes
        memory(0) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R1, R0, 5
        memory(1) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R2, R0, 3
        memory(2) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R3, R0, 2
        
        -- Test 2: Aléa RAW avec forwarding (EX->EX)
        memory(4) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R1, R0, 5
        memory(5) := encode_trit_vector("PPPNNNZZZ"); -- ADD R2, R1, R1  -- Forwarding EX->EX
        
        -- Test 3: Aléa Load-Use avec stall
        memory(8) := encode_trit_vector("PPPNNNZZZ"); -- LOADW R1, 100(R0)
        memory(9) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R2, R1, 1  -- Stall nécessaire
        
        -- Test 4: Branchement pris avec flush
        memory(12) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R1, R0, 1
        memory(13) := encode_trit_vector("PPPNNNZZZ"); -- BEQ R1, R0, 8   -- Non pris
        memory(14) := encode_trit_vector("PPPNNNZZZ"); -- ADDI R2, R0, 2
        memory(15) := encode_trit_vector("PPPNNNZZZ"); -- BEQ R2, R2, 4   -- Pris, flush nécessaire
    end procedure;
    
    -- Procédure pour vérifier les résultats
    procedure check_results(
        reg_addr : in integer;
        expected_value : in integer;
        test_name : in string
    ) is
    begin
        -- Vérification à implémenter selon l'interface du RegFile
        assert false report "Test " & test_name & ": Registre R" & 
                          integer'image(reg_addr) & " = " & 
                          integer'image(expected_value)
               severity note;
    end procedure;

begin
    -- Instanciation du composant sous test
    UUT: entity work.prismchrono_core
        port map (
            clk              => clk,
            rst              => rst,
            instruction      => instruction,
            pc               => pc,
            mem_read_data    => mem_read_data,
            mem_write_data   => mem_write_data,
            mem_address      => mem_address,
            mem_write_en     => mem_write_en,
            mem_read_en      => mem_read_en,
            -- Signaux debug pipeline
            if_id_valid      => if_id_valid,
            id_ex_valid      => id_ex_valid,
            ex_mem_valid     => ex_mem_valid,
            mem_wb_valid     => mem_wb_valid,
            forward_ex_ex    => forward_ex_ex,
            forward_mem_ex   => forward_mem_ex,
            forward_wb_ex    => forward_wb_ex,
            stall_pipeline   => stall_pipeline,
            flush_pipeline   => flush_pipeline
        );
    
    -- Processus de génération d'horloge
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de simulation de la mémoire
    memory_process: process(clk)
    begin
        if rising_edge(clk) then
            if mem_read_en = '1' then
                mem_read_data <= memory(to_integer(unsigned(mem_address(9 downto 0))));
            end if;
            if mem_write_en = '1' then
                memory(to_integer(unsigned(mem_address(9 downto 0)))) <= mem_write_data;
            end if;
            -- Instruction fetch
            instruction <= memory(to_integer(unsigned(pc(9 downto 0))));
        end if;
    end process;
    
    -- Processus de test principal
    test_process: process
    begin
        -- Chargement du programme de test
        load_test_program;
        
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test 1: Instructions indépendantes
        wait for CLK_PERIOD * 5;
        check_results(1, 5, "Instructions indépendantes - R1");
        check_results(2, 3, "Instructions indépendantes - R2");
        check_results(3, 2, "Instructions indépendantes - R3");
        
        -- Test 2: Aléa RAW avec forwarding
        wait for CLK_PERIOD * 5;
        check_results(1, 5, "Forwarding EX->EX - R1");
        check_results(2, 10, "Forwarding EX->EX - R2");
        
        -- Test 3: Aléa Load-Use
        wait for CLK_PERIOD * 5;
        -- Vérifier que le stall est activé
        assert stall_pipeline = '1' report "Stall non activé pour Load-Use" severity error;
        
        -- Test 4: Branchement pris avec flush
        wait for CLK_PERIOD * 5;
        -- Vérifier que le flush est activé
        assert flush_pipeline = '1' report "Flush non activé pour branchement pris" severity error;
        
        -- Fin des tests
        wait for CLK_PERIOD * 100;
        report "Tests pipeline terminés";
        wait;
    end process;

end architecture testbench;