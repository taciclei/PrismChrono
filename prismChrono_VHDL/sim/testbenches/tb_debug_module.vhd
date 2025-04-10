library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;
use work.debug_pkg.all;

entity tb_debug_module is
end entity tb_debug_module;

architecture sim of tb_debug_module is
  -- Constantes
  constant CLK_PERIOD : time := 10 ns;  -- 100 MHz
  
  -- Signaux de test
  signal clk           : std_logic := '0';
  signal rst_n         : std_logic := '0';
  signal uart_rx       : std_logic := '1';
  signal uart_tx       : std_logic;
  signal cpu_halt_req  : std_logic;
  signal cpu_halted    : std_logic := '0';
  signal cpu_resume    : std_logic;
  signal cpu_step      : std_logic;
  signal reg_addr      : std_logic_vector(3 downto 0);
  signal reg_wdata     : std_logic_vector(8 downto 0);
  signal reg_rdata     : std_logic_vector(8 downto 0) := (others => '0');
  signal reg_we        : std_logic;
  signal mem_addr      : std_logic_vector(17 downto 0);
  signal mem_wdata     : std_logic_vector(8 downto 0);
  signal mem_rdata     : std_logic_vector(8 downto 0) := (others => '0');
  signal mem_we        : std_logic;
  signal mem_valid     : std_logic;
  signal mem_ready     : std_logic := '1';
  
  -- Procédure pour envoyer une commande via UART
  procedure send_uart_byte(byte : in std_logic_vector(7 downto 0)) is
    constant BIT_PERIOD : time := 8680 ns;  -- 115200 baud
  begin
    -- Start bit
    uart_rx <= '0';
    wait for BIT_PERIOD;
    
    -- Data bits
    for i in 0 to 7 loop
      uart_rx <= byte(i);
      wait for BIT_PERIOD;
    end loop;
    
    -- Stop bit
    uart_rx <= '1';
    wait for BIT_PERIOD;
  end procedure;
  
begin

  -- Génération horloge
  process
  begin
    wait for CLK_PERIOD/2;
    clk <= not clk;
  end process;
  
  -- Instance DUT
  dut: entity work.debug_module
    port map (
      clk          => clk,
      rst_n        => rst_n,
      uart_rx      => uart_rx,
      uart_tx      => uart_tx,
      cpu_halt_req => cpu_halt_req,
      cpu_halted   => cpu_halted,
      cpu_resume   => cpu_resume,
      cpu_step     => cpu_step,
      reg_addr     => reg_addr,
      reg_wdata    => reg_wdata,
      reg_rdata    => reg_rdata,
      reg_we       => reg_we,
      mem_addr     => mem_addr,
      mem_wdata    => mem_wdata,
      mem_rdata    => mem_rdata,
      mem_we       => mem_we,
      mem_valid    => mem_valid,
      mem_ready    => mem_ready
    );
  
  -- Process de test
  process
  begin
    -- Reset initial
    rst_n <= '0';
    wait for 100 ns;
    rst_n <= '1';
    wait for 100 ns;
    
    -- Test 1: Commande halt
    report "Test 1: Commande halt";
    send_uart_byte(CMD_HALT);
    wait for 1 us;
    assert cpu_halt_req = '1' report "Erreur: cpu_halt_req non activé" severity error;
    
    -- Simule CPU halted
    cpu_halted <= '1';
    wait for 1 us;
    assert cpu_halt_req = '0' report "Erreur: cpu_halt_req toujours actif" severity error;
    
    -- Test 2: Commande step
    report "Test 2: Commande step";
    send_uart_byte(CMD_STEP);
    wait for 1 us;
    assert cpu_step = '1' report "Erreur: cpu_step non activé" severity error;
    wait for CLK_PERIOD;
    assert cpu_step = '0' report "Erreur: cpu_step toujours actif" severity error;
    
    -- Test 3: Commande continue
    report "Test 3: Commande continue";
    send_uart_byte(CMD_CONTINUE);
    wait for 1 us;
    assert cpu_resume = '1' report "Erreur: cpu_resume non activé" severity error;
    wait for CLK_PERIOD;
    assert cpu_resume = '0' report "Erreur: cpu_resume toujours actif" severity error;
    
    -- Test 4: Accès registres
    report "Test 4: Accès registres";
    -- Écriture registre
    send_uart_byte(CMD_REG_WRITE);
    send_uart_byte(X"05"); -- Adresse registre
    send_uart_byte(X"A5"); -- Données
    wait for 2 us;
    assert reg_we = '1' report "Erreur: reg_we non activé" severity error;
    assert reg_addr = X"5" report "Erreur: mauvaise adresse registre" severity error;
    assert reg_wdata = "1" & X"A5" report "Erreur: mauvaises données registre" severity error;
    
    -- Lecture registre
    reg_rdata <= "0" & X"3C";
    send_uart_byte(CMD_REG_READ);
    send_uart_byte(X"05"); -- Adresse registre
    wait for 2 us;
    assert reg_addr = X"5" report "Erreur: mauvaise adresse registre en lecture" severity error;
    
    -- Test 5: Accès mémoire
    report "Test 5: Accès mémoire";
    -- Écriture mémoire
    send_uart_byte(CMD_MEM_WRITE);
    send_uart_byte(X"12"); -- Adresse MSB
    send_uart_byte(X"34"); -- Adresse LSB
    send_uart_byte(X"7B"); -- Données
    wait for 2 us;
    assert mem_we = '1' report "Erreur: mem_we non activé" severity error;
    assert mem_addr = X"1234" report "Erreur: mauvaise adresse mémoire" severity error;
    assert mem_wdata = "1" & X"7B" report "Erreur: mauvaises données mémoire" severity error;
    
    -- Lecture mémoire
    mem_rdata <= "0" & X"F0";
    send_uart_byte(CMD_MEM_READ);
    send_uart_byte(X"12"); -- Adresse MSB
    send_uart_byte(X"34"); -- Adresse LSB
    wait for 2 us;
    assert mem_valid = '1' report "Erreur: mem_valid non activé" severity error;
    assert mem_addr = X"1234" report "Erreur: mauvaise adresse mémoire en lecture" severity error;
    
    -- Test 6: Timeout mémoire
    report "Test 6: Timeout mémoire";
    mem_ready <= '0';
    send_uart_byte(CMD_MEM_READ);
    send_uart_byte(X"00"); -- Adresse MSB
    send_uart_byte(X"00"); -- Adresse LSB
    wait for 100 us; -- Attente timeout
    assert mem_valid = '0' report "Erreur: mem_valid toujours actif après timeout" severity error;
    mem_ready <= '1';
    
    -- Test 7: Accès simultanés registres/mémoire
    report "Test 7: Accès simultanés registres/mémoire";
    -- Écriture registre pendant accès mémoire
    mem_ready <= '0';
    send_uart_byte(CMD_MEM_READ);
    send_uart_byte(X"AB"); -- Adresse MSB
    send_uart_byte(X"CD"); -- Adresse LSB
    wait for 1 us;
    send_uart_byte(CMD_REG_WRITE);
    send_uart_byte(X"03"); -- Adresse registre
    send_uart_byte(X"55"); -- Données
    wait for 2 us;
    assert reg_we = '1' report "Erreur: reg_we non activé pendant accès mémoire" severity error;
    assert reg_addr = X"3" report "Erreur: mauvaise adresse registre pendant accès mémoire" severity error;
    assert reg_wdata = "1" & X"55" report "Erreur: mauvaises données registre pendant accès mémoire" severity error;
    mem_ready <= '1';
    wait for 1 us;
    
    -- Test 8: Timeout UART
    report "Test 8: Timeout UART";
    -- Envoi partiel de commande
    send_uart_byte(CMD_MEM_WRITE);
    send_uart_byte(X"12"); -- Adresse MSB seulement
    wait for 200 us; -- Attente timeout UART
    -- Vérifie que le système est revenu à l'état initial
    assert mem_valid = '0' report "Erreur: mem_valid actif après timeout UART" severity error;
    assert mem_we = '0' report "Erreur: mem_we actif après timeout UART" severity error;
    
    -- Test 9: Performance interruption
    report "Test 9: Performance interruption";
    -- Mesure temps de réponse halt
    send_uart_byte(CMD_HALT);
    wait for 100 ns;
    assert cpu_halt_req = '1' report "Erreur: cpu_halt_req non activé rapidement" severity error;
    cpu_halted <= '1';
    wait for 100 ns;
    assert cpu_halt_req = '0' report "Erreur: cpu_halt_req non désactivé rapidement" severity error;
    
    -- Fin des tests
    report "Tests terminés avec succès";
    wait;
  end process;

end architecture sim;