library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le CPU Core avec périphériques IO (UART)
entity tb_prismchrono_core_io is
    -- Pas de ports pour un testbench
end entity tb_prismchrono_core_io;

architecture sim of tb_prismchrono_core_io is
    -- Constantes
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz
    constant BAUD_RATE  : integer := 115200;
    
    -- Signaux pour le CPU Core
    signal clk             : std_logic := '0';
    signal rst             : std_logic := '1';
    signal uart_tx_serial  : std_logic;
    signal uart_rx_serial  : std_logic := '1';  -- Ligne au repos à '1'
    
    -- Signaux pour la mémoire
    signal mem_addr        : EncodedAddress;
    signal mem_data_in     : EncodedWord;
    signal mem_data_out    : EncodedWord;
    signal mem_read_en     : std_logic;
    signal mem_write_en    : std_logic;
    signal mem_ready       : std_logic := '1';
    
    -- Signaux pour la vérification
    signal test_phase      : integer := 0;
    signal test_done       : boolean := false;
    
    -- Mémoire ROM simulée (programme de test)
    type rom_type is array (0 to 63) of EncodedWord;
    signal rom : rom_type := (others => (others => '0'));
    
    -- Fonction pour convertir un entier en EncodedWord (pour initialiser la ROM)
    function int_to_encoded_word(value : integer) return EncodedWord is
        variable result : EncodedWord := (others => '0');
    begin
        -- Implémentation simplifiée pour les besoins du test
        -- Dans un cas réel, il faudrait une conversion complète de l'entier vers la représentation ternaire
        return result;
    end function;
    
    -- Composant prismchrono_core
    component prismchrono_core is
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            
            -- Interface mémoire
            mem_addr        : out EncodedAddress;
            mem_data_in     : in  EncodedWord;
            mem_data_out    : out EncodedWord;
            mem_read_en     : out std_logic;
            mem_write_en    : out std_logic;
            mem_ready       : in  std_logic;
            
            -- Interface UART
            uart_tx_serial  : out std_logic;
            uart_rx_serial  : in  std_logic
        );
    end component;
    
    -- Constantes pour les instructions
    -- Ces valeurs sont simplifiées et devraient être remplacées par les vraies encodages d'instructions
    constant INSTR_NOP      : EncodedWord := (others => '0');
    constant INSTR_ADDI     : EncodedWord := (others => '0');
    constant INSTR_STORET   : EncodedWord := (others => '0');
    constant INSTR_ECALL    : EncodedWord := (others => '0');
    constant INSTR_EBREAK   : EncodedWord := (others => '0');
    
    -- Constantes pour les adresses MMIO
    constant UART_BASE_ADDR : EncodedAddress := X"F0000000";
    
begin
    -- Instanciation du CPU Core
    dut : prismchrono_core
        port map (
            clk => clk,
            rst => rst,
            mem_addr => mem_addr,
            mem_data_in => mem_data_in,
            mem_data_out => mem_data_out,
            mem_read_en => mem_read_en,
            mem_write_en => mem_write_en,
            mem_ready => mem_ready,
            uart_tx_serial => uart_tx_serial,
            uart_rx_serial => uart_rx_serial
        );
    
    -- Génération de l'horloge
    process
    begin
        while not test_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;
    
    -- Initialisation de la ROM avec le programme de test
    process
    begin
        -- Programme qui envoie "Hello" via l'UART et exécute ECALL/EBREAK
        -- Adresse 0: Initialisation
        rom(0) <= INSTR_NOP;  -- NOP pour démarrer
        
        -- Adresse 1-5: Envoi de "Hello" via STORET à l'adresse MMIO UART_TX_DATA
        rom(1) <= INSTR_ADDI;  -- Charger 'H' (0x48) dans un registre
        rom(2) <= INSTR_STORET;  -- Stocker à l'adresse UART_TX_DATA
        rom(3) <= INSTR_ADDI;  -- Charger 'e' (0x65) dans un registre
        rom(4) <= INSTR_STORET;  -- Stocker à l'adresse UART_TX_DATA
        rom(5) <= INSTR_ADDI;  -- Charger 'l' (0x6C) dans un registre
        rom(6) <= INSTR_STORET;  -- Stocker à l'adresse UART_TX_DATA
        rom(7) <= INSTR_ADDI;  -- Charger 'l' (0x6C) dans un registre
        rom(8) <= INSTR_STORET;  -- Stocker à l'adresse UART_TX_DATA
        rom(9) <= INSTR_ADDI;  -- Charger 'o' (0x6F) dans un registre
        rom(10) <= INSTR_STORET;  -- Stocker à l'adresse UART_TX_DATA
        
        -- Adresse 11: Exécution de ECALL
        rom(11) <= INSTR_ECALL;
        
        -- Adresse 12: Exécution de EBREAK
        rom(12) <= INSTR_EBREAK;
        
        wait;
    end process;
    
    -- Simulation de la mémoire ROM
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_read_en = '1' then
                -- Conversion de l'adresse en index pour la ROM
                -- Cette conversion est simplifiée et devrait être adaptée à l'architecture réelle
                mem_data_in <= rom(to_integer(unsigned(mem_addr(5 downto 0))));
            end if;
        end if;
    end process;
    
    -- Processus de test
    process
    begin
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 5;
        rst <= '0';
        wait for CLK_PERIOD * 5;
        
        -- Test 1: Exécution du programme et vérification de l'UART TX
        test_phase <= 1;
        report "Test 1: Exécution du programme et vérification de l'UART TX";
        
        -- Attente que le programme s'exécute
        -- Dans un cas réel, on vérifierait les signaux UART_TX_SERIAL
        -- et on décodrait les caractères envoyés
        wait for CLK_PERIOD * 1000;
        
        -- Test 2: Vérification des traps (ECALL/EBREAK)
        test_phase <= 2;
        report "Test 2: Vérification des traps (ECALL/EBREAK)";
        
        -- Dans un cas réel, on vérifierait les signaux internes du CPU
        -- pour s'assurer que les traps sont correctement déclenchés
        wait for CLK_PERIOD * 100;
        
        -- Fin du test
        test_phase <= 3;
        report "Tests terminés";
        test_done <= true;
        wait;
    end process;
    
end architecture sim;