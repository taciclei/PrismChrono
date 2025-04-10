library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le cache L1
entity tb_l1_cache is
    -- Pas de ports pour un testbench
end entity tb_l1_cache;

architecture sim of tb_l1_cache is
    -- Constantes pour le testbench
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signaux pour le DUT (Device Under Test)
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    
    -- Interface CPU
    signal cpu_addr     : EncodedAddress := (others => '0');
    signal cpu_data_in  : EncodedWord := (others => '0');
    signal cpu_read     : std_logic := '0';
    signal cpu_write    : std_logic := '0';
    signal cpu_data_out : EncodedWord;
    signal cpu_ready    : std_logic;
    signal cpu_stall    : std_logic;
    
    -- Interface mémoire externe
    signal mem_addr     : EncodedAddress;
    signal mem_data_in  : EncodedWord := (others => '0');
    signal mem_data_out : EncodedWord;
    signal mem_read     : std_logic;
    signal mem_write    : std_logic;
    signal mem_ready    : std_logic := '0';
    
    -- Signaux pour la simulation de la mémoire externe
    type MemoryType is array(0 to 1023) of EncodedWord;
    signal ext_memory   : MemoryType := (others => (others => '0'));
    signal mem_latency_counter : integer := 0;
    constant MEM_LATENCY : integer := 5;  -- Latence simulée de la mémoire externe (cycles)
    
    -- Signaux pour les statistiques
    signal cache_hits   : integer := 0;
    signal cache_misses : integer := 0;
    
    -- Composant à tester
    component l1_cache is
        generic (
            CACHE_SIZE_TRYTES : integer := 8192;
            LINE_SIZE_WORDS   : integer := 4;
            ASSOCIATIVITY     : integer := 2
        );
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            cpu_addr        : in  EncodedAddress;
            cpu_data_in     : in  EncodedWord;
            cpu_read        : in  std_logic;
            cpu_write       : in  std_logic;
            cpu_data_out    : out EncodedWord;
            cpu_ready       : out std_logic;
            cpu_stall       : out std_logic;
            mem_addr        : out EncodedAddress;
            mem_data_in     : in  EncodedWord;
            mem_data_out    : out EncodedWord;
            mem_read        : out std_logic;
            mem_write       : out std_logic;
            mem_ready       : in  std_logic
        );
    end component;
    
begin
    -- Instanciation du DUT avec des paramètres réduits pour la simulation
    dut: l1_cache
        generic map (
            CACHE_SIZE_TRYTES => 512,   -- Cache plus petit pour la simulation
            LINE_SIZE_WORDS   => 2,      -- Lignes plus petites
            ASSOCIATIVITY     => 2       -- 2-way set associative
        )
        port map (
            clk          => clk,
            rst          => rst,
            cpu_addr     => cpu_addr,
            cpu_data_in  => cpu_data_in,
            cpu_read     => cpu_read,
            cpu_write    => cpu_write,
            cpu_data_out => cpu_data_out,
            cpu_ready    => cpu_ready,
            cpu_stall    => cpu_stall,
            mem_addr     => mem_addr,
            mem_data_in  => mem_data_in,
            mem_data_out => mem_data_out,
            mem_read     => mem_read,
            mem_write    => mem_write,
            mem_ready    => mem_ready
        );
    
    -- Génération de l'horloge
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Simulation de la mémoire externe avec latence
    process(clk)
        variable addr_index : integer;
    begin
        if rising_edge(clk) then
            -- Par défaut, mémoire pas prête
            mem_ready <= '0';
            
            -- Si demande de lecture ou écriture
            if (mem_read = '1' or mem_write = '1') then
                -- Simuler la latence
                if mem_latency_counter = 0 then
                    mem_latency_counter <= MEM_LATENCY;
                elsif mem_latency_counter = 1 then
                    -- Fin de la latence, mémoire prête
                    mem_ready <= '1';
                    mem_latency_counter <= 0;
                    
                    -- Calculer l'index dans la mémoire simulée
                    addr_index := to_integer(unsigned(mem_addr(9 downto 0)));
                    
                    -- Traiter la demande
                    if mem_read = '1' then
                        -- Lecture
                        mem_data_in <= ext_memory(addr_index);
                    elsif mem_write = '1' then
                        -- Écriture
                        ext_memory(addr_index) <= mem_data_out;
                    end if;
                else
                    -- Décrémenter le compteur de latence
                    mem_latency_counter <= mem_latency_counter - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Processus de test
    process
        -- Procédure pour effectuer une lecture
        procedure cpu_do_read(addr: in EncodedAddress) is
        begin
            -- Initialiser les signaux
            cpu_addr <= addr;
            cpu_read <= '1';
            cpu_write <= '0';
            
            -- Attendre un cycle
            wait until rising_edge(clk);
            
            -- Attendre que le cache soit prêt
            while cpu_stall = '1' loop
                wait until rising_edge(clk);
            end loop;
            
            -- Désactiver la lecture
            cpu_read <= '0';
            
            -- Mettre à jour les statistiques
            if cpu_stall = '0' and cpu_ready = '1' then
                cache_hits <= cache_hits + 1;
                report "Cache HIT on read at address " & to_hstring(addr);
            else
                cache_misses <= cache_misses + 1;
                report "Cache MISS on read at address " & to_hstring(addr);
            end if;
            
            -- Attendre un cycle supplémentaire
            wait until rising_edge(clk);
        end procedure;
        
        -- Procédure pour effectuer une écriture
        procedure cpu_do_write(addr: in EncodedAddress; data: in EncodedWord) is
        begin
            -- Initialiser les signaux
            cpu_addr <= addr;
            cpu_data_in <= data;
            cpu_read <= '0';
            cpu_write <= '1';
            
            -- Attendre un cycle
            wait until rising_edge(clk);
            
            -- Attendre que le cache soit prêt
            while cpu_stall = '1' loop
                wait until rising_edge(clk);
            end loop;
            
            -- Désactiver l'écriture
            cpu_write <= '0';
            
            -- Mettre à jour les statistiques
            if cpu_stall = '0' and cpu_ready = '1' then
                cache_hits <= cache_hits + 1;
                report "Cache HIT on write at address " & to_hstring(addr);
            else
                cache_misses <= cache_misses + 1;
                report "Cache MISS on write at address " & to_hstring(addr);
            end if;
            
            -- Attendre un cycle supplémentaire
            wait until rising_edge(clk);
        end procedure;
        
    begin
        -- Initialisation
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        report "Test 1: Lecture initiale (miss)";
        -- Première lecture - devrait être un miss
        cpu_do_read(X"00000100");
        
        report "Test 2: Lecture répétée (hit)";
        -- Lecture répétée à la même adresse - devrait être un hit
        cpu_do_read(X"00000100");
        
        report "Test 3: Lecture dans la même ligne (hit)";
        -- Lecture dans la même ligne de cache - devrait être un hit
        cpu_do_read(X"00000108");
        
        report "Test 4: Écriture dans une ligne existante (hit)";
        -- Écriture dans une ligne déjà en cache - devrait être un hit
        cpu_do_write(X"00000100", X"123456789ABCDEF0");
        
        report "Test 5: Lecture après écriture (hit)";
        -- Lecture après écriture - devrait être un hit et retourner la valeur écrite
        cpu_do_read(X"00000100");
        
        report "Test 6: Lecture dans une nouvelle ligne (miss)";
        -- Lecture dans une nouvelle ligne - devrait être un miss
        cpu_do_read(X"00000200");
        
        report "Test 7: Test d'associativité - première voie";
        -- Remplir la première voie du set
        cpu_do_read(X"00000300");
        
        report "Test 8: Test d'associativité - deuxième voie";
        -- Remplir la deuxième voie du même set
        cpu_do_read(X"00001300");  -- Même index, tag différent
        
        report "Test 9: Test de remplacement LRU - accès à la première voie";
        -- Accéder à la première voie pour la marquer comme récemment utilisée
        cpu_do_read(X"00000300");
        
        report "Test 10: Test de remplacement LRU - troisième ligne";
        -- Ajouter une troisième ligne dans le même set - devrait remplacer la deuxième voie
        cpu_do_read(X"00002300");  -- Même index, nouveau tag
        
        report "Test 11: Vérification du remplacement - accès à la ligne remplacée";
        -- Essayer d'accéder à la ligne remplacée - devrait être un miss
        cpu_do_read(X"00001300");
        
        report "Test 12: Test de write-back - écriture dans une ligne";
        -- Écrire dans une ligne pour la marquer comme dirty
        cpu_do_write(X"00000300", X"FEDCBA9876543210");
        
        report "Test 13: Test de write-back - forcer un remplacement";
        -- Forcer un remplacement de la ligne dirty - devrait déclencher un write-back
        cpu_do_read(X"00001300");  -- Même index, nouveau tag
        
        -- Attendre quelques cycles pour que toutes les opérations se terminent
        wait for CLK_PERIOD * 20;
        
        -- Afficher les statistiques
        report "Test terminé. Statistiques: " & 
               integer'image(cache_hits) & " hits, " & 
               integer'image(cache_misses) & " misses.";
        
        -- Fin de la simulation
        wait;
    end process;
    
end architecture sim;