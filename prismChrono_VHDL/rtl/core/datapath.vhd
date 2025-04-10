library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity datapath is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        control_signals : in  ControlSignalsType;            -- Signaux de contrôle
        instr_data      : in  EncodedWord;                   -- Données d'instruction de la mémoire
        mem_data_in     : in  EncodedWord;                   -- Données de la mémoire (lecture)
        opcode          : out OpcodeType;                    -- Opcode pour l'unité de contrôle
        flags           : out FlagBusType;                   -- Flags de l'ALU
        pc_out          : out EncodedAddress;                -- Adresse du PC (pour la mémoire d'instructions)
        mem_addr        : out EncodedAddress;                -- Adresse mémoire (pour la mémoire de données)
        mem_data_out    : out EncodedWord;                   -- Données pour la mémoire (écriture)
        branch_cond     : out BranchCondType                 -- Condition de branchement pour l'unité de contrôle
    );
end entity datapath;

architecture rtl of datapath is
    -- Composant ALU
    component alu_24t is
        port (
            op_a    : in  EncodedWord;     -- Premier opérande (24 trits)
            op_b    : in  EncodedWord;     -- Second opérande (24 trits)
            alu_op  : in  AluOpType;       -- Opération à effectuer
            c_in    : in  EncodedTrit;     -- Retenue d'entrée
            result  : out EncodedWord;     -- Résultat (24 trits)
            flags   : out FlagBusType;     -- Flags (ZF, SF, OF, CF, XF)
            c_out   : out EncodedTrit      -- Retenue de sortie
        );
    end component;
    
    -- Composant banc de registres
    component register_file is
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
    end component;
    
    -- Composant décodeur d'instructions
    component instruction_decoder is
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
    end component;
    
    -- Signaux pour le PC (Program Counter)
    signal pc_reg : EncodedAddress := (others => '0');
    signal pc_next : EncodedAddress;
    signal pc_plus_one : EncodedAddress;
    
    -- Signaux pour la mémoire
    signal mem_addr_internal : EncodedAddress := (others => '0');
    signal mem_data_out_internal : EncodedWord := (others => '0');
    
    -- Signaux pour le décodeur d'adresse MMIO
    signal bram_access : std_logic := '0';
    signal uart_access : std_logic := '0';
    
    -- Signaux pour le registre d'instruction (IR)
    signal ir_reg : EncodedWord := (others => '0');
    
    -- Signaux pour le décodeur d'instructions
    signal rd_addr : std_logic_vector(2 downto 0);
    signal rs1_addr : std_logic_vector(2 downto 0);
    signal rs2_addr : std_logic_vector(2 downto 0);
    signal immediate : EncodedWord;
    signal j_offset : EncodedWord;
    signal b_offset : EncodedWord;
    signal branch_condition : BranchCondType;
    
    -- Signaux pour le calcul d'adresse cible
    signal jal_target : EncodedAddress;
    signal jalr_target : EncodedAddress;
    signal branch_target : EncodedAddress;
    signal target_address : EncodedAddress;
    
    -- Signaux pour le banc de registres
    signal reg_wr_addr : std_logic_vector(2 downto 0);
    signal reg_wr_data : EncodedWord;
    signal reg_rd_data1 : EncodedWord;
    signal reg_rd_data2 : EncodedWord;
    
    -- Signaux pour l'ALU
    signal alu_op_a : EncodedWord;
    signal alu_op_b : EncodedWord;
    signal alu_result : EncodedWord;
    signal alu_c_out : EncodedTrit;
    
    -- Constante pour la retenue d'entrée de l'ALU (initialement à zéro)
    constant ALU_C_IN : EncodedTrit := TRIT_Z;
    
begin
    -- Instanciation du décodeur d'instructions
    inst_decoder : instruction_decoder
        port map (
            instruction => ir_reg,
            opcode      => opcode,
            rd_addr     => rd_addr,
            rs1_addr    => rs1_addr,
            rs2_addr    => rs2_addr,
            immediate   => immediate,
            branch_cond => branch_condition,
            j_offset    => j_offset,
            b_offset    => b_offset
        );
    
    -- Instanciation du banc de registres
    inst_register_file : register_file
        port map (
            clk      => clk,
            rst      => rst,
            wr_en    => control_signals.reg_write,
            wr_addr  => reg_wr_addr,
            wr_data  => reg_wr_data,
            rd_addr1 => rs1_addr,
            rd_data1 => reg_rd_data1,
            rd_addr2 => rs2_addr,
            rd_data2 => reg_rd_data2
        );
    
    -- Instanciation de l'ALU
    inst_alu : alu_24t
        port map (
            op_a    => alu_op_a,
            op_b    => alu_op_b,
            alu_op  => control_signals.alu_op,
            c_in    => ALU_C_IN,
            result  => alu_result,
            flags   => flags,
            c_out   => alu_c_out
        );
    
    -- Processus pour le PC (Program Counter)
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation du PC
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Mise à jour du PC
            pc_reg <= pc_next;
        end if;
    end process;
    
    -- Calcul du prochain PC et des adresses cibles
    pc_plus_one <= std_logic_vector(unsigned(pc_reg) + 1);
    
    -- Calcul de l'adresse cible pour JAL (PC + offset*4)
    -- Multiplication par 4 en décalant de 2 bits (équivalent à *4)
    jal_target <= std_logic_vector(unsigned(pc_reg) + unsigned(j_offset(29 downto 0) & "00"));
    
    -- Calcul de l'adresse cible pour JALR ((rs1 + offset) & AlignMask(4))
    -- Alignement sur 4 octets en mettant les 2 bits de poids faible à 0
    jalr_target <= std_logic_vector(unsigned(reg_rd_data1(31 downto 0)) + unsigned(immediate(31 downto 0))) and X"FFFFFFFC";
    
    -- Calcul de l'adresse cible pour BRANCH (PC + offset*4)
    branch_target <= std_logic_vector(unsigned(pc_reg) + unsigned(b_offset(29 downto 0) & "00"));
    
    -- Multiplexeur pour l'adresse cible
    process(control_signals.pc_src, jal_target, jalr_target, branch_target)
    begin
        case control_signals.pc_src is
            when "10" => target_address <= jal_target;    -- JAL
            when "01" => target_address <= jalr_target;   -- JALR
            when others => target_address <= branch_target; -- BRANCH
        end case;
    end process;
    
    -- Multiplexeur pour le prochain PC
    process(control_signals, pc_plus_one, target_address)
    begin
        if control_signals.pc_load = '1' then
            -- Chargement d'une nouvelle valeur dans le PC
            case control_signals.pc_src is
                when "00" => pc_next <= pc_plus_one;
                when others => pc_next <= target_address; -- Adresse cible (JAL, JALR ou BRANCH)
            end case;
        elsif control_signals.pc_inc = '1' then
            -- Incrémentation du PC
            pc_next <= pc_plus_one;
        else
            -- Maintien du PC
            pc_next <= pc_reg;
        end if;
    end process;
    
    -- Processus pour le registre d'instruction (IR)
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'IR
            ir_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Mise à jour de l'IR pendant la phase de fetch
            if control_signals.mem_read = '1' then
                ir_reg <= instr_data;
            end if;
        end if;
    end process;
    
    -- Multiplexeur pour l'adresse d'écriture du banc de registres
    process(control_signals, rd_addr)
    begin
        case control_signals.reg_dst is
            when "00" => reg_wr_addr <= rd_addr; -- Registre destination de l'instruction
            when others => reg_wr_addr <= "111"; -- Registre ra (pour les appels de fonction)
        end case;
    end process;
    
    -- Multiplexeur pour les données d'écriture du banc de registres
    process(control_signals, alu_result, mem_data_in, pc_plus_one)
    begin
        case control_signals.reg_src is
            when "00" => reg_wr_data <= alu_result; -- Résultat de l'ALU
            when "01" => reg_wr_data <= mem_data_in; -- Données de la mémoire
            when "10" => reg_wr_data <= (31 downto 0 => pc_plus_one, others => '0'); -- PC+1 (pour JAL/JALR)
            when others => reg_wr_data <= (others => '0'); -- Valeur par défaut
        end case;
    end process;
    
    -- Multiplexeur pour l'opérande A de l'ALU
    process(control_signals, reg_rd_data1, pc_reg)
    begin
        if control_signals.alu_src_a = '0' then
            alu_op_a <= reg_rd_data1; -- Registre source 1
        else
            alu_op_a <= (31 downto 0 => pc_reg, others => '0'); -- PC (pour les calculs d'adresse)
        end if;
    end process;
    
    -- Multiplexeur pour l'opérande B de l'ALU
    process(control_signals, reg_rd_data2, immediate)
    begin
        if control_signals.alu_src_b = '0' then
            alu_op_b <= reg_rd_data2; -- Registre source 2
        else
            alu_op_b <= immediate; -- Valeur immédiate
        end if;
    end process;
    
    -- Décodeur d'adresse pour MMIO
    process(alu_result)
    begin
        -- Par défaut, accès à la BRAM
        bram_access <= '0';
        uart_access <= '0';
        
        -- Vérification de la plage d'adresses UART
        if alu_result(31 downto 0) >= UART_BASE_ADDR then
            uart_access <= '1';
        else
            bram_access <= '1';
        end if;
    end process;
    
    -- Calcul de l'adresse relative pour l'UART
    mem_addr_internal <= alu_result(31 downto 0) - UART_BASE_ADDR when uart_access = '1' else
                         alu_result(31 downto 0);
    
    -- Assignation des sorties
    pc_out <= pc_reg;  -- Adresse du PC pour la mémoire d'instructions
    mem_addr <= mem_addr_internal;  -- Adresse mémoire calculée (avec décodage MMIO)
    mem_data_out <= reg_rd_data2; -- Données pour la mémoire = registre source 2
    branch_cond <= branch_condition; -- Condition de branchement pour l'unité de contrôle
    
end architecture rtl;