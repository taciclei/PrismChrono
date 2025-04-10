library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity instruction_decoder is
    port (
        instruction    : in  EncodedWord;                    -- Instruction complète (24 trits)
        opcode         : out OpcodeType;                     -- Opcode (3 trits)
        rd_addr        : out std_logic_vector(2 downto 0);   -- Adresse du registre destination
        rs1_addr       : out std_logic_vector(2 downto 0);   -- Adresse du registre source 1
        rs2_addr       : out std_logic_vector(2 downto 0);   -- Adresse du registre source 2
        immediate      : out EncodedWord;                    -- Valeur immédiate (étendue à 24 trits)
        branch_cond    : out BranchCondType;                 -- Condition de branchement (pour BRANCH)
        j_offset       : out EncodedWord;                    -- Offset pour les sauts (JAL)
        b_offset       : out EncodedWord                     -- Offset pour les branchements (BRANCH)
    );
end entity instruction_decoder;

architecture rtl of instruction_decoder is
    -- Signaux internes pour l'extraction des champs
    signal imm_field : std_logic_vector(9 downto 0);  -- Champ immédiat (5 trits) pour format I
    signal j_field   : std_logic_vector(19 downto 0); -- Champ offset (10 trits) pour format J
    signal b_field   : std_logic_vector(15 downto 0); -- Champ offset (8 trits) pour format B
    signal cond_field : std_logic_vector(5 downto 0); -- Champ condition (3 trits) pour format B
    
begin
    -- Extraction de l'opcode (3 premiers trits = 6 bits)
    opcode <= instruction(47 downto 42);
    
    -- Extraction des adresses de registres (chacune sur 3 bits binaires)
    -- Rd est aux trits 3-5 (bits 41-36)
    rd_addr <= instruction(41 downto 39); -- Bits impairs pour simplifier
    
    -- Rs1 est aux trits 6-8 (bits 35-30)
    rs1_addr <= instruction(35 downto 33); -- Bits impairs pour simplifier
    
    -- Rs2 est aux trits 9-11 (bits 29-24)
    rs2_addr <= instruction(29 downto 27); -- Bits impairs pour simplifier
    
    -- Extraction du champ immédiat (5 trits = 10 bits) pour format I
    imm_field <= instruction(29 downto 20);
    
    -- Extraction du champ offset (10 trits = 20 bits) pour format J
    j_field <= instruction(39 downto 20);
    
    -- Extraction du champ condition (3 trits = 6 bits) pour format B
    cond_field <= instruction(35 downto 30);
    
    -- Extraction du champ offset (8 trits = 16 bits) pour format B
    b_field <= instruction(29 downto 14);
    
    -- Assignation directe de la condition de branchement
    branch_cond <= cond_field;
    
    -- Extension de signe pour l'immédiat format I (de 5 trits à 24 trits)
    process(imm_field)
    begin
        -- Par défaut, on initialise tout à zéro
        immediate <= (others => '0');
        
        -- On copie les 5 trits de l'immédiat dans les 5 trits de poids faible
        immediate(9 downto 0) <= imm_field;
        
        -- Extension de signe: on répète le trit de poids fort (bits 9-8)
        -- pour tous les trits de poids fort (du trit 6 au trit 23)
        for i in 5 to 23 loop
            immediate(i*2+1 downto i*2) <= imm_field(9 downto 8);
        end loop;
    end process;
    
    -- Extension de signe pour l'offset format J (de 10 trits à 24 trits)
    process(j_field)
    begin
        -- Par défaut, on initialise tout à zéro
        j_offset <= (others => '0');
        
        -- On copie les 10 trits de l'offset dans les 10 trits de poids faible
        j_offset(19 downto 0) <= j_field;
        
        -- Extension de signe: on répète le trit de poids fort (bits 19-18)
        -- pour tous les trits de poids fort (du trit 10 au trit 23)
        for i in 10 to 23 loop
            j_offset(i*2+1 downto i*2) <= j_field(19 downto 18);
        end loop;
    end process;
    
    -- Extension de signe pour l'offset format B (de 8 trits à 24 trits)
    process(b_field)
    begin
        -- Par défaut, on initialise tout à zéro
        b_offset <= (others => '0');
        
        -- On copie les 8 trits de l'offset dans les 8 trits de poids faible
        b_offset(15 downto 0) <= b_field;
        
        -- Extension de signe: on répète le trit de poids fort (bits 15-14)
        -- pour tous les trits de poids fort (du trit 8 au trit 23)
        for i in 8 to 23 loop
            b_offset(i*2+1 downto i*2) <= b_field(15 downto 14);
        end loop;
    end process;
    
end architecture rtl;