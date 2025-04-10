library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

entity tb_tryte_arithmetic_unit is
end entity tb_tryte_arithmetic_unit;

architecture sim of tb_tryte_arithmetic_unit is
    -- Signaux de test
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal operation   : std_logic_vector(2 downto 0);
    signal valid_in    : std_logic := '0';
    signal operand_a   : std_logic_vector(23 downto 0);
    signal operand_b   : std_logic_vector(23 downto 0);
    signal result      : std_logic_vector(23 downto 0);
    signal valid_out   : std_logic;
    signal overflow    : std_logic;
    
    -- Constantes
    constant CLK_PERIOD : time := 10 ns;
    
    -- Procédure pour vérifier un résultat
    procedure check_result(
        constant expected : in std_logic_vector(23 downto 0);
        constant actual   : in std_logic_vector(23 downto 0);
        constant msg      : in string
    ) is
    begin
        assert actual = expected
            report msg & ". Expected: " & to_hstring(expected) &
                  ", Got: " & to_hstring(actual)
            severity error;
    end procedure;
    
begin
    -- Instanciation du composant à tester
    UUT: entity work.tryte_arithmetic_unit
    port map (
        clk         => clk,
        rst_n       => rst_n,
        operation   => operation,
        valid_in    => valid_in,
        operand_a   => operand_a,
        operand_b   => operand_b,
        result      => result,
        valid_out   => valid_out,
        overflow    => overflow
    );
    
    -- Génération de l'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Processus de test
    process
        variable test_a, test_b : std_logic_vector(5 downto 0);
    begin
        -- Reset initial
        rst_n <= '0';
        valid_in <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;
        
        -- Test 1: Addition Base 24
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"050A0F14";  -- [5,10,15,20] en Base 24
        operand_b <= x"02040810";  -- [2,4,8,16] en Base 24
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result(x"070C0100", result, "Addition Base 24 failed");
        assert overflow = '1' report "Overflow non détecté" severity error;
        
        -- Test 2: Soustraction Base 24
        operation <= TAU_OP_SUB_B24;
        operand_a <= x"0C0C0C0C";  -- [12,12,12,12] en Base 24
        operand_b <= x"04040404";  -- [4,4,4,4] en Base 24
        wait for CLK_PERIOD;
        check_result(x"08080808", result, "Soustraction Base 24 failed");
        
        -- Test 3: Multiplication Base 24
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"02020202";  -- [2,2,2,2] en Base 24
        operand_b <= x"03030303";  -- [3,3,3,3] en Base 24
        wait for CLK_PERIOD;
        check_result(x"06060606", result, "Multiplication Base 24 failed");
        
        -- Test 4: Conversion Base 24 vers ternaire
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= x"0D0E0F10";  -- [13,14,15,16] en Base 24
        wait for CLK_PERIOD;
        check_result(x"1D1E1F20", result, "Conversion Base 24 vers ternaire failed");
        
        -- Test 5: Conversion ternaire vers Base 24
        operation <= TAU_OP_CONV_T_B24;
        operand_a <= x"1D1E1F20";  -- Valeurs ternaires équilibrées
        wait for CLK_PERIOD;
        check_result(x"0D0E0F10", result, "Conversion ternaire vers Base 24 failed");
        
        -- Test 6: Addition avec grand nombres en Base 24
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"151617FF";  -- Grands nombres en Base 24
        operand_b <= x"0A0B0C01";  -- Nombres moyens en Base 24
        wait for CLK_PERIOD;
        check_result(x"1F212400", result, "Addition grands nombres Base 24 failed");
        assert overflow = '1' report "Overflow non détecté pour grands nombres" severity error;
        
        -- Test 7: Multiplication complexe Base 24
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"030405FF";  -- Nombres avec overflow potentiel
        operand_b <= x"020202FF";  -- Multiplicateur complexe
        wait for CLK_PERIOD;
        check_result(x"060A0AFF", result, "Multiplication complexe Base 24 failed");
        
        -- Test 8: Conversion Base 60
        operation <= TAU_OP_CONV_B60;
        operand_a <= x"3C3D3E3F";  -- Test avec valeurs limites
        wait for CLK_PERIOD;
        check_result(x"0A0B0C0D", result, "Conversion Base 60 failed");
        
        -- Test 9: Addition avec dépassement négatif
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"000000FF";  -- Valeur minimale en Base 24
        operand_b <= x"FFFFFF00";  -- Valeur négative en Base 24
        wait for CLK_PERIOD;
        check_result(x"000000FF", result, "Addition avec dépassement négatif failed");
        assert overflow = '1' report "Overflow négatif non détecté" severity error;
        
        -- Test 10: Soustraction avec résultat nul
        operation <= TAU_OP_SUB_B24;
        operand_a <= x"0A0A0A0A";
        operand_b <= x"0A0A0A0A";
        wait for CLK_PERIOD;
        check_result(x"00000000", result, "Soustraction avec résultat nul failed");
        
        -- Test 11: Multiplication par zéro
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"0A0B0C0D";
        operand_b <= x"00000000";
        wait for CLK_PERIOD;
        check_result(x"00000000", result, "Multiplication par zéro failed");
        
        -- Test 12: Conversion ternaire avec valeurs maximales
        operation <= TAU_OP_CONV_T_B24;
        operand_a <= x"FFFFFF00";  -- Valeurs ternaires maximales
        wait for CLK_PERIOD;
        check_result(x"171717FF", result, "Conversion ternaire maximale failed");
        
        -- Test 13: Addition séquentielle rapide
        operation <= TAU_OP_ADD_B24;
        -- Premier calcul
        operand_a <= x"010203FF";
        operand_b <= x"030201FF";
        valid_in <= '1';
        wait for CLK_PERIOD;
        -- Deuxième calcul immédiat
        operand_a <= x"050607FF";
        operand_b <= x"070605FF";
        wait for CLK_PERIOD;
        check_result(x"0C0C0CFF", result, "Addition séquentielle rapide failed");
        
        -- Test 14: Test de performance Base 24
        operation <= TAU_OP_ADD_B24;
        for i in 0 to 9 loop
            operand_a <= std_logic_vector(to_unsigned(i * 2, 24));
            operand_b <= std_logic_vector(to_unsigned(i * 3, 24));
            valid_in <= '1';
            wait for CLK_PERIOD;
            assert valid_out = '1' report "Performance test: Invalid output timing" severity error;
        end loop;
        
        -- Test 15: Conversion Base 60 avec valeurs extrêmes
        operation <= TAU_OP_CONV_B60;
        operand_a <= x"3B3B3B3B";  -- Valeurs proches de 60
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result(x"0A0A0A0A", result, "Conversion Base 60 valeurs extrêmes failed");
        
        -- Test 16: Test de débordement en cascade
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"171717FF";
        operand_b <= x"171717FF";
        valid_in <= '1';
        wait for CLK_PERIOD;
        assert overflow = '1' report "Débordement en cascade non détecté" severity error;
        
        -- Test 17: Test de latence
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"0F0F0F0F";
        operand_b <= x"02020202";
        valid_in <= '1';
        wait for CLK_PERIOD;
        assert valid_out = '1' report "Latence excessive détectée" severity error;
        check_result(x"1E1E1E1E", result, "Test de latence multiplication failed");
        
        -- Test 18: Test de conversion Base 24 vers Base 60 avec valeurs spéciales
        operation <= TAU_OP_CONV_B60;
        operand_a <= x"3C3C3C3C";  -- Valeurs proches de la limite Base 60
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result(x"0B0B0B0B", result, "Conversion Base 24 vers Base 60 valeurs spéciales failed");
        
        -- Test 19: Test de stabilité des résultats
        operation <= TAU_OP_ADD_B24;
        for i in 0 to 4 loop
            operand_a <= x"0A0B0C" & std_logic_vector(to_unsigned(i, 8));
            operand_b <= x"01020304";
            valid_in <= '1';
            wait for CLK_PERIOD;
            assert valid_out = '1' report "Stabilité des résultats compromise" severity error;
        end loop;
        
        -- Test 20: Test de conversion rapide Base 24
        operation <= TAU_OP_CONV_T_B24;
        for i in 0 to 4 loop
            operand_a <= x"1A1B1C" & std_logic_vector(to_unsigned(i, 8));
            valid_in <= '1';
            wait for CLK_PERIOD;
            assert valid_out = '1' report "Conversion rapide Base 24 échouée" severity error;
        end loop;
        
        -- Fin des tests
        valid_in <= '0';
        wait for CLK_PERIOD * 2;
        
        report "Tests terminés avec succès";
        wait;
    end process;
    
end architecture sim;