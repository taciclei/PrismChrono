library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

entity tau_instructions_tb is
end entity tau_instructions_tb;

architecture behavior of tau_instructions_tb is
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
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de test
    test_process: process
        -- Procédure pour tester une opération
        procedure test_operation(
            op      : in std_logic_vector(2 downto 0);
            a       : in std_logic_vector(23 downto 0);
            b       : in std_logic_vector(23 downto 0);
            exp_res : in std_logic_vector(23 downto 0)
        ) is
        begin
            operation <= op;
            operand_a <= a;
            operand_b <= b;
            valid_in <= '1';
            wait for CLK_PERIOD;
            valid_in <= '0';
            wait until valid_out = '1';
            assert result = exp_res
                report "Test failed for operation " & to_string(op) &
                       ". Expected " & to_string(exp_res) &
                       " but got " & to_string(result)
                severity error;
            wait for CLK_PERIOD;
        end procedure;
        
    begin
        -- Reset initial
        rst_n <= '0';
        wait for CLK_PERIOD * 2;
        rst_n <= '1';
        wait for CLK_PERIOD;
        
        -- Test 1: Addition Base 24
        test_operation(
            op      => TAU_OP_ADD_B24,
            a       => x"123456",  -- Exemple de valeurs en Base 24
            b       => x"789ABC",
            exp_res => x"8ACEF0"   -- Résultat attendu
        );
        
        -- Test 2: Conversion Base 24 vers ternaire
        test_operation(
            op      => TAU_OP_CONV_B24_T,
            a       => x"0C0000",  -- Valeur 12 en Base 24
            b       => x"000000",
            exp_res => x"0D0000"   -- +13 en ternaire équilibré
        );
        
        -- Test 3: Multiplication Base 24
        test_operation(
            op      => TAU_OP_MUL_B24,
            a       => x"020000",  -- 2 en Base 24
            b       => x"030000",  -- 3 en Base 24
            exp_res => x"060000"   -- 6 en Base 24
        );
        
        -- Test 4: Conversion ternaire vers Base 24
        test_operation(
            op      => TAU_OP_CONV_T_B24,
            a       => x"0D0000",  -- +13 en ternaire équilibré
            b       => x"000000",
            exp_res => x"0C0000"   -- 12 en Base 24
        );
        
        -- Fin des tests
        report "Tests terminés";
        wait;
    end process;
    
end architecture behavior;