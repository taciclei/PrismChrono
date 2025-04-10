library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

-- Unité de gestion des états spéciaux
-- Implémente les instructions CHECKW_VALID et IS_SPECIAL_TRYTE
entity special_state_unit is
    port (
        -- Signaux de contrôle
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        operation       : in  std_logic_vector(1 downto 0);  -- Type d'opération
        valid_in        : in  std_logic;                     -- Données d'entrée valides
        
        -- Données d'entrée
        input_value    : in  std_logic_vector(23 downto 0); -- Valeur à vérifier
        
        -- Sorties
        result         : out std_logic;                     -- Résultat de la vérification
        valid_out      : out std_logic                      -- Résultat valide
    );
end entity special_state_unit;

architecture rtl of special_state_unit is
    -- Constantes pour les opérations
    constant OP_CHECKW_VALID    : std_logic_vector(1 downto 0) := "00";
    constant OP_IS_SPECIAL      : std_logic_vector(1 downto 0) := "01";
    
    -- Constantes pour les états spéciaux
    constant NAN_PATTERN  : std_logic_vector(5 downto 0) := "111111"; -- Pattern pour NaN
    constant NULL_PATTERN : std_logic_vector(5 downto 0) := "111110"; -- Pattern pour Null
    
    -- Signaux internes
    signal check_result : std_logic;
    
    -- Fonction pour vérifier si un tryte est spécial
    function is_special_tryte(tryte : std_logic_vector(5 downto 0)) return boolean is
    begin
        return tryte = NAN_PATTERN or tryte = NULL_PATTERN;
    end function;
    
begin
    -- Processus principal de vérification
    process(clk)
        variable any_special : boolean;
        variable all_valid : boolean;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                check_result <= '0';
                valid_out <= '0';
            elsif valid_in = '1' then
                any_special := false;
                all_valid := true;
                
                -- Vérifie chaque tryte dans la valeur d'entrée
                for i in 0 to 3 loop
                    if is_special_tryte(input_value((i+1)*6-1 downto i*6)) then
                        any_special := true;
                        all_valid := false;
                    end if;
                end loop;
                
                case operation is
                    when OP_CHECKW_VALID =>
                        check_result <= '1' when all_valid else '0';
                        
                    when OP_IS_SPECIAL =>
                        check_result <= '1' when any_special else '0';
                        
                    when others =>
                        check_result <= '0';
                end case;
                
                valid_out <= '1';
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
    
    -- Assignation de la sortie
    result <= check_result;
    
end architecture rtl;