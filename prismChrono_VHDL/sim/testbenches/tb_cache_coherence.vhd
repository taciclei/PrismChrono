library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;
use work.cache_coherence_pkg.all;

entity tb_cache_coherence is
end entity tb_cache_coherence;

architecture testbench of tb_cache_coherence is
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    constant CACHE_SIZE : integer := 8192;
    constant LINE_SIZE  : integer := 4;
    constant ASSOC     : integer := 2;
    
    -- Signaux communs
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    
    -- Signaux pour le cache 0
    signal cpu0_addr        : EncodedAddress := (others => '0');
    signal cpu0_data_in     : EncodedWord := (others => '0');
    signal cpu0_read        : std_logic := '0';
    signal cpu0_write       : std_logic := '0';
    signal cpu0_data_out    : EncodedWord;
    signal cpu0_ready       : std_logic;
    signal cpu0_stall       : std_logic;
    
    -- Signaux pour le cache 1
    signal cpu1_addr        : EncodedAddress := (others => '0');
    signal cpu1_data_in     : EncodedWord := (others => '0');
    signal cpu1_read        : std_logic := '0';
    signal cpu1_write       : std_logic := '0';
    signal cpu1_data_out    : EncodedWord;
    signal cpu1_ready       : std_logic;
    signal cpu1_stall       : std_logic;
    
    -- Signaux mémoire partagée
    signal mem_addr0        : EncodedAddress;
    signal mem_addr1        : EncodedAddress;
    signal mem_data_in      : EncodedWord := (others => '0');
    signal mem_data_out0    : EncodedWord;
    signal mem_data_out1    : EncodedWord;
    signal mem_read0        : std_logic;
    signal mem_read1        : std_logic;
    signal mem_write0       : std_logic;
    signal mem_write1       : std_logic;
    signal mem_ready        : std_logic := '1';
    
    -- Signaux de cohérence
    signal snoop_msg0       : CoherenceMessageRecord;
    signal snoop_msg1       : CoherenceMessageRecord;
    signal snoop_msg_valid0 : std_logic := '0';
    signal snoop_msg_valid1 : std_logic := '0';
    signal snoop_resp0      : CoherenceMessageRecord;
    signal snoop_resp1      : CoherenceMessageRecord;
    signal snoop_resp_valid0: std_logic;
    signal snoop_resp_valid1: std_logic;
    
begin
    -- Génération de l'horloge
    clk <= not clk after CLK_PERIOD/2;
    
    -- Instanciation des caches
    cache0: entity work.l1_cache
    generic map (
        CACHE_SIZE_TRYTES => CACHE_SIZE,
        LINE_SIZE_WORDS   => LINE_SIZE,
        ASSOCIATIVITY     => ASSOC
    )
    port map (
        clk              => clk,
        rst              => rst,
        cpu_addr         => cpu0_addr,
        cpu_data_in      => cpu0_data_in,
        cpu_read         => cpu0_read,
        cpu_write        => cpu0_write,
        cpu_data_out     => cpu0_data_out,
        cpu_ready        => cpu0_ready,
        cpu_stall        => cpu0_stall,
        mem_addr         => mem_addr0,
        mem_data_in      => mem_data_in,
        mem_data_out     => mem_data_out0,
        mem_read         => mem_read0,
        mem_write        => mem_write0,
        mem_ready        => mem_ready,
        core_id          => 0,
        snoop_msg        => snoop_msg0,
        snoop_msg_valid  => snoop_msg_valid0,
        snoop_resp       => snoop_resp0,
        snoop_resp_valid => snoop_resp_valid0
    );
    
    cache1: entity work.l1_cache
    generic map (
        CACHE_SIZE_TRYTES => CACHE_SIZE,
        LINE_SIZE_WORDS   => LINE_SIZE,
        ASSOCIATIVITY     => ASSOC
    )
    port map (
        clk              => clk,
        rst              => rst,
        cpu_addr         => cpu1_addr,
        cpu_data_in      => cpu1_data_in,
        cpu_read         => cpu1_read,
        cpu_write        => cpu1_write,
        cpu_data_out     => cpu1_data_out,
        cpu_ready        => cpu1_ready,
        cpu_stall        => cpu1_stall,
        mem_addr         => mem_addr1,
        mem_data_in      => mem_data_in,
        mem_data_out     => mem_data_out1,
        mem_read         => mem_read1,
        mem_write        => mem_write1,
        mem_ready        => mem_ready,
        core_id          => 1,
        snoop_msg        => snoop_msg1,
        snoop_msg_valid  => snoop_msg_valid1,
        snoop_resp       => snoop_resp1,
        snoop_resp_valid => snoop_resp_valid1
    );
    
    -- Processus de test
    process
        -- Procédure pour attendre que le cache soit prêt
        procedure wait_cache_ready(signal ready : in std_logic) is
        begin
            wait until rising_edge(clk) and ready = '1';
        end procedure;
        
        -- Procédure pour écrire dans un cache
        procedure cache_write(
            signal addr : out EncodedAddress;
            signal data : out EncodedWord;
            signal write : out std_logic;
            constant test_addr : in EncodedAddress;
            constant test_data : in EncodedWord
        ) is
        begin
            addr <= test_addr;
            data <= test_data;
            write <= '1';
            wait until rising_edge(clk);
            write <= '0';
        end procedure;
        
        -- Procédure pour lire d'un cache
        procedure cache_read(
            signal addr : out EncodedAddress;
            signal read : out std_logic;
            constant test_addr : in EncodedAddress
        ) is
        begin
            addr <= test_addr;
            read <= '1';
            wait until rising_edge(clk);
            read <= '0';
        end procedure;
        
        -- Procédure pour vérifier l'état MSI d'une ligne de cache
        procedure check_cache_state(
            signal snoop_msg : out CoherenceMessageRecord;
            signal snoop_msg_valid : out std_logic;
            signal snoop_resp : in CoherenceMessageRecord;
            signal snoop_resp_valid : in std_logic;
            constant test_addr : in EncodedAddress;
            constant expected_state : in CacheLineStateType
        ) is
            variable actual_state : CacheLineStateType;
        begin
            -- Envoyer un message de lecture pour vérifier l'état
            snoop_msg.msg_type <= MSG_READ;
            snoop_msg.address <= test_addr;
            snoop_msg_valid <= '1';
            wait until rising_edge(clk);
            snoop_msg_valid <= '0';
            
            -- Attendre la réponse
            wait until rising_edge(clk) and snoop_resp_valid = '1';
            actual_state := decode_msi_state(snoop_resp.data(3 downto 0));
            
            -- Vérifier l'état
            assert actual_state = expected_state
                report "État de cache incorrect. Attendu: " & CacheLineStateType'image(expected_state) &
                       ", Obtenu: " & CacheLineStateType'image(actual_state)
                severity error;
        end procedure;
        
        -- Variables de test
        variable test_addr : EncodedAddress := (others => '0');
        variable test_data : EncodedWord := (others => '0');
        
    begin
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test 1: Transitions d'état MSI de base
        report "Test 1: Transitions d'état MSI de base";
        test_addr := x"00000100";
        test_data := x"ABCD";
        
        -- Cache0 écrit -> État M
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, M);
        
        -- Cache1 lit -> Cache0 passe à S, Cache1 obtient S
        cache_read(cpu1_addr, cpu1_read, test_addr);
        wait_cache_ready(cpu1_ready);
        check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, S);
        check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, S);
        
        -- Test 2: Invalidation lors d'une écriture
        report "Test 2: Invalidation lors d'une écriture";
        test_data := x"5555";
        
        -- Cache0 écrit -> Cache1 doit être invalidé
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, M);
        check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, I);
        
        -- Test 3: Write-Back sur demande de lecture
        report "Test 3: Write-Back sur demande de lecture";
        test_addr := x"00000200";
        test_data := x"AAAA";
        
        -- Cache0 écrit (état M)
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        
        -- Cache1 lit -> Cache0 doit faire un write-back et passer à S
        cache_read(cpu1_addr, cpu1_read, test_addr);
        wait_cache_ready(cpu1_ready);
        check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, S);
        check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, S);
        
        -- Vérifier que les données sont cohérentes
        assert cpu1_data_out = test_data
            report "Test 3 failed: Données incorrectes après write-back"
            severity error;
        
        -- Test 4: Tests de performance et accès concurrents
        report "Test 4: Tests de performance et accès concurrents";
        
        -- Variables pour mesurer le temps
        variable start_time : time;
        variable end_time : time;
        variable elapsed_time : time;
        variable write_latency : time;
        variable read_latency : time;
        variable invalidation_latency : time;
        variable write_back_latency : time;
        variable concurrent_latency : time;
        
        -- Test 4.1: Mesure de la latence d'écriture exclusive
        report "Test 4.1: Mesure de la latence d'écriture exclusive";
        start_time := now;
        test_addr := x"00000300";
        test_data := x"1111";
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        end_time := now;
        write_latency := end_time - start_time;
        report "Latence d'écriture exclusive: " & time'image(write_latency);
        
        -- Test 4.2: Mesure de la latence de lecture partagée
        report "Test 4.2: Mesure de la latence de lecture partagée";
        start_time := now;
        cache_read(cpu1_addr, cpu1_read, test_addr);
        wait_cache_ready(cpu1_ready);
        end_time := now;
        read_latency := end_time - start_time;
        report "Latence de lecture partagée: " & time'image(read_latency);
        
        -- Test 4.3: Mesure de la latence d'invalidation
        report "Test 4.3: Mesure de la latence d'invalidation";
        start_time := now;
        test_data := x"2222";
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, I);
        end_time := now;
        invalidation_latency := end_time - start_time;
        report "Latence d'invalidation: " & time'image(invalidation_latency);
        
        -- Test 4.4: Mesure de la latence de write-back
        report "Test 4.4: Mesure de la latence de write-back";
        test_addr := x"00000310";
        test_data := x"3333";
        -- Mettre cache0 en état M
        cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
        wait_cache_ready(cpu0_ready);
        -- Forcer un write-back en lisant depuis cache1
        start_time := now;
        cache_read(cpu1_addr, cpu1_read, test_addr);
        wait_cache_ready(cpu1_ready);
        end_time := now;
        write_back_latency := end_time - start_time;
        report "Latence de write-back: " & time'image(write_back_latency);
        
        -- Test 4.5: Test de charge avec accès concurrents
        report "Test 4.5: Test de charge avec accès concurrents";
        start_time := now;
        
        -- Séquence d'accès alternés entre les caches
        for i in 0 to 9 loop
            -- Cache0 et Cache1 écrivent sur des adresses différentes
            test_addr := x"00000400" + i * 8;
            test_data := x"4444" + i;
            cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
            
            test_addr := x"00000404" + i * 8;
            test_data := x"5555" + i;
            cache_write(cpu1_addr, cpu1_data_in, cpu1_write, test_addr, test_data);
            
            wait_cache_ready(cpu0_ready);
            wait_cache_ready(cpu1_ready);
            
            -- Vérification des états
            test_addr := x"00000400" + i * 8;
            check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, M);
            
            test_addr := x"00000404" + i * 8;
            check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, M);
        end loop;
        
        end_time := now;
        concurrent_latency := end_time - start_time;
        
        report "Temps total pour accès concurrents: " & time'image(concurrent_latency);
        report "Temps moyen par paire d'accès: " & time'image(concurrent_latency / 10);
        report "Débit effectif: " & integer'image(integer(20.0 * (1 sec / concurrent_latency))) & " opérations/seconde";
        
        -- Test 4.6: Test de performance avec motif ping-pong
        report "Test 4.6: Test de performance avec motif ping-pong";
        start_time := now;
        test_addr := x"00000500";
        
        for i in 0 to 9 loop
            -- Cache0 écrit
            test_data := x"6666" + i;
            cache_write(cpu0_addr, cpu0_data_in, cpu0_write, test_addr, test_data);
            wait_cache_ready(cpu0_ready);
            
            -- Cache1 écrit immédiatement après
            test_data := x"7777" + i;
            cache_write(cpu1_addr, cpu1_data_in, cpu1_write, test_addr, test_data);
            wait_cache_ready(cpu1_ready);
            
            -- Vérification des états
            check_cache_state(snoop_msg0, snoop_msg_valid0, snoop_resp0, snoop_resp_valid0, test_addr, I);
            check_cache_state(snoop_msg1, snoop_msg_valid1, snoop_resp1, snoop_resp_valid1, test_addr, M);
        end loop;
        
        end_time := now;
        elapsed_time := end_time - start_time;
        
        report "Temps total pour motif ping-pong: " & time'image(elapsed_time);
        report "Temps moyen par cycle ping-pong: " & time'image(elapsed_time / 10);
        report "Impact des invalidations: " & time'image(elapsed_time / 20) & " par transition";
        
        -- Fin des tests
        report "Tests de cohérence de cache terminés avec succès";
        wait;
    end process;
    
end architecture testbench;