library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;

entity tb_debug_module_advanced is
end entity tb_debug_module_advanced;

architecture sim of tb_debug_module_advanced is
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    constant NUM_BREAKPOINTS : positive := 4;
    
    -- Signaux de test
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal uart_rx : std_logic := '1';
    signal uart_tx : std_logic;
    
    -- Signaux CPU
    signal cpu_pc : std_logic_vector(17 downto 0) := (others => '0');
    signal cpu_halt_req : std_logic;
    signal cpu_halted : std_logic := '0';
    signal cpu_resume : std_logic;
    signal cpu_step : std_logic;
    
    -- Signaux registres
    signal reg_addr : std_logic_vector(3 downto 0);
    signal reg_wdata : std_logic_vector(8 downto 0);
    signal reg_rdata : std_logic_vector(8 downto 0) := (others => '0');
    signal reg_we : std_logic;
    
    -- Signaux mémoire
    signal mem_addr : std_logic_vector(17 downto 0);
    signal mem_wdata : std_logic_vector(8 downto 0);
    signal mem_rdata : std_logic_vector(8 downto 0) := (others => '0');
    signal mem_we : std_logic;
    signal mem_valid : std_logic;
    signal mem_ready : std_logic := '0';
    
    -- Procédure pour envoyer un octet via UART
    procedure uart_send_byte(byte : in std_logic_vector(7 downto 0)) is
    begin
        uart_rx <= '0';  -- Start bit
        wait for 8680 ns;  -- 115200 baud
        
        for i in 0 to 7 loop
            uart_rx <= byte(i);
            wait for 8680 ns;
        end loop;
        
        uart_rx <= '1';  -- Stop bit
        wait for 8680 ns;
    end procedure;
    
    -- Procédure pour envoyer une commande complète
    procedure send_command(cmd : in string; data : in std_logic_vector) is
    begin
        -- Envoie la commande
        for i in 1 to cmd'length loop
            uart_send_byte(std_logic_vector(to_unsigned(character'pos(cmd(i)), 8)));
        end loop;
        
        -- Envoie les données en hexadécimal
        for i in (data'length/4)-1 downto 0 loop
            case data((i+1)*4-1 downto i*4) is
                when "0000" => uart_send_byte(x"30");  -- '0'
                when "0001" => uart_send_byte(x"31");  -- '1'
                when "0010" => uart_send_byte(x"32");  -- '2'
                when "0011" => uart_send_byte(x"33");  -- '3'
                when "0100" => uart_send_byte(x"34");  -- '4'
                when "0101" => uart_send_byte(x"35");  -- '5'
                when "0110" => uart_send_byte(x"36");  -- '6'
                when "0111" => uart_send_byte(x"37");  -- '7'
                when "1000" => uart_send_byte(x"38");  -- '8'
                when "1001" => uart_send_byte(x"39");  -- '9'
                when "1010" => uart_send_byte(x"41");  -- 'A'
                when "1011" => uart_send_byte(x"42");  -- 'B'
                when "1100" => uart_send_byte(x"43");  -- 'C'
                when "1101" => uart_send_byte(x"44");  -- 'D'
                when "1110" => uart_send_byte(x"45");  -- 'E'
                when "1111" => uart_send_byte(x"46");  -- 'F'
                when others => null;
            end case;
        end loop;
        
        -- Termine la commande
        uart_send_byte(x"0D");  -- CR
        uart_send_byte(x"0A");  -- LF
    end procedure;
    
begin
    -- Instanciation du module de débogage
    uut: entity work.debug_module
        generic map (
            NUM_BREAKPOINTS => NUM_BREAKPOINTS
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            uart_rx => uart_rx,
            uart_tx => uart_tx,
            cpu_pc => cpu_pc,
            cpu_halt_req => cpu_halt_req,
            cpu_halted => cpu_halted,
            cpu_resume => cpu_resume,
            cpu_step => cpu_step,
            reg_addr => reg_addr,
            reg_wdata => reg_wdata,
            reg_rdata => reg_rdata,
            reg_we => reg_we,
            mem_addr => mem_addr,
            mem_wdata => mem_wdata,
            mem_rdata => mem_rdata,
            mem_we => mem_we,
            mem_valid => mem_valid,
            mem_ready => mem_ready
        );
    
    -- Génération de l'horloge
    clk <= not clk after CLK_PERIOD/2;
    
    -- Processus de test
    process
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Test 1: Configuration d'un point d'arrêt
        report "Test 1: Configuration d'un point d'arrêt";
        send_command("z", x"1234");  -- Point d'arrêt à l'adresse 0x1234
        wait for CLK_PERIOD * 10;
        
        -- Test 2: Déclenchement du point d'arrêt
        report "Test 2: Déclenchement du point d'arrêt";
        cpu_pc <= x"1234";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Le point d'arrêt n'a pas déclenché cpu_halt_req"
            severity error;
        
        -- Simule l'arrêt du CPU
        cpu_halted <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Test 3: Lecture mémoire
        report "Test 3: Lecture mémoire";
        send_command("m", x"2000");  -- Lecture à l'adresse 0x2000
        wait for CLK_PERIOD * 2;
        assert mem_valid = '1' and mem_we = '0'
            report "Erreur: Commande de lecture mémoire incorrecte"
            severity error;
        
        -- Simule la réponse mémoire
        mem_rdata <= "100110010";  -- Valeur de test
        mem_ready <= '1';
        wait for CLK_PERIOD;
        mem_ready <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test 4: Écriture mémoire
        report "Test 4: Écriture mémoire";
        send_command("M", x"3000AA");  -- Écriture 0xAA à l'adresse 0x3000
        wait for CLK_PERIOD * 2;
        assert mem_valid = '1' and mem_we = '1'
            report "Erreur: Commande d'écriture mémoire incorrecte"
            severity error;
        
        -- Simule l'acquittement mémoire
        mem_ready <= '1';
        wait for CLK_PERIOD;
        mem_ready <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test 5: Suppression du point d'arrêt
        report "Test 5: Suppression du point d'arrêt";
        send_command("Z", x"1234");
        wait for CLK_PERIOD * 10;
        
        -- Vérifie que le point d'arrêt est désactivé
        cpu_pc <= x"1234";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '0'
            report "Erreur: Le point d'arrêt n'a pas été supprimé"
            severity error;
        
        -- Test 6: Reprise de l'exécution
        report "Test 6: Reprise de l'exécution";
        send_command("c", x"00");
        wait for CLK_PERIOD * 2;
        assert cpu_resume = '1'
            report "Erreur: Signal de reprise non activé"
            severity error;
        
        -- Test 7: Test des accès mémoire concurrents
        report "Test 7: Accès mémoire concurrents";
        
        -- Premier accès mémoire
        send_command("m", x"4000");
        wait for CLK_PERIOD * 2;
        
        -- Deuxième accès mémoire pendant que le premier est en cours
        send_command("m", x"4100");
        wait for CLK_PERIOD * 2;
        
        -- Vérifie que le module gère correctement la concurrence
        assert mem_valid = '1'
            report "Erreur: Premier accès mémoire non valide"
            severity error;
            
        -- Simule une réponse lente de la mémoire
        wait for CLK_PERIOD * 5;
        mem_ready <= '1';
        mem_rdata <= "101010101";
        wait for CLK_PERIOD;
        mem_ready <= '0';
        
        -- Vérifie le traitement du deuxième accès
        wait for CLK_PERIOD * 2;
        assert mem_valid = '1'
            report "Erreur: Deuxième accès mémoire non traité"
            severity error;
            
        -- Test 8: Points d'arrêt multiples et priorités
        report "Test 8: Points d'arrêt multiples";
        
        -- Configure plusieurs points d'arrêt
        send_command("z", x"1000");  -- Premier point d'arrêt
        wait for CLK_PERIOD * 10;
        send_command("z", x"2000");  -- Deuxième point d'arrêt
        wait for CLK_PERIOD * 10;
        
        -- Vérifie le déclenchement du premier point d'arrêt
        cpu_pc <= x"1000";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Premier point d'arrêt multiple non détecté"
            severity error;
            
        -- Simule la reprise et vérifie le deuxième point d'arrêt
        cpu_halted <= '1';
        send_command("c", x"00");  -- Continue
        cpu_halted <= '0';
        wait for CLK_PERIOD * 5;
        
        cpu_pc <= x"2000";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Deuxième point d'arrêt multiple non détecté"
            severity error;
            
        -- Test 9: Lecture registre
        report "Test 7: Lecture registre";
        send_command("r", x"03");  -- Lecture du registre 3
        wait for CLK_PERIOD * 2;
        assert reg_we = '0' and reg_addr = x"3"
            report "Erreur: Commande de lecture registre incorrecte"
            severity error;
            
        -- Simule la valeur du registre
        reg_rdata <= "101010101";
        wait for CLK_PERIOD * 2;
        
        -- Test 8: Écriture registre
        report "Test 8: Écriture registre";
        send_command("R", x"05FF");  -- Écriture 0xFF dans le registre 5
        wait for CLK_PERIOD * 2;
        assert reg_we = '1' and reg_addr = x"5" and reg_wdata = "111111111"
            report "Erreur: Commande d'écriture registre incorrecte"
            severity error;
        wait for CLK_PERIOD * 2;
        
        -- Test 9: Exécution pas à pas
        report "Test 9: Exécution pas à pas";
        send_command("s", x"00");
        wait for CLK_PERIOD * 2;
        assert cpu_step = '1'
            report "Erreur: Signal d'exécution pas à pas non activé"
            severity error;
        wait for CLK_PERIOD * 2;
        
        -- Test 10: Accès mémoire concurrents
        report "Test 10: Test des accès mémoire concurrents";
        
        -- Première lecture mémoire
        send_command("m", x"4000");
        wait for CLK_PERIOD * 2;
        assert mem_valid = '1' and mem_we = '0'
            report "Erreur: Première lecture mémoire invalide"
            severity error;
            
        -- Deuxième lecture mémoire avant la fin de la première
        send_command("m", x"4004");
        wait for CLK_PERIOD * 2;
        
        -- Simule la réponse de la première lecture
        mem_rdata <= "101010101";
        mem_ready <= '1';
        wait for CLK_PERIOD;
        mem_ready <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Vérifie que la deuxième lecture est bien traitée
        assert mem_valid = '1' and mem_we = '0'
            report "Erreur: Deuxième lecture mémoire non traitée"
            severity error;
            
        -- Simule la réponse de la deuxième lecture
        mem_rdata <= "110011001";
        mem_ready <= '1';
        wait for CLK_PERIOD;
        mem_ready <= '0';
        wait for CLK_PERIOD * 2;
        
        -- Test 11: Points d'arrêt multiples et priorité
        report "Test 11: Test des points d'arrêt multiples et priorité";
        
        -- Configure plusieurs points d'arrêt
        send_command("z", x"1000");  -- Premier point d'arrêt
        wait for CLK_PERIOD * 10;
        send_command("z", x"2000");  -- Deuxième point d'arrêt
        wait for CLK_PERIOD * 10;
        send_command("z", x"3000");  -- Troisième point d'arrêt
        wait for CLK_PERIOD * 10;
        
        -- Vérifie la détection simultanée
        cpu_pc <= x"1000";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Premier point d'arrêt non détecté"
            severity error;
            
        -- Simule la reprise après arrêt
        cpu_halted <= '1';
        wait for CLK_PERIOD * 2;
        send_command("c", x"00");
        wait for CLK_PERIOD * 2;
        cpu_halted <= '0';
        
        -- Vérifie le deuxième point d'arrêt
        cpu_pc <= x"2000";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Deuxième point d'arrêt non détecté"
            severity error;
            
        -- Simule la reprise et vérifie le troisième point d'arrêt
        cpu_halted <= '1';
        wait for CLK_PERIOD * 2;
        send_command("c", x"00");
        wait for CLK_PERIOD * 2;
        cpu_halted <= '0';
        
        cpu_pc <= x"3000";
        wait for CLK_PERIOD * 2;
        assert cpu_halt_req = '1'
            report "Erreur: Troisième point d'arrêt non détecté"
            severity error;
        
        -- Test 12: Performance des opérations de débogage
        report "Test 12: Test de performance des opérations de débogage";
        
        -- Test de latence pour les accès registres
        send_command("r", x"07");  -- Lecture registre
        wait for CLK_PERIOD * 2;
        reg_rdata <= "110011001";
        wait for CLK_PERIOD * 2;
        
        -- Test de latence pour les accès mémoire
        send_command("m", x"5000");
        wait for CLK_PERIOD * 2;
        mem_rdata <= "001100110";
        mem_ready <= '1';
        wait for CLK_PERIOD;
        mem_ready <= '0';
        
        -- Test de latence pour les points d'arrêt
        cpu_pc <= x"1000";
        wait for CLK_PERIOD;
        assert cpu_halt_req = '1'
            report "Erreur: Latence de détection du point d'arrêt trop élevée"
            severity error;
        
        -- Nettoyage final
        send_command("Z", x"1000");
        wait for CLK_PERIOD * 10;
        send_command("Z", x"2000");
        wait for CLK_PERIOD * 10;
        send_command("Z", x"3000");
        wait for CLK_PERIOD * 10;
        
        -- Fin des tests
        report "Fin des tests";
        wait;
    end process;
    
end architecture sim;