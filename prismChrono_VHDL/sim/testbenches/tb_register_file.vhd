library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_register_file is
    -- Testbench n'a pas de ports
end entity tb_register_file;

architecture sim of tb_register_file is
    -- Composant à tester
    component register_file is
        port (
            clk      : in  std_logic;                     -- Horloge
            rst      : in  std_logic;                     -- Reset asynchrone
            wr_en    : in  std_logic;                     -- Enable d'écriture
            wr_addr  : in  std_logic_vector(2 downto 0);  -- Adresse d'écriture (3 bits pour 8 registres)
            wr_data  : in  EncodedWord;                   -- Données à écrire (24 trits)
            rd_addr1 : in  std_logic_vector(2 downto 0);  -- Adresse de lecture 1
            rd_data1 : out EncodedWord;                   -- Données lues 1
            rd_addr2 : in  std_logic_vector(2 downto 0);  -- Adresse de lecture 2
            rd_data2 : out EncodedWord                    -- Données lues 2
        );
    end component;
    
    -- Signaux pour les tests
    signal clk_s      : std_logic := '0';
    signal rst_s      : std_logic := '0';
    signal wr_en_s    : std_logic := '0';
    signal wr_addr_s  : std_logic_vector(2 downto 0) := (others => '0');
    signal wr_data_s  : EncodedWord := (others => '0');
    signal rd_addr1_s : std_logic_vector(2 downto 0) := (others => '0');
    signal rd_data1_s : EncodedWord;
    signal rd_addr2_s : std_logic_vector(2 downto 0) := (others => '0');
    signal rd_data2_s : EncodedWord;
    
    -- Constantes pour les tests
    constant CLK_PERIOD : time := 10 ns;
    
    -- Fonction pour initialiser un mot avec une valeur ternaire spécifique
    function init_word(value: EncodedTrit) return EncodedWord is
        variable word : EncodedWord;
    begin
        for i in 0 to 23 loop
            word(i*2+1 downto i*2) := value;
        end loop;
        return word;
    end function;
    
    -- Fonction pour définir un trit spécifique dans un mot
    procedure set_trit(signal word: out EncodedWord; index: natural; trit: EncodedTrit) is
    begin
        word(index*2+1 downto index*2) <= trit;
    end procedure;
    
    -- Fonction pour obtenir un trit spécifique d'un mot
    function get_trit(word: EncodedWord; index: natural) return EncodedTrit is
    begin
        return word(index*2+1 downto index*2);
    end function;
    
begin
    -- Instanciation du composant à tester
    UUT: register_file
        port map (
            clk      => clk_s,
            rst      => rst_s,
            wr_en    => wr_en_s,
            wr_addr  => wr_addr_s,
            wr_data  => wr_data_s,
            rd_addr1 => rd_addr1_s,
            rd_data1 => rd_data1_s,
            rd_addr2 => rd_addr2_s,
            rd_data2 => rd_data2_s
        );
    
    -- Génération de l'horloge
    CLK_GEN: process
    begin
        clk_s <= '0';
        wait for CLK_PERIOD/2;
        clk_s <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Process de test
    STIM_PROC: process
        -- Variables pour les tests
        variable test_data1 : EncodedWord;
        variable test_data2 : EncodedWord;
    begin
        report "Début des tests pour le banc de registres";
        
        -- Test 1: Reset
        report "Test 1: Reset";
        rst_s <= '1';
        wait for CLK_PERIOD;
        rst_s <= '0';
        
        -- Vérification que tous les registres sont à zéro après reset
        for i in 0 to 7 loop
            rd_addr1_s <= std_logic_vector(to_unsigned(i, 3));
            wait for CLK_PERIOD/10;  -- Attente courte pour la propagation combinatoire
            assert rd_data1_s = init_word(TRIT_Z)
                report "Test 1 échoué: Le registre " & integer'image(i) & " n'est pas initialisé à zéro après reset"
                severity error;
        end loop;
        
        -- Test 2: Écriture et lecture simple
        report "Test 2: Ecriture et lecture simple";
        test_data1 := init_word(TRIT_P);  -- Tous les trits à P
        wr_en_s <= '1';
        wr_addr_s <= "001";  -- Registre 1
        wr_data_s <= test_data1;
        wait for CLK_PERIOD;  -- Attendre un cycle d'horloge pour l'écriture
        wr_en_s <= '0';
        
        -- Lecture du registre 1
        rd_addr1_s <= "001";
        wait for CLK_PERIOD/10;  -- Attente courte pour la propagation combinatoire
        assert rd_data1_s = test_data1
            report "Test 2 échoué: La valeur lue ne correspond pas à la valeur écrite"
            severity error;
        
        -- Test 3: Écriture et lecture de plusieurs registres
        report "Test 3: Ecriture et lecture de plusieurs registres";
        test_data1 := init_word(TRIT_P);  -- Tous les trits à P
        test_data2 := init_word(TRIT_N);  -- Tous les trits à N
        
        -- Écriture dans le registre 2
        wr_en_s <= '1';
        wr_addr_s <= "010";  -- Registre 2
        wr_data_s <= test_data1;
        wait for CLK_PERIOD;  -- Attendre un cycle d'horloge pour l'écriture
        
        -- Écriture dans le registre 3
        wr_addr_s <= "011";  -- Registre 3
        wr_data_s <= test_data2;
        wait for CLK_PERIOD;  -- Attendre un cycle d'horloge pour l'écriture
        wr_en_s <= '0';
        
        -- Lecture des registres 2 et 3 simultanément
        rd_addr1_s <= "010";  -- Registre 2
        rd_addr2_s <= "011";  -- Registre 3
        wait for CLK_PERIOD/10;  -- Attente courte pour la propagation combinatoire
        
        assert rd_data1_s = test_data1
            report "Test 3 échoué: La valeur lue du registre 2 ne correspond pas à la valeur écrite"
            severity error;
        assert rd_data2_s = test_data2
            report "Test 3 échoué: La valeur lue du registre 3 ne correspond pas à la valeur écrite"
            severity error;
        
        -- Test 4: Lecture et écriture simultanées sur le même registre
        report "Test 4: Lecture et écriture simultanées sur le même registre";
        test_data1 := init_word(TRIT_P);  -- Tous les trits à P
        test_data2 := init_word(TRIT_N);  -- Tous les trits à N
        
        -- Écriture dans le registre 4
        wr_en_s <= '1';
        wr_addr_s <= "100";  -- Registre 4
        wr_data_s <= test_data1;
        wait for CLK_PERIOD;  -- Attendre un cycle d'horloge pour l'écriture
        
        -- Lecture du registre 4 pour vérifier
        rd_addr1_s <= "100";
        wait for CLK_PERIOD/10;  -- Attente courte pour la propagation combinatoire
        assert rd_data1_s = test_data1
            report "Test 4 échoué: La valeur initiale du registre 4 ne correspond pas à la valeur écrite"
            severity error;
        
        -- Écriture et lecture simultanées sur le registre 4
        wr_data_s <= test_data2;  -- Nouvelle valeur à écrire
        rd_addr1_s <= "100";      -- Lecture du même registre
        wait for CLK_PERIOD/2;    -- Attendre la moitié d'un cycle d'horloge
        
        -- À ce stade, la lecture doit encore retourner l'ancienne valeur
        assert rd_data1_s = test_data1
            report "Test 4 échoué: La valeur lue avant le front d'horloge ne correspond pas à l'ancienne valeur"
            severity error;
        
        wait for CLK_PERIOD/2;    -- Attendre jusqu'au prochain front d'horloge
        wait for CLK_PERIOD/10;   -- Attente courte pour la propagation combinatoire
        
        -- Maintenant, la lecture doit retourner la nouvelle valeur
        assert rd_data1_s = test_data2
            report "Test 4 échoué: La valeur lue après le front d'horloge ne correspond pas à la nouvelle valeur"
            severity error;
        
        wr_en_s <= '0';
        
        -- Fin des tests
        report "Tous les tests ont été exécutés avec succès";
        wait;
    end process;
    
end architecture sim;