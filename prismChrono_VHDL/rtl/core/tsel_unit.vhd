library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

-- Unité de sélection ternaire rapide (TSEL)
-- Implémente l'instruction TSEL qui sélectionne une valeur parmi trois
-- en fonction d'une condition ternaire
entity tsel_unit is
    port (
        -- Signaux de contrôle
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        tsel_enable     : in  std_logic;                     -- Active la sélection ternaire
        
        -- Entrées
        condition_value : in  std_logic_vector(1 downto 0);  -- Valeur ternaire (N="00", Z="01", P="10")
        value_if_n     : in  std_logic_vector(23 downto 0); -- Valeur si négatif
        value_if_z     : in  std_logic_vector(23 downto 0); -- Valeur si zéro
        value_if_p     : in  std_logic_vector(23 downto 0); -- Valeur si positif
        
        -- Sorties
        result         : out std_logic_vector(23 downto 0); -- Valeur sélectionnée
        valid_out      : out std_logic                      -- Résultat valide
    );
end entity tsel_unit;

architecture rtl of tsel_unit is
    -- Constantes pour l'encodage ternaire
    constant TERNARY_N : std_logic_vector(1 downto 0) := "00"; -- Négatif
    constant TERNARY_Z : std_logic_vector(1 downto 0) := "01"; -- Zéro
    constant TERNARY_P : std_logic_vector(1 downto 0) := "10"; -- Positif
    
    -- Signaux internes
    signal selected_value : std_logic_vector(23 downto 0);
    signal selection_valid : std_logic;
    
begin
    -- Processus de sélection de valeur
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                selected_value <= (others => '0');
                selection_valid <= '0';
            else
                if tsel_enable = '1' then
                    case condition_value is
                        when TERNARY_N =>
                            selected_value <= value_if_n;
                            selection_valid <= '1';
                            
                        when TERNARY_Z =>
                            selected_value <= value_if_z;
                            selection_valid <= '1';
                            
                        when TERNARY_P =>
                            selected_value <= value_if_p;
                            selection_valid <= '1';
                            
                        when others =>
                            selected_value <= (others => '0');
                            selection_valid <= '0';
                    end case;
                else
                    selected_value <= (others => '0');
                    selection_valid <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Assignation des sorties
    result <= selected_value;
    valid_out <= selection_valid;
    
end architecture rtl;