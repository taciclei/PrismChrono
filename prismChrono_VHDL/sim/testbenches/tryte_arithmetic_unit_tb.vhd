library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

entity tryte_arithmetic_unit_tb is
end entity tryte_arithmetic_unit_tb;

architecture behavior of tryte_arithmetic_unit_tb is
    -- Signaux pour le composant sous test
    signal clk         : std_logic := '0';
    signal rst_n       : std_logic := '0';
    signal operation   : std_logic_vector(2 downto 0);
    signal valid_in    : std_logic := '0';
    signal operand_a   : std_logic_vector(23 downto 0);
    signal operand_b   : std_logic_vector(23 downto 0);
    signal result      : std_logic_vector(23 downto 0);
    signal valid_out   : std_logic;
    signal overflow    : std_logic;
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Composant sous test
    component tryte_arithmetic_unit is
        port (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            operation   : in  std_logic_vector(2 downto 0);
            valid_in    : in  std_logic;
            operand_a   : in  std_logic_vector(23 downto 0);
            operand_b   : in  std_logic_vector(23 downto 0);
            result      : out std_logic_vector(23 downto 0);
            valid_out   : out std_logic;
            overflow    : out std_logic
        );
    end component;

    -- Procédure pour vérifier les résultats
    procedure check_result(
        constant test_name : in string;
        constant expected  : in std_logic_vector(23 downto 0);
        constant actual    : in std_logic_vector(23 downto 0);
        constant exp_ovf   : in std_logic
    ) is
    begin
        assert actual = expected
            report test_name & ": Résultat incorrect. Attendu: " &
                   to_string(to_integer(unsigned(expected))) &
                   ", Obtenu: " & to_string(to_integer(unsigned(actual)))
            severity error;
            
        assert overflow = exp_ovf
            report test_name & ": Overflow incorrect. Attendu: " &
                   std_logic'image(exp_ovf) & ", Obtenu: " &
                   std_logic'image(overflow)
            severity error;
    end procedure;

begin
    -- Instanciation du composant sous test
    UUT: tryte_arithmetic_unit
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

    -- Process de test
    process
    begin
        -- Initialisation
        rst_n <= '0';
        valid_in <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;

        -- Test 1: Addition Base 24 sans overflow
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"050A0F14";  -- [5,10,15,20]
        operand_b <= x"020408";    -- [2,4,0,8]
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result("Addition sans overflow", x"070C0F1C", result, '0');

        -- Test 2: Addition Base 24 avec overflow
        operand_a <= x"0F0F0F0F";  -- [15,15,15,15]
        operand_b <= x"0F0F0F0F";  -- [15,15,15,15]
        wait for CLK_PERIOD;
        check_result("Addition avec overflow", x"060606", result, '1');

        -- Test 3: Soustraction Base 24
        operation <= TAU_OP_SUB_B24;
        operand_a <= x"0C080402";  -- [12,8,4,2]
        operand_b <= x"040402";    -- [4,4,0,2]
        wait for CLK_PERIOD;
        check_result("Soustraction", x"080400", result, '0');

        -- Test 4: Multiplication Base 24
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"020304";    -- [2,3,0,4]
        operand_b <= x"030205";    -- [3,2,0,5]
        wait for CLK_PERIOD;
        check_result("Multiplication", x"060614", result, '0');

        -- Test 5: Conversion Base 24 vers ternaire
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= x"0C0000";    -- [12,0,0,0]
        wait for CLK_PERIOD;
        check_result("Conversion B24->T", x"FFFFFF", result, '0');

        -- Test 6: Conversion ternaire vers Base 24
        operation <= TAU_OP_CONV_T_B24;
        operand_a <= x"FFFFFF";    -- [-1,-1,-1,-1]
        wait for CLK_PERIOD;
        check_result("Conversion T->B24", x"171717", result, '0');

        -- Test 7: Addition Base 24 avec valeurs maximales
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"171717";    -- [23,23,23,23]
        operand_b <= x"171717";    -- [23,23,23,23]
        wait for CLK_PERIOD;
        check_result("Addition valeurs max", x"0E0E0E", result, '1');

        -- Test 8: Soustraction Base 24 avec valeur négative
        operation <= TAU_OP_SUB_B24;
        operand_a <= x"000000";    -- [0,0,0,0]
        operand_b <= x"010101";    -- [1,1,1,1]
        wait for CLK_PERIOD;
        check_result("Soustraction négative", x"171717", result, '0');

        -- Test 9: Multiplication Base 24 avec grands nombres
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"0C0C0C";    -- [12,12,12,12]
        operand_b <= x"020202";    -- [2,2,2,2]
        wait for CLK_PERIOD;
        check_result("Multiplication grands nombres", x"121212", result, '0');

        -- Test 10: Conversion Base 24 vers ternaire (valeur max)
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= x"171717";    -- [23,23,23,23]
        wait for CLK_PERIOD;
        check_result("Conversion B24->T max", x"FFFFFF", result, '0');

        -- Test 11: Base 24 Addition avec valeurs limites
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"171700";    -- [23,23,0,0]
        operand_b <= x"000017";    -- [0,0,0,23]
        wait for CLK_PERIOD;
        check_result("Addition avec valeurs limites", x"171717", result, '0');

        -- Test 12: Base 24 Multiplication avec overflow
        operation <= TAU_OP_MUL_B24;
        operand_a <= x"0C0C0C";    -- [12,12,12,12]
        operand_b <= x"030303";    -- [3,3,3,3]
        wait for CLK_PERIOD;
        check_result("Multiplication avec overflow", x"161616", result, '1');

        -- Test 13: Conversion Base 24 vers ternaire (valeur spéciale)
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= x"0B0B0B";    -- [11,11,11,11]
        wait for CLK_PERIOD;
        check_result("Conversion B24->T spéciale", x"EEEEEE", result, '0');

        -- Test 14: Soustraction avec underflow
        operation <= TAU_OP_SUB_B24;
        operand_a <= x"000000";    -- [0,0,0,0]
        operand_b <= x"171717";    -- [23,23,23,23]
        wait for CLK_PERIOD;
        check_result("Soustraction avec underflow", x"0E0E0E", result, '1');

        -- Test 15: Test de performance avec opérations mixtes
        operation <= TAU_OP_ADD_B24;
        for i in 0 to 4 loop
            operand_a <= std_logic_vector(to_unsigned(i * 4, 24));
            operand_b <= std_logic_vector(to_unsigned(i * 5, 24));
            valid_in <= '1';
            wait for CLK_PERIOD;
            assert valid_out = '1' report "Performance mixte: Sortie non valide" severity error;
            
            operation <= TAU_OP_MUL_B24;
            wait for CLK_PERIOD;
            assert valid_out = '1' report "Performance mixte: Sortie non valide" severity error;
        end loop;

        -- Test 16: Opérations en cascade Base 24
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"0A0B0C";  -- [10,11,12]
        operand_b <= x"010203";  -- [1,2,3]
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result("Addition cascade 1", x"0B0D0F", result, '0');
        
        operand_a <= result;      -- Utiliser le résultat précédent
        operand_b <= x"040506";  -- [4,5,6]
        wait for CLK_PERIOD;
        check_result("Addition cascade 2", x"0F1215", result, '0');

        -- Test 17: Conversion aller-retour
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= x"0C0C0C";  -- [12,12,12]
        wait for CLK_PERIOD;
        
        operation <= TAU_OP_CONV_T_B24;
        operand_a <= result;      -- Utiliser le résultat de la conversion
        wait for CLK_PERIOD;
        check_result("Conversion aller-retour", x"0C0C0C", result, '0');

        -- Test 18: Opérations rapides Base 24
        operation <= TAU_OP_ADD_B24;
        for i in 0 to 9 loop
            operand_a <= std_logic_vector(to_unsigned(i, 24));
            operand_b <= std_logic_vector(to_unsigned(23 - i, 24));
            valid_in <= '1';
            wait for CLK_PERIOD/2;  -- Test avec timing plus serré
            assert valid_out = '1' report "Performance rapide: Sortie non valide" severity error;
        end loop;

        -- Test 19: Test de limites Base 24
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"171717";  -- Valeurs maximales [23,23,23]
        operand_b <= x"171717";  -- [23,23,23]
        valid_in <= '1';
        wait for CLK_PERIOD;
        check_result("Addition limite max", x"0E0E0E", result, '1');

        operation <= TAU_OP_SUB_B24;
        operand_a <= x"000000";  -- Valeurs minimales [0,0,0]
        operand_b <= x"171717";  -- [23,23,23]
        wait for CLK_PERIOD;
        check_result("Soustraction limite min", x"0E0E0E", result, '1');

        -- Test 20: Séquence complexe d'opérations
        operation <= TAU_OP_ADD_B24;
        operand_a <= x"0A0B0C";  -- [10,11,12]
        operand_b <= x"010203";  -- [1,2,3]
        valid_in <= '1';
        wait for CLK_PERIOD;
        
        operation <= TAU_OP_MUL_B24;
        operand_a <= result;      -- Utiliser le résultat de l'addition
        operand_b <= x"020202";  -- [2,2,2]
        wait for CLK_PERIOD;
        
        operation <= TAU_OP_CONV_B24_T;
        operand_a <= result;      -- Utiliser le résultat de la multiplication
        wait for CLK_PERIOD;

        -- Fin des tests
        valid_in <= '0';
        wait for CLK_PERIOD * 2;
        
        report "Tests terminés avec succès";
        wait;
    end process;

end architecture behavior;