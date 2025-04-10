library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;
use work.prismchrono_tau_pkg.all;

-- Unité de branchement ternaire (BRANCH3)
-- Implémente le mécanisme de branchement à 3 voies basé sur les résultats ternaires
entity branch3_unit is
    port (
        -- Signaux de contrôle
        clk             : in  std_logic;
        rst_n           : in  std_logic;
        branch3_enable  : in  std_logic;                     -- Active le branchement ternaire
        
        -- Entrées de condition
        condition_value : in  std_logic_vector(1 downto 0);  -- Valeur ternaire (N="00", Z="01", P="10")
        
        -- Adresses de branchement
        addr_if_n      : in  std_logic_vector(31 downto 0); -- Adresse si négatif
        addr_if_z      : in  std_logic_vector(31 downto 0); -- Adresse si zéro
        addr_if_p      : in  std_logic_vector(31 downto 0); -- Adresse si positif
        next_pc        : in  std_logic_vector(31 downto 0); -- PC+4 (adresse suivante)
        
        -- Sorties
        branch_taken   : out std_logic;                     -- Branchement pris
        target_address : out std_logic_vector(31 downto 0)  -- Adresse cible
    );
end entity branch3_unit;

architecture rtl of branch3_unit is
    -- Constantes pour l'encodage ternaire
    constant TERNARY_N : std_logic_vector(1 downto 0) := "00"; -- Négatif
    constant TERNARY_Z : std_logic_vector(1 downto 0) := "01"; -- Zéro
    constant TERNARY_P : std_logic_vector(1 downto 0) := "10"; -- Positif
    
    -- Signaux internes
    signal selected_address : std_logic_vector(31 downto 0);
    signal branch_decision : std_logic;
    
begin
    -- Processus de sélection d'adresse et de décision de branchement
    process(clk)
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                selected_address <= (others => '0');
                branch_decision <= '0';
            else
                if branch3_enable = '1' then
                    case condition_value is
                        when TERNARY_N =>
                            selected_address <= addr_if_n;
                            branch_decision <= '1';
                            
                        when TERNARY_Z =>
                            selected_address <= addr_if_z;
                            branch_decision <= '1';
                            
                        when TERNARY_P =>
                            selected_address <= addr_if_p;
                            branch_decision <= '1';
                            
                        when others =>
                            selected_address <= next_pc;
                            branch_decision <= '0';
                    end case;
                else
                    selected_address <= next_pc;
                    branch_decision <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Assignation des sorties
    branch_taken <= branch_decision;
    target_address <= selected_address;
    
end architecture rtl;