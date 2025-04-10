library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_memory_controller is
    -- Pas de ports pour un testbench
end entity tb_memory_controller;

architecture sim of tb_memory_controller is
    -- Composant à tester
    component memory_controller is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            -- Interface avec le cœur du processeur
            mem_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
            mem_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire
            mem_read        : in  std_logic;                     -- Signal de lecture mémoire
            mem_write       : in  std_logic;                     -- Signal d'écriture mémoire
            mem_data_out    : out EncodedWord;                   -- Données lues de la mémoire
            mem_ready       : out std_logic;                     -- Signal indiquant que la mémoire est prête
            -- Interface avec la mémoire externe
            ext_mem_addr    : out EncodedAddress;                -- Adresse pour la mémoire externe
            ext_mem_data_in : in  EncodedWord;                   -- Données de la mémoire externe (lecture)
            ext_mem_data_out: out EncodedWord;                   -- Données pour la mémoire externe (écriture)
            ext_mem_read    : out std_logic;                     -- Signal de lecture mémoire externe
            ext_mem_write   : out std_logic;                     -- Signal d'écriture mémoire externe
            ext_mem_ready   : in  std_logic                      -- Signal indiquant que la mémoire externe est prête
        );
    end component;
    
    -- Signaux pour la stimulation du composant
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    -- Signaux pour l'interface avec le cœur du processeur
    signal mem_addr : EncodedAddress := (others => '0');
    signal mem_data_in : EncodedWord := (others => '0');
    signal mem_read : std_logic := '0';
    signal mem_write : std_logic := '0';
    signal mem_data_out : EncodedWord;
    signal mem_ready : std_logic;
    
    -- Signaux pour l'interface avec la mémoire externe
    signal ext_mem_addr : EncodedAddress;
    signal ext_mem_data_in : EncodedWord := (others => '0');
    signal ext_mem_data_out : EncodedWord;
    signal ext_mem_read : std_logic;
    signal ext_mem_write : std_logic;
    signal ext_mem_ready : std_logic := '0';
    
    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Procédure pour faciliter l'affichage des messages
    procedure print(msg : string) is
    begin
        report msg severity note;
    end procedure;
    
begin
    -- Instanciation du composant à tester
    uut: memory_controller
        port map (
            clk => clk,
            rst => rst,
            mem_addr => mem_addr,
            mem_data_in => mem_data_in,
            mem_read => mem_read,
            mem_write => mem_write,
            mem_data_out => mem_data_out,
            mem_ready => mem_ready,
            ext_mem_addr => ext_mem_addr,
            ext_mem_data_in => ext_mem_data_in,
            ext_mem_data_out => ext_mem_data_out,
            ext_mem_read => ext_mem_read,
            ext_mem_write => ext_mem_write,
            ext_mem_ready => ext_mem_ready
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
        
        print("Test 1: Lecture mémoire sans cache hit");
        -- Demande de lecture à l'adresse 0x00000000
        mem_addr <= (others => '0');
        mem_read <= '1';
        mem_write <= '0';
        wait for CLK_PERIOD;
        
        -- Vérification que la demande est transmise à la mémoire externe
        assert ext_mem_read = '1' report "Erreur: Signal de lecture externe non activé" severity error;
        assert ext_mem_write = '0' report "Erreur: Signal d'écriture externe activé par erreur" severity error;
        assert ext_mem_addr = mem_addr report "Erreur: Adresse externe incorrecte" severity error;
        
        -- Simulation de la réponse de la mémoire externe
        ext_mem_data_in <= X"123456789ABCDEF0123456789ABCDEF0"; -- Valeur arbitraire
        wait for CLK_PERIOD * 2;
        ext_mem_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que les données sont transmises au CPU
        assert mem_ready = '1' report "Erreur: Signal ready non activé" severity error;
        assert mem_data_out = ext_mem_data_in report "Erreur: Données de sortie incorrectes" severity error;
        
        -- Fin de la lecture
        ext_mem_ready <= '0';
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        print("Test 2: Lecture mémoire avec cache hit");
        -- Nouvelle demande de lecture à la même adresse (devrait être en cache)
        mem_read <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que les données sont fournies directement depuis le cache
        assert mem_ready = '1' report "Erreur: Signal ready non activé pour le cache hit" severity error;
        assert mem_data_out = ext_mem_data_in report "Erreur: Données de cache incorrectes" severity error;
        
        -- Fin de la lecture
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        print("Test 3: Écriture mémoire");
        -- Demande d'écriture à l'adresse 0x00000000
        mem_addr <= (others => '0');
        mem_data_in <= X"FEDCBA9876543210FEDCBA9876543210"; -- Valeur arbitraire
        mem_write <= '1';
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- Vérification que la demande est transmise à la mémoire externe
        assert ext_mem_write = '1' report "Erreur: Signal d'écriture externe non activé" severity error;
        assert ext_mem_read = '0' report "Erreur: Signal de lecture externe activé par erreur" severity error;
        assert ext_mem_addr = mem_addr report "Erreur: Adresse externe incorrecte pour l'écriture" severity error;
        assert ext_mem_data_out = mem_data_in report "Erreur: Données d'écriture incorrectes" severity error;
        
        -- Simulation de la confirmation d'écriture
        wait for CLK_PERIOD * 2;
        ext_mem_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la confirmation est transmise au CPU
        assert mem_ready = '1' report "Erreur: Signal ready non activé pour l'écriture" severity error;
        
        -- Fin de l'écriture
        ext_mem_ready <= '0';
        mem_write <= '0';
        wait for CLK_PERIOD;
        
        print("Test 4: Vérification de l'invalidation du cache après écriture");
        -- Nouvelle demande de lecture à la même adresse (le cache devrait être invalidé)
        mem_read <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la demande est transmise à la mémoire externe (pas de hit cache)
        assert ext_mem_read = '1' report "Erreur: Signal de lecture externe non activé après invalidation du cache" severity error;
        
        -- Simulation de la réponse de la mémoire externe avec les nouvelles données
        ext_mem_data_in <= X"FEDCBA9876543210FEDCBA9876543210"; -- Mêmes données que celles écrites
        wait for CLK_PERIOD * 2;
        ext_mem_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que les nouvelles données sont transmises au CPU
        assert mem_ready = '1' report "Erreur: Signal ready non activé" severity error;
        assert mem_data_out = ext_mem_data_in report "Erreur: Nouvelles données de sortie incorrectes" severity error;
        
        -- Fin de la lecture
        ext_mem_ready <= '0';
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        print("Test 5: Lecture à une adresse différente");
        -- Demande de lecture à une nouvelle adresse
        mem_addr <= X"0000000000000001"; -- Adresse différente
        mem_read <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la demande est transmise à la mémoire externe
        assert ext_mem_read = '1' report "Erreur: Signal de lecture externe non activé pour nouvelle adresse" severity error;
        assert ext_mem_addr = mem_addr report "Erreur: Adresse externe incorrecte pour nouvelle lecture" severity error;
        
        -- Simulation de la réponse de la mémoire externe
        ext_mem_data_in <= X"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"; -- Nouvelle valeur
        wait for CLK_PERIOD * 2;
        ext_mem_ready <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que les données sont transmises au CPU
        assert mem_ready = '1' report "Erreur: Signal ready non activé pour nouvelle adresse" severity error;
        assert mem_data_out = ext_mem_data_in report "Erreur: Données de sortie incorrectes pour nouvelle adresse" severity error;
        
        -- Fin de la lecture
        ext_mem_ready <= '0';
        mem_read <= '0';
        wait for CLK_PERIOD;
        
        -- Fin de la simulation
        print("Tous les tests ont été exécutés avec succès");
        wait;
    end process;
    
end architecture sim;