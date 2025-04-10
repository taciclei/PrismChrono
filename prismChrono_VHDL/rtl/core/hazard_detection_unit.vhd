library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity hazard_detection_unit is
    port (
        -- Registres sources étage ID
        if_id_rs1     : in  std_logic_vector(4 downto 0);
        if_id_rs2     : in  std_logic_vector(4 downto 0);
        
        -- Registre destination étage EX
        id_ex_rd      : in  std_logic_vector(4 downto 0);
        id_ex_memread : in  std_logic;
        
        -- Contrôle branchement
        branch_taken  : in  std_logic;
        
        -- Signaux de contrôle pipeline
        load_use_hazard : out std_logic;
        branch_hazard   : out std_logic
    );
end entity hazard_detection_unit;

architecture rtl of hazard_detection_unit is
begin
    -- Détection des aléas Load-Use
    load_use_detection : process(if_id_rs1, if_id_rs2, id_ex_rd, id_ex_memread)
    begin
        -- Par défaut, pas d'aléa
        load_use_hazard <= '0';
        
        -- Détection aléa Load-Use
        if (id_ex_memread = '1' and
            (id_ex_rd = if_id_rs1 or id_ex_rd = if_id_rs2)) then
            load_use_hazard <= '1';
        end if;
    end process;
    
    -- Détection des aléas de contrôle (branchements)
    branch_detection : process(branch_taken)
    begin
        -- Par défaut, pas d'aléa
        branch_hazard <= '0';
        
        -- Si branchement pris, flush nécessaire
        if (branch_taken = '1') then
            branch_hazard <= '1';
        end if;
    end process;
    
end architecture rtl;