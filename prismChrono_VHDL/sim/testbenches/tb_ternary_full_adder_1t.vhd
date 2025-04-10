library ieee;
use ieee.std_logic_1164.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_ternary_full_adder_1t is
    -- Testbench n'a pas de ports
end entity tb_ternary_full_adder_1t;

architecture sim of tb_ternary_full_adder_1t is
    -- Composant à tester
    component ternary_full_adder_1t is
        port (
            a_in    : in  EncodedTrit;
            b_in    : in  EncodedTrit;
            c_in    : in  EncodedTrit;
            sum_out : out EncodedTrit;
            c_out   : out EncodedTrit
        );
    end component;
    
    -- Signaux pour les tests
    signal a_in_s    : EncodedTrit;
    signal b_in_s    : EncodedTrit;
    signal c_in_s    : EncodedTrit;
    signal sum_out_s : EncodedTrit;
    signal c_out_s   : EncodedTrit;
    
    -- Constante pour le délai entre les tests
    constant T : time := 10 ns;
    
    -- Fonction pour convertir un trit encodé en chaîne de caractères pour les messages d'erreur
    function trit_to_string(t: EncodedTrit) return string is
    begin
        if t = TRIT_N then
            return "N";
        elsif t = TRIT_Z then
            return "Z";
        elsif t = TRIT_P then
            return "P";
        else
            return "?";
        end if;
    end function;
    
begin
    -- Instanciation du composant à tester
    UUT: ternary_full_adder_1t
        port map (
            a_in    => a_in_s,
            b_in    => b_in_s,
            c_in    => c_in_s,
            sum_out => sum_out_s,
            c_out   => c_out_s
        );
    
    -- Process de test
    process
        -- Variables pour stocker les valeurs attendues
        variable expected_sum : EncodedTrit;
        variable expected_carry : EncodedTrit;
    begin
        report "Début des tests pour l'additionneur complet 1-trit";
        
        -- Test 1: N + N + N = P avec retenue N
        a_in_s <= TRIT_N;
        b_in_s <= TRIT_N;
        c_in_s <= TRIT_N;
        wait for T;
        expected_sum := TRIT_P;
        expected_carry := TRIT_N;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour N+N+N devrait être P, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour N+N+N devrait être N, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 2: N + N + Z = N avec retenue N
        a_in_s <= TRIT_N;
        b_in_s <= TRIT_N;
        c_in_s <= TRIT_Z;
        wait for T;
        expected_sum := TRIT_N;
        expected_carry := TRIT_N;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour N+N+Z devrait être N, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour N+N+Z devrait être N, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 3: N + N + P = Z avec retenue N
        a_in_s <= TRIT_N;
        b_in_s <= TRIT_N;
        c_in_s <= TRIT_P;
        wait for T;
        expected_sum := TRIT_Z;
        expected_carry := TRIT_N;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour N+N+P devrait être Z, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour N+N+P devrait être N, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 4: N + Z + Z = N avec retenue Z
        a_in_s <= TRIT_N;
        b_in_s <= TRIT_Z;
        c_in_s <= TRIT_Z;
        wait for T;
        expected_sum := TRIT_N;
        expected_carry := TRIT_Z;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour N+Z+Z devrait être N, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour N+Z+Z devrait être Z, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 5: Z + Z + Z = Z avec retenue Z
        a_in_s <= TRIT_Z;
        b_in_s <= TRIT_Z;
        c_in_s <= TRIT_Z;
        wait for T;
        expected_sum := TRIT_Z;
        expected_carry := TRIT_Z;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour Z+Z+Z devrait être Z, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour Z+Z+Z devrait être Z, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 6: P + P + P = Z avec retenue P
        a_in_s <= TRIT_P;
        b_in_s <= TRIT_P;
        c_in_s <= TRIT_P;
        wait for T;
        expected_sum := TRIT_Z;
        expected_carry := TRIT_P;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour P+P+P devrait être Z, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour P+P+P devrait être P, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 7: P + Z + Z = P avec retenue Z
        a_in_s <= TRIT_P;
        b_in_s <= TRIT_Z;
        c_in_s <= TRIT_Z;
        wait for T;
        expected_sum := TRIT_P;
        expected_carry := TRIT_Z;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour P+Z+Z devrait être P, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour P+Z+Z devrait être Z, mais est " & trit_to_string(c_out_s)
            severity error;
        
        -- Test 8: N + P + Z = Z avec retenue Z
        a_in_s <= TRIT_N;
        b_in_s <= TRIT_P;
        c_in_s <= TRIT_Z;
        wait for T;
        expected_sum := TRIT_Z;
        expected_carry := TRIT_Z;
        assert sum_out_s = expected_sum
            report "Erreur: La somme pour N+P+Z devrait être Z, mais est " & trit_to_string(sum_out_s)
            severity error;
        assert c_out_s = expected_carry
            report "Erreur: La retenue pour N+P+Z devrait être Z, mais est " & trit_to_string(c_out_s)
            severity error;
        
        report "Tests terminés avec succès";
        wait;
    end process;
    
end architecture sim;