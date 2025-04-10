library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le module de transmission UART
entity tb_uart_tx is
    -- Pas de ports pour un testbench
end entity tb_uart_tx;

architecture sim of tb_uart_tx is
    -- Constantes
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz
    constant BAUD_RATE  : integer := 115200;
    constant BIT_PERIOD : time := (1000000000 / BAUD_RATE) * 1 ns;  -- Période d'un bit en ns
    
    -- Signaux pour le DUT (Device Under Test)
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal tx_data     : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_start    : std_logic := '0';
    signal tx_busy     : std_logic;
    signal tx_done     : std_logic;
    signal tx_serial   : std_logic;
    
    -- Signaux pour la vérification
    signal test_data   : std_logic_vector(7 downto 0) := X"41";  -- 'A' en ASCII
    signal received_data : std_logic_vector(7 downto 0) := (others => '0');
    signal test_phase  : integer := 0;
    signal test_done   : boolean := false;
    
    -- Procédure pour recevoir un octet depuis la ligne série
    procedure receive_byte(signal serial_in : in std_logic; signal byte_out : out std_logic_vector(7 downto 0)) is
        variable temp_byte : std_logic_vector(7 downto 0) := (others => '0');
    begin
        -- Attente du bit de start (transition de 1 à 0)
        wait until serial_in = '0';
        
        -- Attente de la moitié de la période de bit pour échantillonner au milieu
        wait for BIT_PERIOD / 2;
        
        -- Vérification que c'est bien un bit de start
        assert serial_in = '0'
            report "Erreur: Bit de start invalide"
            severity error;
            
        -- Attente de la fin du bit de start
        wait for BIT_PERIOD / 2;
        
        -- Réception des 8 bits de données (LSB first)
        for i in 0 to 7 loop
            -- Attente de la moitié de la période de bit
            wait for BIT_PERIOD / 2;
            
            -- Échantillonnage du bit
            temp_byte(i) := serial_in;
            
            -- Attente de la fin du bit
            wait for BIT_PERIOD / 2;
        end loop;
        
        -- Vérification du bit de stop
        wait for BIT_PERIOD / 2;
        assert serial_in = '1'
            report "Erreur: Bit de stop invalide"
            severity error;
            
        -- Assignation du résultat
        byte_out <= temp_byte;
    end procedure;
    
begin
    -- Instanciation du DUT
    dut : entity work.uart_tx
        generic map (
            CLK_FREQ => 25000000,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            tx_data => tx_data,
            tx_start => tx_start,
            tx_busy => tx_busy,
            tx_done => tx_done,
            tx_serial => tx_serial
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
    
    -- Processus de test
    process
    begin
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 5;
        rst <= '0';
        wait for CLK_PERIOD * 5;
        
        -- Test 1: Transmission d'un caractère
        test_phase <= 1;
        report "Test 1: Transmission d'un caractère";
        
        -- Préparation des données à transmettre
        tx_data <= test_data;
        
        -- Démarrage de la transmission
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Vérification que tx_busy passe à '1'
        assert tx_busy = '1'
            report "Erreur: tx_busy devrait être à '1' pendant la transmission"
            severity error;
            
        -- Réception du caractère transmis
        receive_byte(tx_serial, received_data);
        
        -- Attente que la transmission soit terminée
        wait until tx_done = '1' for BIT_PERIOD * 12;  -- Timeout après 12 périodes de bit
        
        -- Vérification que tx_done passe à '1'
        assert tx_done = '1'
            report "Erreur: tx_done devrait être à '1' après la transmission"
            severity error;
            
        -- Vérification que tx_busy revient à '0'
        assert tx_busy = '0'
            report "Erreur: tx_busy devrait revenir à '0' après la transmission"
            severity error;
            
        -- Vérification des données reçues
        assert received_data = test_data
            report "Erreur: Les données reçues ne correspondent pas au caractère envoyé"
            severity error;
            
        wait for CLK_PERIOD * 10;
        
        -- Test 2: Transmission de plusieurs caractères consécutifs
        test_phase <= 2;
        report "Test 2: Transmission de plusieurs caractères consécutifs";
        
        -- Premier caractère: 'H' (0x48)
        tx_data <= X"48";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Attente que la transmission soit terminée
        wait until tx_done = '1';
        wait for CLK_PERIOD * 2;
        
        -- Deuxième caractère: 'i' (0x69)
        tx_data <= X"69";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Attente que la transmission soit terminée
        wait until tx_done = '1';
        wait for CLK_PERIOD * 2;
        
        -- Troisième caractère: '!' (0x21)
        tx_data <= X"21";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        -- Attente que la transmission soit terminée
        wait until tx_done = '1';
        wait for CLK_PERIOD * 10;
        
        -- Fin du test
        test_phase <= 3;
        report "Tests terminés";
        test_done <= true;
        wait;
    end process;
    
end architecture sim;