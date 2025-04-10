library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Testbench pour le contrôleur UART avec interface MMIO
entity tb_uart_controller_mmio is
    -- Pas de ports pour un testbench
end entity tb_uart_controller_mmio;

architecture sim of tb_uart_controller_mmio is
    -- Constantes
    constant CLK_PERIOD : time := 40 ns;  -- 25 MHz
    constant BAUD_RATE  : integer := 115200;
    
    -- Signaux pour le DUT (Device Under Test)
    signal clk             : std_logic := '0';
    signal rst             : std_logic := '1';
    signal addr            : EncodedAddress := (others => '0');
    signal data_in         : EncodedWord := (others => '0');
    signal data_out        : EncodedWord := (others => '0');
    signal read_en         : std_logic := '0';
    signal write_en        : std_logic := '0';
    signal uart_tx_serial  : std_logic;
    signal uart_rx_serial  : std_logic := '1';  -- Ligne au repos à '1'
    
    -- Signaux pour la vérification
    signal tx_data_byte    : std_logic_vector(7 downto 0) := X"41";  -- 'A' en ASCII
    signal rx_data_byte    : std_logic_vector(7 downto 0) := X"00";
    signal test_phase      : integer := 0;
    signal test_done       : boolean := false;
    
    -- Fonction pour convertir un octet binaire en tryte ternaire
    function binary_to_ternary(bin : std_logic_vector(7 downto 0)) return EncodedTryte is
        variable result : EncodedTryte := (others => '0');
    begin
        -- Conversion simple: chaque groupe de 3 bits devient un trit
        -- Premier trit (bits 7-6-5)
        if bin(7) = '1' then
            result(5 downto 4) := TRIT_P;  -- Positif
        elsif bin(6) = '1' then
            result(5 downto 4) := TRIT_Z;  -- Zéro
        else
            result(5 downto 4) := TRIT_N;  -- Négatif
        end if;
        
        -- Deuxième trit (bits 4-3-2)
        if bin(4) = '1' then
            result(3 downto 2) := TRIT_P;  -- Positif
        elsif bin(3) = '1' then
            result(3 downto 2) := TRIT_Z;  -- Zéro
        else
            result(3 downto 2) := TRIT_N;  -- Négatif
        end if;
        
        -- Troisième trit (bits 1-0 + padding)
        if bin(1) = '1' then
            result(1 downto 0) := TRIT_P;  -- Positif
        elsif bin(0) = '1' then
            result(1 downto 0) := TRIT_Z;  -- Zéro
        else
            result(1 downto 0) := TRIT_N;  -- Négatif
        end if;
        
        return result;
    end function;
    
    -- Fonction pour convertir un tryte ternaire en octet binaire
    function ternary_to_binary(tern : EncodedTryte) return std_logic_vector is
        variable result : std_logic_vector(7 downto 0) := (others => '0');
    begin
        -- Conversion simple: chaque trit devient un groupe de bits
        -- Premier trit -> bits 7-6-5
        case tern(5 downto 4) is
            when TRIT_P => result(7) := '1';
            when TRIT_Z => result(6) := '1';
            when TRIT_N => result(5) := '1';
            when others => null;
        end case;
        
        -- Deuxième trit -> bits 4-3-2
        case tern(3 downto 2) is
            when TRIT_P => result(4) := '1';
            when TRIT_Z => result(3) := '1';
            when TRIT_N => result(2) := '1';
            when others => null;
        end case;
        
        -- Troisième trit -> bits 1-0
        case tern(1 downto 0) is
            when TRIT_P => result(1) := '1';
            when TRIT_Z => result(0) := '1';
            when TRIT_N => -- Pas de bit à mettre à 1
            when others => null;
        end case;
        
        return result;
    end function;
    
begin
    -- Instanciation du DUT
    dut : entity work.uart_controller
        generic map (
            CLK_FREQ => 25000000,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            addr => addr,
            data_in => data_in,
            data_out => data_out,
            read_en => read_en,
            write_en => write_en,
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
    
    -- Processus de test
    process
    begin
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 5;
        rst <= '0';
        wait for CLK_PERIOD * 5;
        
        -- Test 1: Écriture dans le registre TX_DATA
        test_phase <= 1;
        report "Test 1: Écriture dans le registre TX_DATA";
        
        -- Préparation des données à écrire
        addr <= UART_TX_DATA_OFFSET;
        data_in(5 downto 0) <= binary_to_ternary(tx_data_byte);
        write_en <= '1';
        wait for CLK_PERIOD;
        write_en <= '0';
        
        -- Attente que la transmission soit terminée
        wait for CLK_PERIOD * 1000;  -- Temps suffisant pour la transmission à 115200 bauds
        
        -- Test 2: Lecture du registre STATUS
        test_phase <= 2;
        report "Test 2: Lecture du registre STATUS";
        
        addr <= UART_STATUS_OFFSET;
        read_en <= '1';
        wait for CLK_PERIOD;
        read_en <= '0';
        
        -- Vérification que TX_READY est à '1' (transmission terminée)
        assert ternary_to_binary(data_out(5 downto 0))(0) = '1'
            report "Erreur: TX_READY devrait être à '1' après la transmission"
            severity error;
        
        -- Test 3: Simulation d'une réception UART
        test_phase <= 3;
        report "Test 3: Simulation d'une réception UART";
        
        -- Simulation d'une réception bit par bit
        -- Préparation du caractère à recevoir (B = 0x42 en ASCII)
        rx_data_byte <= X"42";
        
        -- Bit de start (toujours 0)
        uart_rx_serial <= '0';
        wait for CLK_PERIOD * (CLK_FREQ / BAUD_RATE);
        
        -- Bits de données (LSB first)
        for i in 0 to 7 loop
            uart_rx_serial <= rx_data_byte(i);
            wait for CLK_PERIOD * (CLK_FREQ / BAUD_RATE);
        end loop;
        
        -- Bit de stop (toujours 1)
        uart_rx_serial <= '1';
        wait for CLK_PERIOD * (CLK_FREQ / BAUD_RATE);
        
        -- Attente supplémentaire pour s'assurer que la réception est terminée
        wait for CLK_PERIOD * 10;
        
        -- Test 4: Vérification du registre STATUS puis lecture du registre RX_DATA
        test_phase <= 4;
        report "Test 4: Vérification du registre STATUS puis lecture du registre RX_DATA";
        
        -- Vérification que le bit RX_READY est à '1' dans le registre STATUS
        addr <= UART_STATUS_OFFSET;
        read_en <= '1';
        wait for CLK_PERIOD;
        read_en <= '0';
        
        -- Vérification que RX_READY est à '1' (données disponibles)
        assert ternary_to_binary(data_out(5 downto 0))(2) = '1'
            report "Erreur: RX_READY devrait être à '1' après la réception"
            severity error;
        
        -- Lecture du registre RX_DATA
        addr <= UART_RX_DATA_OFFSET;
        read_en <= '1';
        wait for CLK_PERIOD;
        read_en <= '0';
        
        -- Vérification que les données reçues sont correctes (B = 0x42)
        assert ternary_to_binary(data_out(5 downto 0)) = X"42"
            report "Erreur: Les données reçues ne correspondent pas au caractère envoyé"
            severity error;
        
        -- Fin du test
        test_phase <= 5;
        report "Tests terminés";
        test_done <= true;
        wait;
    end process;
    
end architecture sim;