library ieee;
use ieee.std_logic_1164.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity ternary_full_adder_1t is
    port (
        a_in    : in  EncodedTrit;
        b_in    : in  EncodedTrit;
        c_in    : in  EncodedTrit;
        sum_out : out EncodedTrit;
        c_out   : out EncodedTrit
    );
end entity ternary_full_adder_1t;

architecture rtl of ternary_full_adder_1t is
begin
    -- Implémentation directe sans utiliser de variables intermédiaires pour éviter l'overflow
    process(a_in, b_in, c_in)
    begin
        -- Calcul direct de la somme et de la retenue en fonction des entrées
        -- Cas N + N + N = P avec retenue N
        if a_in = TRIT_N and b_in = TRIT_N and c_in = TRIT_N then
            sum_out <= TRIT_P;
            c_out <= TRIT_N;
        
        -- Cas N + N + Z = N avec retenue N
        elsif a_in = TRIT_N and b_in = TRIT_N and c_in = TRIT_Z then
            sum_out <= TRIT_N;
            c_out <= TRIT_N;
        
        -- Cas N + N + P = Z avec retenue N
        elsif a_in = TRIT_N and b_in = TRIT_N and c_in = TRIT_P then
            sum_out <= TRIT_Z;
            c_out <= TRIT_N;
        
        -- Cas N + Z + N = N avec retenue N
        elsif a_in = TRIT_N and b_in = TRIT_Z and c_in = TRIT_N then
            sum_out <= TRIT_N;
            c_out <= TRIT_N;
        
        -- Cas N + Z + Z = N avec retenue Z
        elsif a_in = TRIT_N and b_in = TRIT_Z and c_in = TRIT_Z then
            sum_out <= TRIT_N;
            c_out <= TRIT_Z;
        
        -- Cas N + Z + P = Z avec retenue Z
        elsif a_in = TRIT_N and b_in = TRIT_Z and c_in = TRIT_P then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas N + P + N = Z avec retenue N
        elsif a_in = TRIT_N and b_in = TRIT_P and c_in = TRIT_N then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas N + P + Z = Z avec retenue Z
        elsif a_in = TRIT_N and b_in = TRIT_P and c_in = TRIT_Z then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas N + P + P = P avec retenue Z
        elsif a_in = TRIT_N and b_in = TRIT_P and c_in = TRIT_P then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas Z + N + N = N avec retenue N
        elsif a_in = TRIT_Z and b_in = TRIT_N and c_in = TRIT_N then
            sum_out <= TRIT_N;
            c_out <= TRIT_N;
        
        -- Cas Z + N + Z = N avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_N and c_in = TRIT_Z then
            sum_out <= TRIT_N;
            c_out <= TRIT_Z;
        
        -- Cas Z + N + P = Z avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_N and c_in = TRIT_P then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas Z + Z + N = N avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_Z and c_in = TRIT_N then
            sum_out <= TRIT_N;
            c_out <= TRIT_Z;
        
        -- Cas Z + Z + Z = Z avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_Z and c_in = TRIT_Z then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas Z + Z + P = P avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_Z and c_in = TRIT_P then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas Z + P + N = Z avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_P and c_in = TRIT_N then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas Z + P + Z = P avec retenue Z
        elsif a_in = TRIT_Z and b_in = TRIT_P and c_in = TRIT_Z then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas Z + P + P = N avec retenue P
        elsif a_in = TRIT_Z and b_in = TRIT_P and c_in = TRIT_P then
            sum_out <= TRIT_N;
            c_out <= TRIT_P;
        
        -- Cas P + N + N = Z avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_N and c_in = TRIT_N then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas P + N + Z = Z avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_N and c_in = TRIT_Z then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas P + N + P = P avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_N and c_in = TRIT_P then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas P + Z + N = Z avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_Z and c_in = TRIT_N then
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        
        -- Cas P + Z + Z = P avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_Z and c_in = TRIT_Z then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas P + Z + P = N avec retenue P
        elsif a_in = TRIT_P and b_in = TRIT_Z and c_in = TRIT_P then
            sum_out <= TRIT_N;
            c_out <= TRIT_P;
        
        -- Cas P + P + N = P avec retenue Z
        elsif a_in = TRIT_P and b_in = TRIT_P and c_in = TRIT_N then
            sum_out <= TRIT_P;
            c_out <= TRIT_Z;
        
        -- Cas P + P + Z = N avec retenue P
        elsif a_in = TRIT_P and b_in = TRIT_P and c_in = TRIT_Z then
            sum_out <= TRIT_N;
            c_out <= TRIT_P;
        
        -- Cas P + P + P = Z avec retenue P
        elsif a_in = TRIT_P and b_in = TRIT_P and c_in = TRIT_P then
            sum_out <= TRIT_Z;
            c_out <= TRIT_P;
        
        -- Cas par défaut (ne devrait jamais arriver)
        else
            sum_out <= TRIT_Z;
            c_out <= TRIT_Z;
        end if;
    end process;
    
end architecture rtl;