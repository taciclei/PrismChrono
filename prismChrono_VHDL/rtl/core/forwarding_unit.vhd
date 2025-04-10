library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity forwarding_unit is
    port (
        -- Registres sources étage EX
        id_ex_rs1     : in  std_logic_vector(4 downto 0);
        id_ex_rs2     : in  std_logic_vector(4 downto 0);
        
        -- Registre destination étages MEM et WB
        ex_mem_rd     : in  std_logic_vector(4 downto 0);
        mem_wb_rd     : in  std_logic_vector(4 downto 0);
        ex_mem_regwrite : in  std_logic;
        mem_wb_regwrite : in  std_logic;
        
        -- Signaux de forwarding
        forward_a     : out std_logic_vector(1 downto 0);
        forward_b     : out std_logic_vector(1 downto 0)
    );
end entity forwarding_unit;

architecture rtl of forwarding_unit is
begin
    -- Logique de forwarding pour l'entrée A de l'ALU
    forward_a_process : process(id_ex_rs1, ex_mem_rd, mem_wb_rd, ex_mem_regwrite, mem_wb_regwrite)
    begin
        -- Par défaut, pas de forwarding
        forward_a <= "00";
        
        -- Forwarding depuis l'étage MEM
        if (ex_mem_regwrite = '1' and ex_mem_rd /= "00000" and
            ex_mem_rd = id_ex_rs1) then
            forward_a <= "10";
        -- Forwarding depuis l'étage WB
        elsif (mem_wb_regwrite = '1' and mem_wb_rd /= "00000" and
               mem_wb_rd = id_ex_rs1) then
            forward_a <= "01";
        end if;
    end process;
    
    -- Logique de forwarding pour l'entrée B de l'ALU
    forward_b_process : process(id_ex_rs2, ex_mem_rd, mem_wb_rd, ex_mem_regwrite, mem_wb_regwrite)
    begin
        -- Par défaut, pas de forwarding
        forward_b <= "00";
        
        -- Forwarding depuis l'étage MEM
        if (ex_mem_regwrite = '1' and ex_mem_rd /= "00000" and
            ex_mem_rd = id_ex_rs2) then
            forward_b <= "10";
        -- Forwarding depuis l'étage WB
        elsif (mem_wb_regwrite = '1' and mem_wb_rd /= "00000" and
               mem_wb_rd = id_ex_rs2) then
            forward_b <= "01";
        end if;
    end process;
    
end architecture rtl;