library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le module de réception UART
entity tb_uart_rx is
    -- Pas de ports pour un testbench
end entity tb_uart_rx;

architecture sim of tb_uart_rx is
    -- Constantes
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz
    constant BAUD_RATE  : integer := 115200;
    constant BIT_PERIOD : time := (1000000000 / BAUD_RATE) * 1 ns;  -- Période d'un bit en ns
    
    -- Signaux pour le DUT (Device Under Test)
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal rx_serial   : std_logic := '1';  -- Ligne au repos à '1'
    signal rx_data     : std_logic_vector(7 downto 0);
    signal rx_valid    : std_logic;
    signal rx_error    : std_logic;
    
    -- Signaux pour la vérification
    signal test_data   : std_logic_vector(7 downto 0) := X"42";  -- 'B' en ASCII
    signal test_phase  : integer := 0;
    signal test_done   : boolean := false;
    
    -- Procédure pour envoyer un octet sur la ligne série
    procedure send_byte(byte_to_send : in std_logic_vector(7 downto 0)) is
    begin
        -- Bit de start (toujours 0)
        rx_serial <= '0';
        wait for BIT_PERIOD;
        
        -- Bits de données (LSB first)
        for i in 0 to 7 loop
            rx_serial <= byte_to_send(i);
            wait for BIT_PERIOD;
        end loop;
        
        -- Bit de stop (toujours 1)
        rx_serial <= '1';
        wait for BIT_PERIOD;
    end procedure;
    
begin
    -- Instanciation du DUT
    dut : entity work.uart_rx
        generic map (
            CLK_FREQ => 25000000,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            rx_serial => rx_serial,
            rx_data => rx_data,
            rx_valid => rx_valid,
            rx_error => rx_error
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
        
        -- Test 1: Réception d'un caractère valide
        test_phase <= 1;
        report "Test 1: Réception d'un caractère valide";
        
        -- Envoi du caractère de test
        send_byte(test_data);
        
        -- Attente que la réception soit terminée
        wait until rx_valid = '1' for BIT_PERIOD * 12;  -- Timeout après 12 périodes de bit
        
        -- Vérification des données reçues
        assert rx_valid = '1'
            report "Erreur: rx_valid devrait être à '1' après la réception"
            severity error;
            
        assert rx_data = test_data
            report "Erreur: Les données reçues ne correspondent pas au caractère envoyé"
            severity error;
            
        assert rx_error = '0'
            report "Erreur: rx_error devrait être à '0' pour une réception valide"
            severity error;
            
        wait for CLK_PERIOD * 10;
        
        -- Test 2: Réception avec erreur de framing (bit de stop invalide)
        test_phase <= 2;
        report "Test 2: Réception avec erreur de framing (bit de stop invalide)";
        
        -- Bit de start
        rx_serial <= '0';
        wait for BIT_PERIOD;
        
        -- Bits de données
        for i in 0 to 7 loop
            rx_serial <= test_data(i);
            wait for BIT_PERIOD;
        end loop;
        
        -- Bit de stop invalide (0 au lieu de 1)
        rx_serial <= '0';
        wait for BIT_PERIOD;
        
        -- Retour à l'état de repos
        rx_serial <= '1';
        
        -- Attente que l'erreur soit détectée
        wait until rx_error = '1' for BIT_PERIOD * 12;  -- Timeout après 12 périodes de bit
        
        -- Vérification de l'erreur
        assert rx_error = '1'
            report "Erreur: rx_error devrait être à '1' pour une erreur de framing"
            severity error;
            
        wait for CLK_PERIOD * 10;
        
        -- Test 3: Réception de plusieurs caractères consécutifs
        test_phase <= 3;
        report "Test 3: Réception de plusieurs caractères consécutifs";
        
        -- Envoi de 3 caractères consécutifs
        send_byte(X"48");  -- 'H' en ASCII
        wait for CLK_PERIOD * 10;
        
        send_byte(X"69");  -- 'i' en ASCII
        wait for CLK_PERIOD * 10;
        
        send_byte(X"21");  -- '!' en ASCII
        wait for CLK_PERIOD * 10;
        
        -- Fin du test
        test_phase <= 4;
        report "Tests terminés";
        test_done <= true;
        wait;
    end process;
    
end architecture sim;