library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.prismchrono_types_pkg.all;

entity tb_bus_arbiter_multicore is
end entity tb_bus_arbiter_multicore;

architecture sim of tb_bus_arbiter_multicore is
  -- Constantes
  constant CLK_PERIOD : time := 10 ns;
  constant N_MASTERS : integer := 4;
  
  -- Signaux de test
  signal clk           : std_logic := '0';
  signal rst_n         : std_logic := '0';
  signal m_req         : std_logic_vector(N_MASTERS-1 downto 0) := (others => '0');
  signal m_addr        : std_logic_vector(N_MASTERS*24-1 downto 0) := (others => '0');
  signal m_wr          : std_logic_vector(N_MASTERS-1 downto 0) := (others => '0');
  signal m_wdata       : std_logic_vector(N_MASTERS*24-1 downto 0) := (others => '0');
  signal m_valid       : std_logic_vector(N_MASTERS-1 downto 0);
  signal m_rdata       : std_logic_vector(N_MASTERS*24-1 downto 0);
  signal s_req         : std_logic;
  signal s_addr        : std_logic_vector(23 downto 0);
  signal s_wr          : std_logic;
  signal s_wdata       : std_logic_vector(23 downto 0);
  signal s_valid       : std_logic := '0';
  signal s_rdata       : std_logic_vector(23 downto 0) := (others => '0');
  
  -- Compteurs pour les statistiques
  signal access_count    : integer_vector(N_MASTERS-1 downto 0) := (others => 0);
  signal waiting_cycles  : integer_vector(N_MASTERS-1 downto 0) := (others => 0);
  signal total_latency   : integer_vector(N_MASTERS-1 downto 0) := (others => 0);
  signal max_latency     : integer_vector(N_MASTERS-1 downto 0) := (others => 0);
  signal min_latency     : integer_vector(N_MASTERS-1 downto 0) := (others => 16#7FFFFFFF#);
  signal request_start   : time_vector(N_MASTERS-1 downto 0);
  signal concurrent_reqs : integer := 0;
  
begin
  -- Instanciation du DUT
  dut: entity work.bus_arbiter
    generic map (
      N_MASTERS => N_MASTERS
    )
    port map (
      clk      => clk,
      rst_n    => rst_n,
      m_req    => m_req,
      m_addr   => m_addr,
      m_wr     => m_wr,
      m_wdata  => m_wdata,
      m_valid  => m_valid,
      m_rdata  => m_rdata,
      s_req    => s_req,
      s_addr   => s_addr,
      s_wr     => s_wr,
      s_wdata  => s_wdata,
      s_valid  => s_valid,
      s_rdata  => s_rdata
    );

  -- Génération de l'horloge
  clk <= not clk after CLK_PERIOD/2;

  -- Process de stimulation
  stim_proc: process
    -- Procédure pour générer une requête de lecture
    procedure generate_read_request(
      master_id : in integer;
      address   : in std_logic_vector(23 downto 0)
    ) is
      variable start_time : time;
      variable latency   : integer;
    begin
      start_time := now;
      request_start(master_id) <= start_time;
      concurrent_reqs <= concurrent_reqs + 1;
      
      m_req(master_id) <= '1';
      m_addr(master_id*24+23 downto master_id*24) <= address;
      m_wr(master_id) <= '0';
      wait until m_valid(master_id) = '1';
      
      latency := (now - start_time) / CLK_PERIOD;
      total_latency(master_id) <= total_latency(master_id) + latency;
      if latency > max_latency(master_id) then
        max_latency(master_id) <= latency;
      end if;
      if latency < min_latency(master_id) then
        min_latency(master_id) <= latency;
      end if;
      
      m_req(master_id) <= '0';
      access_count(master_id) <= access_count(master_id) + 1;
      concurrent_reqs <= concurrent_reqs - 1;
      wait for CLK_PERIOD;
    end procedure;

    -- Procédure pour générer une requête d'écriture
    procedure generate_write_request(
      master_id : in integer;
      address   : in std_logic_vector(23 downto 0);
      data      : in std_logic_vector(23 downto 0)
    ) is
    begin
      m_req(master_id) <= '1';
      m_addr(master_id*24+23 downto master_id*24) <= address;
      m_wr(master_id) <= '1';
      m_wdata(master_id*24+23 downto master_id*24) <= data;
      wait until m_valid(master_id) = '1';
      m_req(master_id) <= '0';
      access_count(master_id) <= access_count(master_id) + 1;
      wait for CLK_PERIOD;
    end procedure;

  begin
    -- Reset initial
    wait for CLK_PERIOD*2;
    rst_n <= '1';
    wait for CLK_PERIOD*2;

    -- Test 1: Accès séquentiels simples
    report "Test 1: Accès séquentiels simples";
    for i in 0 to N_MASTERS-1 loop
      generate_read_request(i, std_logic_vector(to_unsigned(i*16#100#, 24)));
    end loop;

    -- Test 2: Accès concurrents
    report "Test 2: Accès concurrents";
    -- Tous les maîtres demandent l'accès simultanément
    for i in 0 to N_MASTERS-1 loop
      m_req(i) <= '1';
      m_addr(i*24+23 downto i*24) <= std_logic_vector(to_unsigned(i*16#200#, 24));
      m_wr(i) <= '0';
    end loop;
    
    -- Attendre que toutes les requêtes soient servies
    wait for CLK_PERIOD*10;
    for i in 0 to N_MASTERS-1 loop
      m_req(i) <= '0';
    end loop;

    -- Test 3: Mélange lecture/écriture
    report "Test 3: Mélange lecture/écriture";
    generate_write_request(0, X"000100", X"AAAAAA");
    generate_read_request(1, X"000100");
    generate_write_request(2, X"000200", X"BBBBBB");
    generate_read_request(3, X"000200");

    -- Test 4: Stress test avec accès rapides et mesures de performance
    report "Test 4: Stress test avec accès rapides et mesures de performance";
    for i in 0 to 19 loop  -- 20 cycles de test
      for m in 0 to N_MASTERS-1 loop
        if (m + i) mod 2 = 0 then
          generate_read_request(m, std_logic_vector(to_unsigned(i*16#100# + m, 24)));
        else
          generate_write_request(m, std_logic_vector(to_unsigned(i*16#100# + m, 24)),
                                std_logic_vector(to_unsigned(16#FFFFFF# - m, 24)));
        end if;
      end loop;
    end loop;

    -- Test 5: Test de contention maximale
    report "Test 5: Test de contention maximale";
    for i in 0 to 9 loop  -- 10 cycles de test intense
      -- Tous les maîtres demandent l'accès simultanément
      for m in 0 to N_MASTERS-1 loop
        generate_read_request(m, std_logic_vector(to_unsigned(16#F000# + m, 24)));
      end loop;
    end loop;

    -- Afficher les statistiques détaillées
    report "Test terminé. Statistiques détaillées:";
    for i in 0 to N_MASTERS-1 loop
      report "Maître " & integer'image(i) & ":";
      report "  Nombre d'accès: " & integer'image(access_count(i));
      report "  Latence moyenne: " & integer'image(total_latency(i) / access_count(i)) & " cycles";
      report "  Latence max: " & integer'image(max_latency(i)) & " cycles";
      report "  Latence min: " & integer'image(min_latency(i)) & " cycles";
    end loop;
    report "Nombre maximum de requêtes simultanées: " & integer'image(concurrent_reqs);

    wait for CLK_PERIOD*10;
    report "Simulation terminée avec succès";
    wait;
  end process;

  -- Process pour simuler la mémoire
  mem_proc: process
  begin
    wait until s_req = '1';
    wait for CLK_PERIOD*2;  -- Latence mémoire simulée
    s_valid <= '1';
    if s_wr = '0' then
      -- Pour la lecture, renvoyer une donnée basée sur l'adresse
      s_rdata <= s_addr;
    end if;
    wait for CLK_PERIOD;
    s_valid <= '0';
  end process;

end architecture sim;