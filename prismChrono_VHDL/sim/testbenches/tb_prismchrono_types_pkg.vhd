library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package à tester
library work;
use work.prismchrono_types_pkg.all;

entity tb_prismchrono_types_pkg is
    -- Testbench n'a pas de ports
end entity tb_prismchrono_types_pkg;

architecture sim of tb_prismchrono_types_pkg is
    -- Signaux pour les tests
    signal test_trit : EncodedTrit;
    signal test_int : integer;
    signal test_result_trit : EncodedTrit;
    signal test_result_int : integer;
begin
    -- Process de test pour les fonctions de conversion
    process
    begin
        -- Test de to_integer
        report "Test de la fonction to_integer";
        
        test_trit <= TRIT_N;
        wait for 10 ns;
        test_result_int <= to_integer(test_trit);
        assert test_result_int = -1
            report "Erreur: to_integer(TRIT_N) devrait retourner -1, mais a retourné " & integer'image(test_result_int)
            severity error;
        
        test_trit <= TRIT_Z;
        wait for 10 ns;
        test_result_int <= to_integer(test_trit);
        assert test_result_int = 0
            report "Erreur: to_integer(TRIT_Z) devrait retourner 0, mais a retourné " & integer'image(test_result_int)
            severity error;
        
        test_trit <= TRIT_P;
        wait for 10 ns;
        test_result_int <= to_integer(test_trit);
        assert test_result_int = 1
            report "Erreur: to_integer(TRIT_P) devrait retourner 1, mais a retourné " & integer'image(test_result_int)
            severity error;
        
        test_trit <= "11"; -- Encodage non utilisé
        wait for 10 ns;
        test_result_int <= to_integer(test_trit);
        assert test_result_int = 0
            report "Erreur: to_integer(""11"") devrait retourner 0 (valeur par défaut), mais a retourné " & integer'image(test_result_int)
            severity error;
        
        -- Test de to_encoded_trit
        report "Test de la fonction to_encoded_trit";
        
        test_int <= -1;
        wait for 10 ns;
        test_result_trit <= to_encoded_trit(test_int);
        assert test_result_trit = TRIT_N
            report "Erreur: to_encoded_trit(-1) devrait retourner TRIT_N"
            severity error;
        
        test_int <= 0;
        wait for 10 ns;
        test_result_trit <= to_encoded_trit(test_int);
        assert test_result_trit = TRIT_Z
            report "Erreur: to_encoded_trit(0) devrait retourner TRIT_Z"
            severity error;
        
        test_int <= 1;
        wait for 10 ns;
        test_result_trit <= to_encoded_trit(test_int);
        assert test_result_trit = TRIT_P
            report "Erreur: to_encoded_trit(1) devrait retourner TRIT_P"
            severity error;
        
        -- Test avec des valeurs hors de la plage normale
        test_int <= -5;
        wait for 10 ns;
        test_result_trit <= to_encoded_trit(test_int);
        assert test_result_trit = TRIT_N
            report "Erreur: to_encoded_trit(-5) devrait retourner TRIT_N"
            severity error;
        
        test_int <= 5;
        wait for 10 ns;
        test_result_trit <= to_encoded_trit(test_int);
        assert test_result_trit = TRIT_P
            report "Erreur: to_encoded_trit(5) devrait retourner TRIT_P"
            severity error;
        
        report "Tests terminés";
        wait;
    end process;
    
end architecture sim;