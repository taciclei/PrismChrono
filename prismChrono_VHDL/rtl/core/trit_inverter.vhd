library ieee;
use ieee.std_logic_1164.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity trit_inverter is
    port (
        trit_in  : in  EncodedTrit;
        trit_out : out EncodedTrit
    );
end entity trit_inverter;

architecture rtl of trit_inverter is
begin
    -- Logique combinatoire pour l'inversion ternaire
    -- N -> P, P -> N, Z -> Z
    process(trit_in)
    begin
        case trit_in is
            when TRIT_N => trit_out <= TRIT_P;
            when TRIT_Z => trit_out <= TRIT_Z;
            when TRIT_P => trit_out <= TRIT_N;
            when others => trit_out <= trit_in; -- Pour l'encodage non utilisé "11"
        end case;
    end process;
    
end architecture rtl;