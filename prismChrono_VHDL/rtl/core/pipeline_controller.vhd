library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity pipeline_controller is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        -- Interface avec le cœur du processeur
        instr_addr      : in  EncodedAddress;                -- Adresse d'instruction demandée
        instr_data      : out EncodedWord;                   -- Instruction décodée
        instr_ready     : out std_logic;                     -- Signal indiquant que l'instruction est prête
        -- Interface avec la mémoire d'instructions
        mem_instr_addr  : out EncodedAddress;                -- Adresse pour la mémoire d'instructions
        mem_instr_data  : in  EncodedWord;                   -- Données de la mémoire d'instructions
        mem_instr_ready : in  std_logic;                     -- Signal indiquant que la mémoire d'instructions est prête
        -- Signaux de contrôle du pipeline
        stall           : in  std_logic;                     -- Signal pour geler le pipeline
        flush           : in  std_logic;                     -- Signal pour vider le pipeline
        branch_taken    : in  std_logic;                     -- Signal indiquant qu'un branchement est pris
        branch_target   : in  EncodedAddress                 -- Adresse cible du branchement
    );
end entity pipeline_controller;

architecture rtl of pipeline_controller is
    -- Types pour les étages du pipeline
    type PipelineStageType is (
        FETCH,          -- Récupération de l'instruction
        DECODE,         -- Décodage de l'instruction
        EXECUTE,        -- Exécution de l'instruction
        MEMORY,         -- Accès mémoire
        WRITEBACK       -- Écriture des résultats
    );
    
    -- Registres du pipeline
    type FetchDecodeRegType is record
        valid       : std_logic;                     -- Indique si l'étage contient une instruction valide
        pc          : EncodedAddress;                -- Adresse de l'instruction
        instruction : EncodedWord;                   -- Instruction complète
    end record;
    
    type DecodeExecuteRegType is record
        valid       : std_logic;                     -- Indique si l'étage contient une instruction valide
        pc          : EncodedAddress;                -- Adresse de l'instruction
        opcode      : OpcodeType;                    -- Opcode de l'instruction
        rd_addr     : std_logic_vector(2 downto 0);  -- Adresse du registre destination
        rs1_addr    : std_logic_vector(2 downto 0);  -- Adresse du registre source 1
        rs2_addr    : std_logic_vector(2 downto 0);  -- Adresse du registre source 2
        immediate   : EncodedWord;                   -- Valeur immédiate
    end record;
    
    type ExecuteMemoryRegType is record
        valid       : std_logic;                     -- Indique si l'étage contient une instruction valide
        pc          : EncodedAddress;                -- Adresse de l'instruction
        opcode      : OpcodeType;                    -- Opcode de l'instruction
        rd_addr     : std_logic_vector(2 downto 0);  -- Adresse du registre destination
        result      : EncodedWord;                   -- Résultat de l'ALU
        mem_addr    : EncodedAddress;                -- Adresse mémoire
        mem_data    : EncodedWord;                   -- Données pour la mémoire
    end record;
    
    type MemoryWritebackRegType is record
        valid       : std_logic;                     -- Indique si l'étage contient une instruction valide
        rd_addr     : std_logic_vector(2 downto 0);  -- Adresse du registre destination
        result      : EncodedWord;                   -- Résultat à écrire dans le registre
    end record;
    
    -- Signaux internes pour les registres du pipeline
    signal fd_reg  : FetchDecodeRegType := (valid => '0', pc => (others => '0'), instruction => (others => '0'));
    signal de_reg  : DecodeExecuteRegType := (valid => '0', pc => (others => '0'), opcode => (others => '0'),
                                             rd_addr => (others => '0'), rs1_addr => (others => '0'),
                                             rs2_addr => (others => '0'), immediate => (others => '0'));
    signal em_reg  : ExecuteMemoryRegType := (valid => '0', pc => (others => '0'), opcode => (others => '0'),
                                             rd_addr => (others => '0'), result => (others => '0'),
                                             mem_addr => (others => '0'), mem_data => (others => '0'));
    signal mw_reg  : MemoryWritebackRegType := (valid => '0', rd_addr => (others => '0'), result => (others => '0'));
    
    -- Signaux pour la détection des aléas
    signal data_hazard : std_logic := '0';
    signal control_hazard : std_logic := '0';
    
    -- Composant décodeur d'instructions
    component instruction_decoder is
        port (
            instruction    : in  EncodedWord;                    -- Instruction complète (24 trits)
            opcode         : out OpcodeType;                     -- Opcode (3 trits)
            rd_addr        : out std_logic_vector(2 downto 0);   -- Adresse du registre destination
            rs1_addr       : out std_logic_vector(2 downto 0);   -- Adresse du registre source 1
            rs2_addr       : out std_logic_vector(2 downto 0);   -- Adresse du registre source 2
            immediate      : out EncodedWord                     -- Valeur immédiate (étendue à 24 trits)
        );
    end component;
    
    -- Signaux pour le décodeur d'instructions
    signal decode_opcode   : OpcodeType;
    signal decode_rd_addr  : std_logic_vector(2 downto 0);
    signal decode_rs1_addr : std_logic_vector(2 downto 0);
    signal decode_rs2_addr : std_logic_vector(2 downto 0);
    signal decode_immediate: EncodedWord;
    
begin
    -- Instanciation du décodeur d'instructions
    inst_decoder : instruction_decoder
        port map (
            instruction => fd_reg.instruction,
            opcode      => decode_opcode,
            rd_addr     => decode_rd_addr,
            rs1_addr    => decode_rs1_addr,
            rs2_addr    => decode_rs2_addr,
            immediate   => decode_immediate
        );
    
    -- Processus synchrone pour mettre à jour les registres du pipeline
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation des registres du pipeline
            fd_reg <= (valid => '0', pc => (others => '0'), instruction => (others => '0'));
            de_reg <= (valid => '0', pc => (others => '0'), opcode => (others => '0'),
                      rd_addr => (others => '0'), rs1_addr => (others => '0'),
                      rs2_addr => (others => '0'), immediate => (others => '0'));
            em_reg <= (valid => '0', pc => (others => '0'), opcode => (others => '0'),
                      rd_addr => (others => '0'), result => (others => '0'),
                      mem_addr => (others => '0'), mem_data => (others => '0'));
            mw_reg <= (valid => '0', rd_addr => (others => '0'), result => (others => '0'));
        elsif rising_edge(clk) then
            -- Mise à jour des registres du pipeline si pas de gel
            if stall = '0' then
                -- Étage Fetch -> Decode
                if flush = '1' or branch_taken = '1' then
                    -- Vider l'étage en cas de flush ou de branchement
                    fd_reg.valid <= '0';
                elsif mem_instr_ready = '1' then
                    -- Récupération de l'instruction
                    fd_reg.valid <= '1';
                    fd_reg.pc <= instr_addr;
                    fd_reg.instruction <= mem_instr_data;
                end if;
                
                -- Étage Decode -> Execute
                if flush = '1' then
                    -- Vider l'étage en cas de flush
                    de_reg.valid <= '0';
                else
                    -- Transfert des informations décodées
                    de_reg.valid <= fd_reg.valid and not control_hazard;
                    de_reg.pc <= fd_reg.pc;
                    de_reg.opcode <= decode_opcode;
                    de_reg.rd_addr <= decode_rd_addr;
                    de_reg.rs1_addr <= decode_rs1_addr;
                    de_reg.rs2_addr <= decode_rs2_addr;
                    de_reg.immediate <= decode_immediate;
                end if;
                
                -- Étage Execute -> Memory
                if flush = '1' then
                    -- Vider l'étage en cas de flush
                    em_reg.valid <= '0';
                else
                    -- Transfert des résultats de l'exécution
                    em_reg.valid <= de_reg.valid;
                    em_reg.pc <= de_reg.pc;
                    em_reg.opcode <= de_reg.opcode;
                    em_reg.rd_addr <= de_reg.rd_addr;
                    -- Les signaux result, mem_addr et mem_data seraient normalement
                    -- mis à jour par l'ALU et le datapath
                end if;
                
                -- Étage Memory -> Writeback
                if flush = '1' then
                    -- Vider l'étage en cas de flush
                    mw_reg.valid <= '0';
                else
                    -- Transfert des résultats de l'accès mémoire
                    mw_reg.valid <= em_reg.valid;
                    mw_reg.rd_addr <= em_reg.rd_addr;
                    -- Le signal result serait normalement mis à jour en fonction
                    -- du résultat de l'ALU ou de la lecture mémoire
                end if;
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour la détection des aléas de données
    process(de_reg, em_reg, mw_reg, decode_rs1_addr, decode_rs2_addr)
    begin
        -- Par défaut, pas d'aléa
        data_hazard <= '0';
        
        -- Vérification des dépendances de données
        -- Si une instruction en cours d'exécution écrit dans un registre
        -- qui est lu par l'instruction en cours de décodage
        if de_reg.valid = '1' and de_reg.rd_addr /= "000" then
            if de_reg.rd_addr = decode_rs1_addr or de_reg.rd_addr = decode_rs2_addr then
                data_hazard <= '1';
            end if;
        end if;
        
        if em_reg.valid = '1' and em_reg.rd_addr /= "000" then
            if em_reg.rd_addr = decode_rs1_addr or em_reg.rd_addr = decode_rs2_addr then
                data_hazard <= '1';
            end if;
        end if;
    end process;
    
    -- Processus combinatoire pour la détection des aléas de contrôle
    process(branch_taken)
    begin
        -- Aléa de contrôle si un branchement est pris
        control_hazard <= branch_taken;
    end process;
    
    -- Connexion des signaux de sortie
    instr_data <= fd_reg.instruction;
    instr_ready <= fd_reg.valid;
    
    -- Connexion des signaux vers la mémoire d'instructions
    mem_instr_addr <= instr_addr;
    
end architecture rtl;