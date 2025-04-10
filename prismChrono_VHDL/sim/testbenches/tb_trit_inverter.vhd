library ieee;
use ieee.std_logic_1164.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_trit_inverter is
    -- Testbench n'a pas de ports
end entity tb_trit_inverter;

architecture sim of tb_trit_inverter is
    -- Composant à tester
    component trit_inverter is
        port (
            trit_in  : in  EncodedTrit;
            trit_out : out EncodedTrit
        );
    end component;
    
    -- Signaux pour les tests
    signal input_trit  : EncodedTrit;
    signal output_trit : EncodedTrit;
    
    -- Constante pour le délai entre les tests
    constant T : time := 10 ns;
begin
    -- Instanciation du composant à tester
    UUT: trit_inverter
        port map (
            trit_in  => input_trit,
            trit_out => output_trit
        );
    
    -- Process de test
    process
    begin
        -- Test avec TRIT_N en entrée
        input_trit <= TRIT_N;
        wait for T;
        assert output_trit = TRIT_P
            report "Erreur: L'inversion de TRIT_N devrait être TRIT_P"
            severity error;
        
        -- Test avec TRIT_Z en entrée
        input_trit <= TRIT_Z;
        wait for T;
        assert output_trit = TRIT_Z
            report "Erreur: L'inversion de TRIT_Z devrait être TRIT_Z"
            severity error;
        
        -- Test avec TRIT_P en entrée
        input_trit <= TRIT_P;
        wait for T;
        assert output_trit = TRIT_N
            report "Erreur: L'inversion de TRIT_P devrait être TRIT_N"
            severity error;
        
        -- Test avec l'encodage non utilisé "11" en entrée
        input_trit <= "11";
        wait for T;
        assert output_trit = "11"
            report "Erreur: L'inversion de ""11"" devrait être ""11"" (valeur inchangée)"
            severity error;
        
        report "Tests terminés avec succès";
        wait;
    end process;
    
end architecture sim;