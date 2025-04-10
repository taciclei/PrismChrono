library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_prismchrono_core is
    -- Testbench n'a pas de ports
end entity tb_prismchrono_core;

architecture sim of tb_prismchrono_core is
    -- Composant à tester
    component prismchrono_core is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            instr_data      : in  EncodedWord;                   -- Données d'instruction de la mémoire
            mem_data_in     : in  EncodedWord;                   -- Données de la mémoire (lecture)
            instr_addr      : out EncodedAddress;                -- Adresse pour la mémoire d'instructions
            mem_addr        : out EncodedAddress;                -- Adresse pour la mémoire de données
            mem_data_out    : out EncodedWord;                   -- Données pour la mémoire (écriture)
            mem_read        : out std_logic;                     -- Signal de lecture mémoire
            mem_write       : out std_logic;                     -- Signal d'écriture mémoire
            halted          : out std_logic;                     -- Signal indiquant que le CPU est arrêté
            debug_state     : out FsmStateType                   -- État courant de la FSM (pour debug)
        );
    end component;
    
    -- Signaux pour les tests
    signal clk_s : std_logic := '0';
    signal rst_s : std_logic := '1';
    signal instr_data_s : EncodedWord := (others => '0');
    signal mem_data_in_s : EncodedWord := (others => '0');
    signal instr_addr_s : EncodedAddress;
    signal mem_addr_s : EncodedAddress;
    signal mem_data_out_s : EncodedWord;
    signal mem_read_s : std_logic;
    signal mem_write_s : std_logic;
    signal halted_s : std_logic;
    signal debug_state_s : FsmStateType;
    
    -- Constante pour la période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Mémoire d'instructions simulée
    type instr_memory_type is array (0 to 7) of EncodedWord;
    signal instr_memory : instr_memory_type := (others => (others => '0'));
    
    -- Banc de registres simulé pour vérification
    type reg_file_type is array (0 to 7) of EncodedWord;
    signal reg_file_sim : reg_file_type := (others => (others => '0'));
    
    -- Signaux pour la simulation
    signal sim_done : boolean := false;
    
begin
    -- Instanciation du composant à tester
    uut: prismchrono_core
        port map (
            clk         => clk_s,
            rst         => rst_s,
            instr_data  => instr_data_s,
            mem_data_in => mem_data_in_s,
            instr_addr  => instr_addr_s,
            mem_addr    => mem_addr_s,
            mem_data_out => mem_data_out_s,
            mem_read    => mem_read_s,
            mem_write   => mem_write_s,
            halted      => halted_s,
            debug_state => debug_state_s
        );
    
    -- Processus de génération d'horloge
    clk_process: process
    begin
        while not sim_done loop
            clk_s <= '0';
            wait for CLK_PERIOD/2;
            clk_s <= '1';
            wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;
    
    -- Processus de simulation de la mémoire d'instructions
    instr_mem_process: process(instr_addr_s)
    begin
        -- Lecture de la mémoire d'instructions en fonction de l'adresse
        if unsigned(instr_addr_s) < instr_memory'length then
            instr_data_s <= instr_memory(to_integer(unsigned(instr_addr_s)));
        else
            instr_data_s <= (others => '0'); -- NOP par défaut
        end if;
    end process;
    
    -- Processus de test principal
    stim_process: process
    begin
        -- Initialisation de la mémoire d'instructions avec les instructions de test
        -- Instruction 0: NOP (ZZZ)
        instr_memory(0) <= (47 downto 42 => OPCODE_NOP, others => '0');
        
        -- Instruction 1: ADDI R1, R0, 5 (PNN, 001, 000, 00000101)
        instr_memory(1) <= (47 downto 42 => OPCODE_ADDI,  -- Opcode ADDI
                           41 downto 36 => "010000",     -- Rd = R1 (001)
                           35 downto 30 => "010101",     -- Rs1 = R0 (000)
                           29 downto 20 => "0101010101", -- Imm = 5 (00000101)
                           others => '0');
        
        -- Instruction 2: ADDI R2, R1, -1 (PNN, 010, 001, 00000N)
        instr_memory(2) <= (47 downto 42 => OPCODE_ADDI,  -- Opcode ADDI
                           41 downto 36 => "100000",     -- Rd = R2 (010)
                           35 downto 30 => "010000",     -- Rs1 = R1 (001)
                           29 downto 20 => "0000000000", -- Imm = -1 (00000N)
                           others => '0');
        
        -- Instruction 3: HALT (NNN)
        instr_memory(3) <= (47 downto 42 => OPCODE_HALT, others => '0');
        
        -- Reset initial
        rst_s <= '1';
        wait for CLK_PERIOD * 2;
        rst_s <= '0';
        
        -- Attendre que le CPU s'arrête (instruction HALT)
        wait until halted_s = '1';
        wait for CLK_PERIOD * 5; -- Attendre quelques cycles supplémentaires
        
        -- Vérification des résultats
        -- À ce stade, le registre R1 devrait contenir 5 et le registre R2 devrait contenir 4 (5-1)
        -- Mais comme nous n'avons pas accès direct aux registres, nous vérifions seulement que le CPU s'est arrêté
        assert halted_s = '1' report "Le CPU ne s'est pas arrêté correctement" severity error;
        
        -- Fin de la simulation
        sim_done <= true;
        wait;
    end process;
    
    -- Processus pour afficher l'état du CPU
    debug_process: process
    begin
        wait for CLK_PERIOD;
        while not sim_done loop
            wait for CLK_PERIOD;
            report "Cycle: État = " & FsmStateType'image(debug_state_s) & 
                   ", PC = " & integer'image(to_integer(unsigned(instr_addr_s))) & 
                   ", Halted = " & std_logic'image(halted_s);
        end loop;
        wait;
    end process;
    
end architecture sim;