library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;

entity tb_tnn_unit is
end entity tb_tnn_unit;

architecture sim of tb_tnn_unit is
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    constant VECTOR_SIZE : positive := 8;
    
    -- Signaux pour le DUT
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    signal start : std_logic := '0';
    signal busy : std_logic;
    signal done : std_logic;
    signal op_type : std_logic_vector(1 downto 0) := "00";
    signal operand1 : std_logic_vector(2*VECTOR_SIZE-1 downto 0) := (others => '0');
    signal operand2 : std_logic_vector(2*VECTOR_SIZE-1 downto 0) := (others => '0');
    signal result : std_logic_vector(8 downto 0);
    
    -- Procédure pour encoder une valeur ternaire
    procedure encode_ternary(signal vec : out std_logic_vector; position : natural; val : string) is
    begin
        case val is
            when "N" => vec(position*2+1 downto position*2) <= "00";
            when "Z" => vec(position*2+1 downto position*2) <= "01";
            when "P" => vec(position*2+1 downto position*2) <= "10";
            when others => vec(position*2+1 downto position*2) <= "01";
        end case;
    end procedure;
    
    -- Procédure pour configurer un vecteur ternaire complet
    procedure set_ternary_vector(signal vec : out std_logic_vector; values : string) is
    begin
        for i in 0 to VECTOR_SIZE-1 loop
            encode_ternary(vec, i, values(i+1 to i+1));
        end loop;
    end procedure;
    
begin
    -- Instanciation du DUT
    dut: entity work.tnn_unit
        generic map (
            VECTOR_SIZE => VECTOR_SIZE,
            ACC_WIDTH => 16
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            start => start,
            busy => busy,
            done => done,
            op_type => op_type,
            operand1 => operand1,
            operand2 => operand2,
            result => result
        );
    
    -- Génération de l'horloge
    clk <= not clk after CLK_PERIOD/2;
    
    -- Process de test
    process
        -- Procédure pour exécuter une opération
        procedure execute_operation(op1_str, op2_str : string) is
        begin
            set_ternary_vector(operand1, op1_str);
            set_ternary_vector(operand2, op2_str);
            start <= '1';
            wait until rising_edge(clk);
            start <= '0';
            wait until done = '1';
            wait until rising_edge(clk);
        end procedure;
        
        -- Procédure pour vérifier le résultat
        procedure check_result(expected : string) is
            variable expected_val : std_logic_vector(8 downto 0);
        begin
            case expected is
                when "N" => expected_val := "000000000";
                when "Z" => expected_val := "000000001";
                when "P" => expected_val := "000000010";
                when others => expected_val := "000000001";
            end case;
            
            assert result = expected_val
                report "Erreur: Résultat incorrect. Attendu: " & expected &
                       ", Obtenu: " & integer'image(to_integer(unsigned(result)))
                severity error;
        end procedure;
        
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Test 1: Produit scalaire positif
        report "Test 1: Produit scalaire positif";
        execute_operation("PPPPPPPP", "PPPPPPPP");
        check_result("P");
        
        -- Test 2: Produit scalaire négatif
        report "Test 2: Produit scalaire négatif";
        execute_operation("PPPPPPPP", "NNNNNNNN");
        check_result("N");
        
        -- Test 3: Produit scalaire nul
        report "Test 3: Produit scalaire nul";
        execute_operation("PNPNPNPN", "PNPNPNPN");
        check_result("Z");
        
        -- Test 4: Vecteur avec zéros
        report "Test 4: Vecteur avec zéros";
        execute_operation("PZPZPZPZ", "PZPZPZPZ");
        check_result("P");
        
        -- Test 5: Vecteur mixte
        report "Test 5: Vecteur mixte";
        execute_operation("PNZPNZPN", "NPZNPZNP");
        check_result("N");
        
        -- Test 6: Vérification du signal busy
        report "Test 6: Vérification du signal busy";
        start <= '1';
        wait until rising_edge(clk);
        assert busy = '1'
            report "Erreur: Signal busy non activé au démarrage"
            severity error;
        start <= '0';
        wait until done = '1';
        assert busy = '0'
            report "Erreur: Signal busy non désactivé à la fin"
            severity error;
        
        -- Test 7: Test de multiplication-accumulation (MAC)
        report "Test 7: Test de multiplication-accumulation";
        op_type <= "01";  -- Mode MAC
        execute_operation("PPPPPPPP", "PPPPPPPP");
        check_result("P");
        execute_operation("NNNNNNNN", "PPPPPPPP");
        check_result("N");
        
        -- Test 8: Test de la fonction d'activation
        report "Test 8: Test de la fonction d'activation";
        op_type <= "10";  -- Mode activation
        execute_operation("PNZPNZPN", "ZZZZZZZZ");  -- Le deuxième opérande est ignoré
        check_result("P");
        execute_operation("NNNNNNNN", "ZZZZZZZZ");
        check_result("N");
        execute_operation("ZZZZZZZZ", "ZZZZZZZZ");
        check_result("Z");
        
        -- Test 9: Test des cas limites
        report "Test 9: Test des cas limites";
        op_type <= "00";  -- Mode produit scalaire
        execute_operation("ZZZZZZZZ", "ZZZZZZZZ");
        check_result("Z");
        execute_operation("PPPPPPPP", "ZZZZZZZZ");
        check_result("Z");
        
        -- Test 10: Test de débordement MAC
        report "Test 10: Test de débordement MAC";
        op_type <= "01";  -- Mode MAC
        -- Accumulation répétée de valeurs positives pour provoquer un débordement
        for i in 1 to 16 loop
            execute_operation("PPPPPPPP", "PPPPPPPP");
            wait for CLK_PERIOD;
        end loop;
        check_result("P");  -- Vérifie que le résultat reste positif après débordement

        -- Test 11: Test de séquence MAC complexe
        report "Test 11: Test de séquence MAC complexe";
        op_type <= "01";
        execute_operation("PNZPNZPN", "NPZNPZNP");  -- Commence avec une valeur négative
        execute_operation("PPPPPPPP", "PPPPPPPP");  -- Ajoute une valeur positive
        execute_operation("ZZZZZZZZ", "PNPNPNPN");  -- Ajoute des zéros
        check_result("P");  -- Vérifie le résultat final

        -- Test 12: Test de réinitialisation
        report "Test 12: Test de réinitialisation";
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD * 2;
        op_type <= "01";
        execute_operation("PPPPPPPP", "PPPPPPPP");
        check_result("P");  -- Vérifie que l'accumulateur est correctement réinitialisé

        -- Test 13: Test de latence
        report "Test 13: Test de latence";
        op_type <= "00";  -- Mode produit scalaire
        start <= '1';
        wait until rising_edge(clk);
        assert busy = '1' report "Erreur: Signal busy non activé immédiatement" severity error;
        wait until done = '1';
        assert busy = '0' report "Erreur: Signal busy non désactivé après done" severity error;
        wait for CLK_PERIOD;
        start <= '0';
        wait for CLK_PERIOD;

        -- Test 14: Test de transition rapide entre opérations
        report "Test 14: Test de transition rapide entre opérations";
        op_type <= "00";  -- Mode produit scalaire
        execute_operation("PPPPPPPP", "PPPPPPPP");
        wait for CLK_PERIOD/2;
        op_type <= "01";  -- Mode MAC
        execute_operation("NNNNNNNN", "PPPPPPPP");
        wait for CLK_PERIOD/2;
        op_type <= "10";  -- Mode activation
        execute_operation("PNZPNZPN", "ZZZZZZZZ");
        check_result("P");
        
        -- Test de transition pendant l'opération
        op_type <= "00";
        start <= '1';
        wait until rising_edge(clk);
        op_type <= "01";
        wait for CLK_PERIOD;
        op_type <= "10";
        wait until done = '1';
        start <= '0';
        check_result("P");

        -- Test 15: Test de robustesse du MAC
        report "Test 15: Test de robustesse du MAC";
        op_type <= "01";  -- Mode MAC
        -- Alternance de valeurs positives et négatives avec délais variables
        for i in 1 to 8 loop
            execute_operation("PPPPPPPP", "PPPPPPPP");
            wait for CLK_PERIOD * (i mod 3 + 1);
            execute_operation("NNNNNNNN", "PPPPPPPP");
            wait for CLK_PERIOD * ((i + 1) mod 3 + 1);
        end loop;
        check_result("Z");  -- Le résultat devrait être proche de zéro
        
        -- Test de robustesse avec des opérations consécutives rapides
        for i in 1 to 4 loop
            start <= '1';
            wait for CLK_PERIOD/2;
            start <= '0';
            wait for CLK_PERIOD/2;
        end loop;
        wait until done = '1';
        check_result("Z");

        -- Test 16: Test de stabilité de l'activation
        report "Test 16: Test de stabilité de l'activation";
        op_type <= "10";  -- Mode activation
        -- Test avec des valeurs alternées
        execute_operation("PNPNPNPN", "ZZZZZZZZ");
        check_result("P");
        execute_operation("NPNPNPNP", "ZZZZZZZZ");
        check_result("N");
        execute_operation("ZZZZZZZZ", "ZZZZZZZZ");
        check_result("Z");

        -- Test 17: Test d'accès mémoire concurrents
        report "Test 17: Test d'accès mémoire concurrents";
        op_type <= "01";  -- Mode MAC
        -- Lancement de plusieurs opérations en séquence rapide
        for i in 1 to 4 loop
            start <= '1';
            wait for CLK_PERIOD/4;
            start <= '0';
            wait for CLK_PERIOD/4;
            set_ternary_vector(operand1, "PPPPPPPP");
            set_ternary_vector(operand2, "PPPPPPPP");
            wait for CLK_PERIOD/2;
        end loop;
        wait until done = '1';
        check_result("P");

        -- Test 18: Test de points d'arrêt multiples
        report "Test 18: Test de points d'arrêt multiples";
        -- Test de réinitialisation pendant une opération
        start <= '1';
        wait for CLK_PERIOD/2;
        rst_n <= '0';
        wait for CLK_PERIOD;
        rst_n <= '1';
        wait for CLK_PERIOD;
        assert busy = '0' report "Erreur: Signal busy actif après reset" severity error;
        
        -- Test 19: Test de performance
        report "Test 19: Test de performance";
        -- Mesure du temps de traitement pour différentes opérations
        op_type <= "00";  -- Mode produit scalaire
        for i in 1 to 100 loop
            execute_operation("PNZPNZPN", "NPZNPZNP");
            wait for CLK_PERIOD;
        end loop;
        
        -- Test 20: Test de robustesse avancée
        report "Test 20: Test de robustesse avancée";
        -- Test de changements rapides d'opérations avec reset
        for i in 1 to 5 loop
            op_type <= "00";
            start <= '1';
            wait for CLK_PERIOD/4;
            op_type <= "01";
            wait for CLK_PERIOD/4;
            op_type <= "10";
            wait for CLK_PERIOD/4;
            rst_n <= '0';
            wait for CLK_PERIOD/4;
            rst_n <= '1';
            start <= '0';
            wait for CLK_PERIOD;
        end loop;
        assert busy = '0' report "Erreur: Signal busy actif après séquence de test" severity error;

        -- Fin des tests
        report "Fin des tests";
        wait;
    end process;
    
end architecture sim;