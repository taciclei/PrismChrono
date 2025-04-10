library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le système complet PrismChrono avec cache L1 et mémoire externe DDR
entity tb_prismchrono_top_ddr is
    -- Pas de ports pour un testbench
end entity tb_prismchrono_top_ddr;

architecture sim of tb_prismchrono_top_ddr is
    -- Constantes pour le testbench
    constant CLK_PERIOD : time := 10 ns;
    
    -- Signaux pour le DUT (Device Under Test)
    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '1';  -- Reset actif bas
    signal rst          : std_logic := '0';  -- Reset actif haut (inversion de rst_n)
    
    -- Signaux UART
    signal uart_tx_pin  : std_logic;
    signal uart_rx_pin  : std_logic := '1';  -- Ligne idle à '1'
    
    -- Signaux pour les LEDs et boutons
    signal leds         : std_logic_vector(7 downto 0);
    signal buttons      : std_logic_vector(3 downto 0) := (others => '0');
    
    -- Signaux pour la simulation de la mémoire DDR externe
    signal ddr_cmd_valid   : std_logic;
    signal ddr_cmd_ready   : std_logic := '1';  -- Toujours prêt pour simplifier
    signal ddr_cmd_we      : std_logic;
    signal ddr_cmd_addr    : std_logic_vector(27 downto 0);
    
    signal ddr_wdata_valid : std_logic;
    signal ddr_wdata_ready : std_logic := '1';  -- Toujours prêt pour simplifier
    signal ddr_wdata       : std_logic_vector(63 downto 0);
    signal ddr_wdata_mask  : std_logic_vector(7 downto 0);
    
    signal ddr_rdata_valid : std_logic := '0';
    signal ddr_rdata_ready : std_logic;
    signal ddr_rdata       : std_logic_vector(63 downto 0) := (others => '0');
    
    -- Mémoire DDR simulée
    type DdrMemoryType is array(0 to 1023) of std_logic_vector(63 downto 0);
    signal ddr_memory   : DdrMemoryType := (others => (others => '0'));
    signal ddr_latency_counter : integer := 0;
    constant DDR_LATENCY : integer := 10;  -- Latence simulée de la mémoire DDR (cycles)
    
    -- Composant top-level à tester
    component prismchrono_top is
        port (
            clk          : in  std_logic;
            rst_n        : in  std_logic;
            uart_tx_pin  : out std_logic;
            uart_rx_pin  : in  std_logic;
            leds         : out std_logic_vector(7 downto 0);
            buttons      : in  std_logic_vector(3 downto 0);
            -- Interface DDR (ajoutée pour le sprint 8)
            ddr_cmd_valid   : out std_logic;
            ddr_cmd_ready   : in  std_logic;
            ddr_cmd_we      : out std_logic;
            ddr_cmd_addr    : out std_logic_vector(27 downto 0);
            ddr_wdata_valid : out std_logic;
            ddr_wdata_ready : in  std_logic;
            ddr_wdata       : out std_logic_vector(63 downto 0);
            ddr_wdata_mask  : out std_logic_vector(7 downto 0);
            ddr_rdata_valid : in  std_logic;
            ddr_rdata_ready : out std_logic;
            ddr_rdata       : in  std_logic_vector(63 downto 0)
        );
    end component;
    
    -- Signaux pour le monitoring des performances
    signal cycle_counter : integer := 0;
    signal cache_hits    : integer := 0;
    signal cache_misses  : integer := 0;
    signal ddr_accesses  : integer := 0;
    
begin
    -- Inversion du reset
    rst <= not rst_n;
    
    -- Instanciation du DUT
    dut: prismchrono_top
        port map (
            clk          => clk,
            rst_n        => rst_n,
            uart_tx_pin  => uart_tx_pin,
            uart_rx_pin  => uart_rx_pin,
            leds         => leds,
            buttons      => buttons,
            -- Interface DDR
            ddr_cmd_valid   => ddr_cmd_valid,
            ddr_cmd_ready   => ddr_cmd_ready,
            ddr_cmd_we      => ddr_cmd_we,
            ddr_cmd_addr    => ddr_cmd_addr,
            ddr_wdata_valid => ddr_wdata_valid,
            ddr_wdata_ready => ddr_wdata_ready,
            ddr_wdata       => ddr_wdata,
            ddr_wdata_mask  => ddr_wdata_mask,
            ddr_rdata_valid => ddr_rdata_valid,
            ddr_rdata_ready => ddr_rdata_ready,
            ddr_rdata       => ddr_rdata
        );
    
    -- Génération de l'horloge
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Compteur de cycles
    process(clk)
    begin
        if rising_edge(clk) then
            cycle_counter <= cycle_counter + 1;
        end if;
    end process;
    
    -- Simulation de la mémoire DDR externe avec latence
    process(clk)
        variable addr_index : integer;
    begin
        if rising_edge(clk) then
            -- Par défaut, données non valides
            ddr_rdata_valid <= '0';
            
            -- Si commande valide
            if ddr_cmd_valid = '1' and ddr_cmd_ready = '1' then
                -- Incrémenter le compteur d'accès DDR
                ddr_accesses <= ddr_accesses + 1;
                
                -- Calculer l'index dans la mémoire simulée (simplification)
                addr_index := to_integer(unsigned(ddr_cmd_addr(9 downto 0)));
                
                -- Si c'est une écriture
                if ddr_cmd_we = '1' then
                    -- Attendre que les données soient valides
                    if ddr_wdata_valid = '1' and ddr_wdata_ready = '1' then
                        -- Écrire les données dans la mémoire simulée
                        ddr_memory(addr_index) <= ddr_wdata;
                    end if;
                -- Si c'est une lecture
                else
                    -- Démarrer le compteur de latence
                    ddr_latency_counter <= DDR_LATENCY;
                end if;
            end if;
            
            -- Gestion de la latence pour les lectures
            if ddr_latency_counter > 0 then
                ddr_latency_counter <= ddr_latency_counter - 1;
                
                -- Fin de la latence, données prêtes
                if ddr_latency_counter = 1 then
                    -- Calculer l'index dans la mémoire simulée (simplification)
                    addr_index := to_integer(unsigned(ddr_cmd_addr(9 downto 0)));
                    
                    -- Envoyer les données lues
                    ddr_rdata <= ddr_memory(addr_index);
                    ddr_rdata_valid <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- Processus de test
    process
        -- Procédure pour initialiser la mémoire DDR simulée
        procedure init_ddr_memory is
        begin
            -- Initialiser quelques valeurs dans la mémoire DDR
            ddr_memory(0) <= X"0123456789ABCDEF";
            ddr_memory(1) <= X"FEDCBA9876543210";
            ddr_memory(2) <= X"AABBCCDDEEFF0011";
            ddr_memory(3) <= X"1100FFEEDDCCBBAA";
            
            -- Initialiser un programme de test dans la mémoire DDR
            -- (adresses plus élevées que la BRAM)
            ddr_memory(256) <= X"0000000000000001";  -- Instruction simple (ex: NOP)
            ddr_memory(257) <= X"0000000000000002";  -- Instruction simple (ex: ADDI)
            ddr_memory(258) <= X"0000000000000003";  -- Instruction simple (ex: LOAD)
            ddr_memory(259) <= X"0000000000000004";  -- Instruction simple (ex: STORE)
            ddr_memory(260) <= X"0000000000000005";  -- Instruction simple (ex: JUMP)
        end procedure;
        
        -- Procédure pour envoyer une commande UART
        procedure send_uart_command(cmd : in std_logic_vector(7 downto 0)) is
            constant BIT_PERIOD : time := 8680 ns;  -- Pour 115200 bauds
        begin
            -- Start bit
            uart_rx_pin <= '0';
            wait for BIT_PERIOD;
            
            -- Data bits (LSB first)
            for i in 0 to 7 loop
                uart_rx_pin <= cmd(i);
                wait for BIT_PERIOD;
            end loop;
            
            -- Stop bit
            uart_rx_pin <= '1';
            wait for BIT_PERIOD;
        end procedure;
        
    begin
        -- Initialisation de la mémoire DDR
        init_ddr_memory;
        
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 5;
        rst_n <= '1';
        wait for CLK_PERIOD * 10;
        
        -- Attendre que le système soit prêt
        wait for 1 ms;
        
        report "Début du test du système complet avec cache L1 et mémoire DDR";
        
        -- Envoyer des commandes UART pour charger et exécuter un programme
        -- qui accède à la mémoire DDR externe
        
        -- Commande pour charger un programme dans la mémoire
        send_uart_command(X"01");  -- Commande hypothétique de chargement
        wait for 1 ms;
        
        -- Commande pour exécuter le programme
        send_uart_command(X"02");  -- Commande hypothétique d'exécution
        wait for 10 ms;
        
        -- Attendre la fin de l'exécution
        wait for 50 ms;
        
        -- Afficher les statistiques
        report "Test terminé. Statistiques: " & 
               integer'image(cycle_counter) & " cycles, " & 
               integer'image(ddr_accesses) & " accès DDR.";
        
        -- Fin de la simulation
        wait;
    end process;
    
end architecture sim;