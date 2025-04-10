library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_pipeline_controller is
    -- Pas de ports pour un testbench
end entity tb_pipeline_controller;

architecture sim of tb_pipeline_controller is
    -- Composant à tester
    component pipeline_controller is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            -- Interface avec le cœur du processeur
            instr_addr      : in  EncodedAddress;                -- Adresse d'instruction demandée
            instr_data      : out EncodedWord;                   -- Instruction décodée
            instr_ready     : out std_logic;                     -- Signal indiquant que l'instruction est prête
            -- Interface avec la mémoire d'instructions
            mem_instr_addr  : out EncodedAddress;                -- Adresse pour la mémoire d'instructions
            mem_instr_data  : in  EncodedWord;                   -- Données de la mémoire d'instructions
            mem_instr_ready : in  std_logic;                     -- Signal indiquant que la mémoire d'instructions est prête
            -- Signaux de contrôle du pipeline
            stall           : in  std_logic;                     -- Signal pour geler le pipeline
            flush           : in  std_logic;                     -- Signal pour vider le pipeline
            branch_taken    : in  std_logic;                     -- Signal indiquant qu'un branchement est pris
            branch_target   : in  EncodedAddress                 -- Adresse cible du branchement
        );
    end component;
    
    -- Signaux pour la stimulation du composant
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    -- Signaux pour l'interface avec le cœur du processeur
    signal instr_addr : EncodedAddress := (others => '0');
    signal instr_data : EncodedWord;
    signal instr_ready : std_logic;
    
    -- Signaux pour l'interface avec la mémoire d'instructions
    signal mem_instr_addr : EncodedAddress;
    signal mem_instr_data : EncodedWord := (others => '0');
    signal mem_instr_ready : std_logic := '0';
    
    -- Signaux de contrôle du pipeline
    signal stall : std_logic := '0';
    signal flush : std_logic := '0';
    signal branch_taken : std_logic := '0';
    signal branch_target : EncodedAddress := (others => '0');
    
    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Procédure pour faciliter l'affichage des messages
    procedure print(msg : string) is
    begin
        report msg severity note;
    end procedure;
    
begin
    -- Instanciation du composant à tester
    uut: pipeline_controller
        port map (
            clk => clk,
            rst => rst,
            instr_addr => instr_addr,
            instr_data => instr_data,
            instr_ready => instr_ready,
            mem_instr_addr => mem_instr_addr,
            mem_instr_data => mem_instr_data,
            mem_instr_ready => mem_instr_ready,
            stall => stall,
            flush => flush,
            branch_taken => branch_taken,
            branch_target => branch_target
        );
    
    -- Processus de génération de l'horloge
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de stimulation
    process
    begin
        -- Initialisation
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        print("Test 1: Récupération d'instruction normale");
        -- Demande d'instruction à l'adresse 0x00000000
        instr_addr <= (others => '0');
        wait for CLK_PERIOD;
        
        -- Vérification que la demande est transmise à la mémoire d'instructions
        assert mem_instr_addr = instr_addr report "Erreur: Adresse d'instruction incorrecte" severity error;
        
        -- Simulation de la réponse de la mémoire d'instructions
        mem_instr_data <= X"100000000000000000000000"; -- Instruction ADDI (exemple)
        mem_instr_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que l'instruction est transmise au CPU
        assert instr_ready = '1' report "Erreur: Signal ready non activé" severity error;
        assert instr_data = mem_instr_data report "Erreur: Instruction incorrecte" severity error;
        
        -- Fin de la récupération
        mem_instr_ready <= '0';
        wait for CLK_PERIOD;
        
        print("Test 2: Gel du pipeline");
        -- Demande d'instruction à l'adresse suivante
        instr_addr <= X"0000000000000001";
        stall <= '1'; -- Gel du pipeline
        wait for CLK_PERIOD;
        
        -- Vérification que l'état du pipeline ne change pas
        assert instr_ready = '0' report "Erreur: Pipeline non gelé" severity error;
        
        -- Fin du gel
        stall <= '0';
        wait for CLK_PERIOD;
        
        -- Simulation de la réponse de la mémoire d'instructions
        mem_instr_data <= X"100001000000000000000000"; -- Instruction ADD (exemple)
        mem_instr_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que l'instruction est transmise au CPU
        assert instr_ready = '1' report "Erreur: Signal ready non activé après gel" severity error;
        assert instr_data = mem_instr_data report "Erreur: Instruction incorrecte après gel" severity error;
        
        -- Fin de la récupération
        mem_instr_ready <= '0';
        wait for CLK_PERIOD;
        
        print("Test 3: Vidage du pipeline");
        -- Demande d'instruction à l'adresse suivante
        instr_addr <= X"0000000000000002";
        flush <= '1'; -- Vidage du pipeline
        wait for CLK_PERIOD;
        
        -- Vérification que le pipeline est vidé
        assert instr_ready = '0' report "Erreur: Pipeline non vidé" severity error;
        
        -- Fin du vidage
        flush <= '0';
        wait for CLK_PERIOD;
        
        -- Simulation de la réponse de la mémoire d'instructions
        mem_instr_data <= X"100010000000000000000000"; -- Instruction SUB (exemple)
        mem_instr_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que l'instruction est transmise au CPU
        assert instr_ready = '1' report "Erreur: Signal ready non activé après vidage" severity error;
        assert instr_data = mem_instr_data report "Erreur: Instruction incorrecte après vidage" severity error;
        
        -- Fin de la récupération
        mem_instr_ready <= '0';
        wait for CLK_PERIOD;
        
        print("Test 4: Branchement");
        -- Demande d'instruction à l'adresse suivante
        instr_addr <= X"0000000000000003";
        branch_taken <= '1'; -- Branchement pris
        branch_target <= X"000000000000000A"; -- Adresse cible du branchement
        wait for CLK_PERIOD;
        
        -- Vérification que le pipeline est vidé pour le branchement
        assert instr_ready = '0' report "Erreur: Pipeline non vidé pour branchement" severity error;
        
        -- Fin du branchement
        branch_taken <= '0';
        wait for CLK_PERIOD;
        
        -- Simulation de la réponse de la mémoire d'instructions
        mem_instr_data <= X"100100000000000000000000"; -- Instruction TMIN (exemple)
        mem_instr_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que l'instruction est transmise au CPU
        assert instr_ready = '1' report "Erreur: Signal ready non activé après branchement" severity error;
        assert instr_data = mem_instr_data report "Erreur: Instruction incorrecte après branchement" severity error;
        
        -- Fin de la récupération
        mem_instr_ready <= '0';
        wait for CLK_PERIOD;
        
        -- Fin de la simulation
        print("Tous les tests ont été exécutés avec succès");
        wait;
    end process;
    
end architecture sim;