library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_mul_div_unit is
end entity tb_mul_div_unit;

architecture testbench of tb_mul_div_unit is
    -- Signaux pour le composant sous test
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal start       : std_logic := '0';
    signal op_type     : std_logic_vector(1 downto 0) := "00";
    signal op_a        : EncodedWord := (others => '0');
    signal op_b        : EncodedWord := (others => '0');
    signal result      : EncodedWord;
    signal flags       : FlagBusType;
    signal done        : std_logic;
    
    -- Constantes pour les types d'opération
    constant OP_MUL : std_logic_vector(1 downto 0) := "00";
    constant OP_DIV : std_logic_vector(1 downto 0) := "01";
    constant OP_MOD : std_logic_vector(1 downto 0) := "10";
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Procédure pour attendre la fin d'une opération
    procedure wait_for_done is
    begin
        wait until done = '1';
        wait for CLK_PERIOD;
    end procedure;
    
    -- Procédure pour vérifier les flags
    procedure check_flags(
        expected_zf : std_logic;
        expected_sf : std_logic;
        expected_of : std_logic;
        expected_cf : std_logic;
        expected_xf : std_logic
    ) is
    begin
        assert flags.zero_flag = expected_zf
            report "ZF incorrect: " & std_logic'image(flags.zero_flag) & ", attendu: " & std_logic'image(expected_zf)
            severity error;
        assert flags.sign_flag = expected_sf
            report "SF incorrect: " & std_logic'image(flags.sign_flag) & ", attendu: " & std_logic'image(expected_sf)
            severity error;
        assert flags.overflow_flag = expected_of
            report "OF incorrect: " & std_logic'image(flags.overflow_flag) & ", attendu: " & std_logic'image(expected_of)
            severity error;
        assert flags.carry_flag = expected_cf
            report "CF incorrect: " & std_logic'image(flags.carry_flag) & ", attendu: " & std_logic'image(expected_cf)
            severity error;
        assert flags.extended_flag = expected_xf
            report "XF incorrect: " & std_logic'image(flags.extended_flag) & ", attendu: " & std_logic'image(expected_xf)
            severity error;
    end procedure;

begin
    -- Instanciation du composant sous test
    UUT: entity work.mul_div_unit
        port map (
            clk     => clk,
            rst     => rst,
            start   => start,
            op_type => op_type,
            op_a    => op_a,
            op_b    => op_b,
            result  => result,
            flags   => flags,
            done    => done
        );
    
    -- Processus de génération d'horloge
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de test principal
    test_process: process
    begin
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Test 1: Multiplication simple (1 * 1)
        op_type <= OP_MUL;
        op_a <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZP"); -- 1
        op_b <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZP"); -- 1
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait_for_done;
        assert result = encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZP")
            report "Test 1 échoué: 1 * 1 devrait être 1"
            severity error;
        check_flags('0', '0', '0', '0', '0');
        
        -- Test 2: Multiplication par zéro
        op_type <= OP_MUL;
        op_a <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZP"); -- 1
        op_b <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZZ"); -- 0
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait_for_done;
        assert result = encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZZ")
            report "Test 2 échoué: 1 * 0 devrait être 0"
            severity error;
        check_flags('1', '0', '0', '0', '0');
        
        -- Test 3: Multiplication avec nombre négatif
        op_type <= OP_MUL;
        op_a <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZZP"); -- 1
        op_b <= encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZN"); -- -1
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait_for_done;
        assert result = encode_trit_vector("ZZZZZZZZZZZZZZZZZZZZZZN")
            report "Test 3 échoué: 1 * (-1) devrait être -1"
            severity error;
        check_flags('0', '1', '0', '0', '0');
        
        -- Test 4: Multiplication avec dépassement
        op_type <= OP_MUL;
        op_a <= encode_trit_vector("PPPPPPPPPPPPPPPPPPPPPPPP"); -- Max positif
        op_b <= encode_trit_vector("PPPPPPPPPPPPPPPPPPPPPPPP"); -- Max positif
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';
        wait_for_done;
        check_flags('0', '0', '1', '0', '0'); -- Overflow attendu
        
        -- Fin des tests
        wait for CLK_PERIOD * 10;
        report "Tests terminés";
        wait;
    end process;

end architecture testbench;