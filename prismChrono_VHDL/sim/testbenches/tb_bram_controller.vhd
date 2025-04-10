library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_bram_controller is
    -- Pas de ports pour un testbench
end entity tb_bram_controller;

architecture sim of tb_bram_controller is
    -- Composant à tester
    component bram_controller is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            
            -- Interface avec le cœur du processeur
            mem_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
            mem_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire (mot complet)
            mem_tryte_in    : in  EncodedTryte;                  -- Tryte à écrire en mémoire (pour STORET)
            mem_read        : in  std_logic;                     -- Signal de lecture mémoire
            mem_write       : in  std_logic;                     -- Signal d'écriture mémoire (mot complet)
            mem_write_tryte : in  std_logic;                     -- Signal d'écriture mémoire (tryte)
            mem_data_out    : out EncodedWord;                   -- Données lues de la mémoire (mot complet)
            mem_tryte_out   : out EncodedTryte;                  -- Tryte lu de la mémoire (pour LOADT/LOADTU)
            mem_ready       : out std_logic;                     -- Signal indiquant que la mémoire est prête
            alignment_error : out std_logic;                     -- Signal indiquant une erreur d'alignement
            
            -- Interface avec la BRAM (primitive FPGA)
            bram_addr       : out std_logic_vector(15 downto 0); -- Adresse pour la BRAM (binaire)
            bram_data_in    : in  std_logic_vector(47 downto 0); -- Données de la BRAM (binaire)
            bram_data_out   : out std_logic_vector(47 downto 0); -- Données pour la BRAM (binaire)
            bram_we         : out std_logic;                     -- Write enable pour la BRAM
            bram_en         : out std_logic;                     -- Enable pour la BRAM
            bram_tryte_sel  : out std_logic_vector(7 downto 0)   -- Sélection de tryte (8 trytes par mot)
        );
    end component;
    
    -- Signaux pour la simulation
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    -- Signaux pour l'interface CPU
    signal mem_addr : EncodedAddress := (others => '0');
    signal mem_data_in : EncodedWord := (others => '0');
    signal mem_tryte_in : EncodedTryte := (others => '0');
    signal mem_read : std_logic := '0';
    signal mem_write : std_logic := '0';
    signal mem_write_tryte : std_logic := '0';
    signal mem_data_out : EncodedWord;
    signal mem_tryte_out : EncodedTryte;
    signal mem_ready : std_logic;
    signal alignment_error : std_logic;
    
    -- Signaux pour l'interface BRAM
    signal bram_addr : std_logic_vector(15 downto 0);
    signal bram_data_in : std_logic_vector(47 downto 0) := (others => '0');
    signal bram_data_out : std_logic_vector(47 downto 0);
    signal bram_we : std_logic;
    signal bram_en : std_logic;
    signal bram_tryte_sel : std_logic_vector(7 downto 0);
    
    -- Constantes pour les tests
    constant CLK_PERIOD : time := 10 ns;
    
    -- Mémoire simulée pour les tests
    type bram_array_type is array (0 to 255) of std_logic_vector(47 downto 0);
    signal bram_memory : bram_array_type := (others => (others => '0'));
    
    -- Fonction pour créer un mot ternaire encodé avec des valeurs spécifiques
    function create_encoded_word(value : integer) return EncodedWord is
        variable result : EncodedWord := (others => '0');
    begin
        -- Remplir le mot avec une valeur simple pour les tests
        for i in 0 to 23 loop
            if (value + i) mod 3 = 0 then
                result(2*i+1 downto 2*i) := TRIT_Z; -- 0
            elsif (value + i) mod 3 = 1 then
                result(2*i+1 downto 2*i) := TRIT_P; -- +1
            else
                result(2*i+1 downto 2*i) := TRIT_N; -- -1
            end if;
        end loop;
        return result;
    end function;
    
    -- Fonction pour créer un tryte ternaire encodé avec des valeurs spécifiques
    function create_encoded_tryte(value : integer) return EncodedTryte is
        variable result : EncodedTryte := (others => '0');
    begin
        -- Remplir le tryte avec une valeur simple pour les tests
        for i in 0 to 2 loop
            if (value + i) mod 3 = 0 then
                result(2*i+1 downto 2*i) := TRIT_Z; -- 0
            elsif (value + i) mod 3 = 1 then
                result(2*i+1 downto 2*i) := TRIT_P; -- +1
            else
                result(2*i+1 downto 2*i) := TRIT_N; -- -1
            end if;
        end loop;
        return result;
    end function;
    
begin
    -- Instanciation du composant à tester
    uut: bram_controller
        port map (
            clk => clk,
            rst => rst,
            mem_addr => mem_addr,
            mem_data_in => mem_data_in,
            mem_tryte_in => mem_tryte_in,
            mem_read => mem_read,
            mem_write => mem_write,
            mem_write_tryte => mem_write_tryte,
            mem_data_out => mem_data_out,
            mem_tryte_out => mem_tryte_out,
            mem_ready => mem_ready,
            alignment_error => alignment_error,
            bram_addr => bram_addr,
            bram_data_in => bram_data_in,
            bram_data_out => bram_data_out,
            bram_we => bram_we,
            bram_en => bram_en,
            bram_tryte_sel => bram_tryte_sel
        );
    
    -- Processus de génération d'horloge
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de simulation de la BRAM
    process(clk)
        variable addr_index : integer;
    begin
        if rising_edge(clk) then
            -- Convertir l'adresse en index pour le tableau
            addr_index := to_integer(unsigned(bram_addr(15 downto 4)));
            
            -- Écriture en mémoire
            if bram_en = '1' and bram_we = '1' then
                if bram_tryte_sel = "11111111" then
                    -- Écriture d'un mot complet
                    bram_memory(addr_index) <= bram_data_out;
                else
                    -- Écriture sélective de trytes
                    for i in 0 to 7 loop
                        if bram_tryte_sel(i) = '1' then
                            case i is
                                when 0 => bram_memory(addr_index)(5 downto 0) <= bram_data_out(5 downto 0);
                                when 1 => bram_memory(addr_index)(11 downto 6) <= bram_data_out(11 downto 6);
                                when 2 => bram_memory(addr_index)(17 downto 12) <= bram_data_out(17 downto 12);
                                when 3 => bram_memory(addr_index)(23 downto 18) <= bram_data_out(23 downto 18);
                                when 4 => bram_memory(addr_index)(29 downto 24) <= bram_data_out(29 downto 24);
                                when 5 => bram_memory(addr_index)(35 downto 30) <= bram_data_out(35 downto 30);
                                when 6 => bram_memory(addr_index)(41 downto 36) <= bram_data_out(41 downto 36);
                                when 7 => bram_memory(addr_index)(47 downto 42) <= bram_data_out(47 downto 42);
                                when others => null;
                            end case;
                        end if;
                    end loop;
                end if;
            end if;
            
            -- Lecture en mémoire
            if bram_en = '1' and bram_we = '0' then
                bram_data_in <= bram_memory(addr_index);
            end if;
        end if;
    end process;
    
    -- Processus de test
    process
        -- Variables pour les tests
        variable test_word : EncodedWord;
        variable test_tryte : EncodedTryte;
        variable addr_aligned : EncodedAddress;
        variable addr_unaligned : EncodedAddress;
    begin
        -- Initialisation
        report "Début des tests du contrôleur BRAM";
        rst <= '1';
        wait for CLK_PERIOD;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test 1: Écriture et lecture d'un mot aligné
        report "Test 1: Écriture et lecture d'un mot aligné";
        addr_aligned := X"00000010"; -- Adresse alignée sur 8 trytes
        test_word := create_encoded_word(1);
        
        -- Écriture du mot
        mem_addr <= addr_aligned;
        mem_data_in <= test_word;
        mem_write <= '1';
        wait for CLK_PERIOD;
        mem_write <= '0';
        
        -- Attendre que l'écriture soit terminée
        wait until mem_ready = '1';
        wait for CLK_PERIOD;
        
        -- Lecture du mot
        mem_addr <= addr_aligned;
        mem_read <= '1';
        wait for CLK_PERIOD;
        mem_read <= '0';
        
        -- Attendre que la lecture soit terminée
        wait until mem_ready = '1';
        wait for CLK_PERIOD;
        
        -- Vérifier que la valeur lue correspond à la valeur écrite
        assert mem_data_out = test_word
            report "Test 1 échoué: La valeur lue ne correspond pas à la valeur écrite"
            severity error;
        
        -- Test 2: Écriture et lecture d'un tryte
        report "Test 2: Écriture et lecture d'un tryte";
        addr_aligned := X"00000020"; -- Adresse alignée sur 8 trytes
        test_tryte := create_encoded_tryte(2);
        
        -- Écriture du tryte
        mem_addr <= addr_aligned;
        mem_tryte_in <= test_tryte;
        mem_write_tryte <= '1';
        wait for CLK_PERIOD;
        mem_write_tryte <= '0';
        
        -- Attendre que l'écriture soit terminée
        wait until mem_ready = '1';
        wait for CLK_PERIOD;
        
        -- Lecture du tryte
        mem_addr <= addr_aligned;
        mem_read <= '1';
        wait for CLK_PERIOD;
        mem_read <= '0';
        
        -- Attendre que la lecture soit terminée
        wait until mem_ready = '1';
        wait for CLK_PERIOD;
        
        -- Vérifier que le tryte lu correspond au tryte écrit
        assert mem_data_out(5 downto 0) = test_tryte
            report "Test 2 échoué: Le tryte lu ne correspond pas au tryte écrit"
            severity error;
        
        -- Test 3: Accès à un mot non aligné (doit générer une erreur d'alignement)
        report "Test 3: Accès à un mot non aligné";
        addr_unaligned := X"00000015"; -- Adresse non alignée sur 8 trytes
        
        -- Tentative de lecture d'un mot non aligné
        mem_addr <= addr_unaligned;
        mem_read <= '1';
        wait for CLK_PERIOD;
        mem_read <= '0';
        
        -- Vérifier que l'erreur d'alignement est générée
        assert alignment_error = '1'
            report "Test 3 échoué: L'erreur d'alignement n'a pas été générée pour la lecture"
            severity error;
        
        wait for CLK_PERIOD;
        
        -- Tentative d'écriture d'un mot non aligné
        mem_addr <= addr_unaligned;
        mem_data_in <= test_word;
        mem_write <= '1';
        wait for CLK_PERIOD;
        mem_write <= '0';
        
        -- Vérifier que l'erreur d'alignement est générée
        assert alignment_error = '1'
            report "Test 3 échoué: L'erreur d'alignement n'a pas été générée pour l'écriture"
            severity error;
        
        wait for CLK_PERIOD;
        
        -- Test 4: Écriture et lecture de trytes à différentes positions dans un mot
        report "Test 4: Écriture et lecture de trytes à différentes positions";
        addr_aligned := X"00000030"; -- Adresse alignée sur 8 trytes
        
        -- Écrire des trytes à différentes positions
        for i in 0 to 7 loop
            test_tryte := create_encoded_tryte(i);
            mem_addr <= std_logic_vector(unsigned(addr_aligned) + i);
            mem_tryte_in <= test_tryte;
            mem_write_tryte <= '1';
            wait for CLK_PERIOD;
            mem_write_tryte <= '0';
            
            -- Attendre que l'écriture soit terminée
            wait until mem_ready = '1';
            wait for CLK_PERIOD;
        end loop;
        
        -- Lire les trytes à différentes positions
        for i in 0 to 7 loop
            test_tryte := create_encoded_tryte(i);
            mem_addr <= std_logic_vector(unsigned(addr_aligned) + i);
            mem_read <= '1';
            wait for CLK_PERIOD;
            mem_read <= '0';
            
            -- Attendre que la lecture soit terminée
            wait until mem_ready = '1';
            
            -- Vérifier que le tryte lu correspond au tryte écrit
            assert mem_tryte_out = test_tryte
                report "Test 4 échoué: Le tryte lu à la position " & integer'image(i) & " ne correspond pas au tryte écrit"
                severity error;
            
            wait for CLK_PERIOD;
        end loop;
        
        -- Test 5: Vérification de l'endianness (Little-Endian)
        report "Test 5: Vérification de l'endianness (Little-Endian)";
        addr_aligned := X"00000040"; -- Adresse alignée sur 8 trytes
        
        -- Écrire un mot avec des valeurs distinctes pour chaque tryte
        test_word := (others => '0');
        for i in 0 to 7 loop
            test_tryte := create_encoded_tryte(i);
            case i is
                when 0 => test_word(5 downto 0) := test_tryte;
                when 1 => test_word(11 downto 6) := test_tryte;
                when 2 => test_word(17 downto 12) := test_tryte;
                when 3 => test_word(23 downto 18) := test_tryte;
                when 4 => test_word(29 downto 24) := test_tryte;
                when 5 => test_word(35 downto 30) := test_tryte;
                when 6 => test_word(41 downto 36) := test_tryte;
                when 7 => test_word(47 downto 42) := test_tryte;
                when others => null;
            end case;
        end loop;
        
        -- Écrire le mot
        mem_addr <= addr_aligned;
        mem_data_in <= test_word;
        mem_write <= '1';
        wait for CLK_PERIOD;
        mem_write <= '0';
        
        -- Attendre que l'écriture soit terminée
        wait until mem_ready = '1';
        wait for CLK_PERIOD;
        
        -- Lire les trytes individuellement et vérifier l'endianness
        for i in 0 to 7 loop
            test_tryte := create_encoded_tryte(i);
            mem_addr <= std_logic_vector(unsigned(addr_aligned) + i);
            mem_read <= '1';
            wait for CLK_PERIOD;
            mem_read <= '0';
            
            -- Attendre que la lecture soit terminée
            wait until mem_ready = '1';
            
            -- Vérifier que le tryte lu correspond au tryte attendu
            assert mem_tryte_out = test_tryte
                report "Test 5 échoué: Le tryte lu à l'adresse " & integer'image(i) & " ne respecte pas l'endianness Little-Endian"
                severity error;
            
            wait for CLK_PERIOD;
        end loop;
        
        -- Fin des tests
        report "Tous les tests ont été exécutés avec succès";
        wait;
    end process;
    
end architecture sim;