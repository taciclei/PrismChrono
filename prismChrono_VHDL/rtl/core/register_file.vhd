library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity register_file is
    port (
        clk      : in  std_logic;                     -- Horloge
        rst      : in  std_logic;                     -- Reset asynchrone
        wr_en    : in  std_logic;                     -- Enable d'écriture
        wr_addr  : in  std_logic_vector(2 downto 0);  -- Adresse d'écriture (3 bits pour 8 registres)
        wr_data  : in  EncodedWord;                   -- Données à écrire (24 trits)
        rd_addr1 : in  std_logic_vector(2 downto 0);  -- Adresse de lecture 1
        rd_data1 : out EncodedWord;                   -- Données lues 1
        rd_addr2 : in  std_logic_vector(2 downto 0);  -- Adresse de lecture 2
        rd_data2 : out EncodedWord                    -- Données lues 2
    );
end entity register_file;

architecture rtl of register_file is
    -- Tableau de registres (8 registres de 24 trits chacun)
    signal regs : RegArrayType(0 to 7) := (others => (others => '0'));
    
begin
    -- Processus d'écriture synchrone
    process(clk, rst)
    begin
        if rst = '1' then
            -- Initialisation de tous les registres à zéro au reset
            for i in 0 to 7 loop
                regs(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if wr_en = '1' then
                -- Écriture dans le registre sélectionné
                regs(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;
    
    -- Lecture combinatoire (immédiate) sur les deux ports
    rd_data1 <= regs(to_integer(unsigned(rd_addr1)));
    rd_data2 <= regs(to_integer(unsigned(rd_addr2)));
    
end architecture rtl;