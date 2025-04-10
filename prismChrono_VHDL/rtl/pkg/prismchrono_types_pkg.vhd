library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package prismchrono_types_pkg is
    -- Définition de l'encodage binaire des trits
    subtype EncodedTrit is std_logic_vector(1 downto 0);
    
    -- Constantes pour les valeurs ternaires
    constant TRIT_N : EncodedTrit := "00"; -- Négatif (-1)
    constant TRIT_Z : EncodedTrit := "01"; -- Zéro (0)
    constant TRIT_P : EncodedTrit := "10"; -- Positif (+1)
    
    -- Types dérivés pour les structures de données plus larges
    subtype EncodedTryte is std_logic_vector(5 downto 0);   -- 3 trits (3*2 bits)
    subtype EncodedWord is std_logic_vector(47 downto 0);   -- 24 trits (24*2 bits)
    subtype EncodedAddress is std_logic_vector(31 downto 0); -- 16 trits (16*2 bits)
    
    -- Type pour les opérations de l'ALU
    type AluOpType is (OP_ADD, OP_SUB, OP_TMIN, OP_TMAX, OP_TINV, OP_MUL, OP_DIV, OP_MOD,
                      OP_TCMP3, OP_ABS_T, OP_SIGNUM_T, OP_EXTRACT_TRYTE, OP_INSERT_TRYTE);

    -- Constantes pour les opcodes des instructions spécialisées
    constant OPCODE_TERNARY_SPEC : std_logic_vector(6 downto 0) := "0110011"; -- 0x33
    
    -- Constantes pour les champs funct3 des instructions spécialisées
    constant FUNCT3_TCMP3         : std_logic_vector(2 downto 0) := "001";
    constant FUNCT3_ABS_T         : std_logic_vector(2 downto 0) := "010";
    constant FUNCT3_SIGNUM_T      : std_logic_vector(2 downto 0) := "011";
    constant FUNCT3_EXTRACT_TRYTE : std_logic_vector(2 downto 0) := "100";
    constant FUNCT3_INSERT_TRYTE  : std_logic_vector(2 downto 0) := "101";
    
    -- Constante pour le champ funct7 des instructions spécialisées
    constant FUNCT7_TERNARY_SPEC : std_logic_vector(6 downto 0) := "0100000"; -- 0x20
    
    -- Type pour les flags de l'ALU
    subtype FlagBusType is std_logic_vector(4 downto 0);
    
    -- Constantes pour les indices des flags
    constant FLAG_Z_IDX : integer := 0; -- Zero Flag
    constant FLAG_S_IDX : integer := 1; -- Sign Flag
    constant FLAG_O_IDX : integer := 2; -- Overflow Flag
    constant FLAG_C_IDX : integer := 3; -- Carry Flag
    constant FLAG_X_IDX : integer := 4; -- Extended Flag (pour états spéciaux)
    
    -- Type pour le tableau de registres
    type RegArrayType is array (natural range <>) of EncodedWord;
    
    -- Types pour l'unité de contrôle et le décodeur d'instructions
    -- États de la machine à états finis (FSM)
    type FsmStateType is (
        RESET,          -- État initial après reset
        FETCH,          -- Récupération de l'instruction
        DECODE,         -- Décodage de l'instruction
        EXEC_NOP,       -- Exécution de NOP
        EXEC_ADDI,      -- Exécution de ADDI
        EXEC_ALU_R,     -- Exécution des instructions ALU format R
        EXEC_ALU_I,     -- Exécution des instructions ALU format I
        EXEC_CSR,       -- Exécution des instructions CSR
        EXEC_JAL,       -- Exécution de JAL (saut et lien)
        EXEC_JALR,      -- Exécution de JALR (saut et lien via registre)
        EXEC_BRANCH,    -- Exécution de BRANCH (branchement conditionnel)
        EXEC_MUL_INIT,  -- Initialisation de la multiplication
        EXEC_MUL_COMPUTE, -- Calcul de la multiplication (multi-cycles)
        EXEC_DIV_INIT,  -- Initialisation de la division
        EXEC_DIV_COMPUTE, -- Calcul de la division (multi-cycles)
        WB_ADDI,        -- Write-back pour ADDI
        WB_REG,         -- Write-back pour les registres
        WB_CSR,         -- Write-back pour les CSR
        WB_JAL,         -- Write-back pour JAL (écriture de PC+4 dans Rd)
        WB_JALR,        -- Write-back pour JALR (écriture de PC+4 dans Rd)
        WB_MUL,         -- Write-back pour MUL
        WB_DIV,         -- Write-back pour DIV
        MEM_READ,       -- Accès mémoire en lecture
        MEM_WRITE,      -- Accès mémoire en écriture
        MEM_WAIT,       -- Attente de la mémoire
        HALTED          -- CPU arrêté (après instruction HALT)
    );
    
    -- Opcodes des instructions
    subtype OpcodeType is std_logic_vector(5 downto 0); -- 3 trits
    
    -- Constantes pour les opcodes
    constant OPCODE_NOP      : OpcodeType := "010101"; -- ZZZ (000)
    constant OPCODE_HALT     : OpcodeType := "000000"; -- NNN (-13)
    constant OPCODE_ADDI     : OpcodeType := "100000"; -- PNN (-4)
    constant OPCODE_ADD      : OpcodeType := "100001"; -- PNN (-3)
    constant OPCODE_SUB      : OpcodeType := "100010"; -- PNN (-2)
    constant OPCODE_TMIN     : OpcodeType := "100100"; -- PNZ (-1)
    constant OPCODE_TMAX     : OpcodeType := "100101"; -- PNZ (0)
    constant OPCODE_TINV     : OpcodeType := "100110"; -- PNZ (1)
    constant OPCODE_TMINI    : OpcodeType := "101000"; -- PNP (-4)
    constant OPCODE_TMAXI    : OpcodeType := "101001"; -- PNP (-3)
    constant OPCODE_MUL      : OpcodeType := "101010"; -- PNP (-2) - Multiplication
    constant OPCODE_DIV      : OpcodeType := "101011"; -- PNP (-1) - Division
    constant OPCODE_MOD      : OpcodeType := "101100"; -- PNP (0)  - Modulo
    constant OPCODE_TCMP3    : OpcodeType := "101101"; -- PNP (1)  - Comparaison ternaire directe
    constant OPCODE_ABS_T    : OpcodeType := "101110"; -- PNP (2)  - Valeur absolue ternaire
    constant OPCODE_SIGNUM_T : OpcodeType := "101111"; -- PNP (3)  - Extraction de signe ternaire
    constant OPCODE_CSRRW_T  : OpcodeType := "110000"; -- PPZ (-4)
    constant OPCODE_CSRRS_T  : OpcodeType := "110001"; -- PPZ (-3)
    constant OPCODE_CSRRC_T  : OpcodeType := "110010"; -- PPZ (-2)
    constant OPCODE_CMP      : OpcodeType := "100011"; -- PNN (-1) - Comparaison (pour les branchements)
    constant OPCODE_JAL      : OpcodeType := "010000"; -- ZNN (-4) - Jump And Link
    constant OPCODE_JALR     : OpcodeType := "010001"; -- ZNN (-3) - Jump And Link Register
    constant OPCODE_BRANCH   : OpcodeType := "010010"; -- ZNN (-2) - Branchement conditionnel
    constant OPCODE_ECALL    : OpcodeType := "001000"; -- NZN (-5) - Environment Call
    constant OPCODE_EBREAK   : OpcodeType := "001001"; -- NZN (-4) - Environment Break
    
    -- Type pour les formats d'instruction
    type InstructionFormatType is (R_TYPE, I_TYPE, S_TYPE, B_TYPE, U_TYPE, J_TYPE, CSR_TYPE);
    
    -- Type pour les conditions de branchement
    subtype BranchCondType is std_logic_vector(5 downto 0); -- 3 trits
    
    -- Constantes pour les conditions de branchement
    constant COND_EQ   : BranchCondType := "010101"; -- ZZZ (000) - Equal (Zero Flag = 1)
    constant COND_NE   : BranchCondType := "100000"; -- PNN (-4) - Not Equal (Zero Flag = 0)
    constant COND_LT   : BranchCondType := "100001"; -- PNN (-3) - Less Than (Sign Flag = 1)
    constant COND_GE   : BranchCondType := "100010"; -- PNN (-2) - Greater or Equal (Sign Flag = 0)
    constant COND_LTU  : BranchCondType := "100011"; -- PNN (-1) - Less Than Unsigned
    constant COND_GEU  : BranchCondType := "100100"; -- PNZ (-1) - Greater or Equal Unsigned
    constant COND_BOF  : BranchCondType := "100101"; -- PNZ (0)  - Branch on Overflow
    constant COND_BCF  : BranchCondType := "100110"; -- PNZ (1)  - Branch on Carry
    constant COND_BSPEC : BranchCondType := "101000"; -- PNP (-4) - Branch on Special State
    constant COND_B    : BranchCondType := "101001"; -- PNP (-3) - Unconditional Branch

    -- Types pour les niveaux de privilège
    subtype PrivilegeModeType is std_logic_vector(1 downto 0);
    constant PRIV_U : PrivilegeModeType := "00"; -- User mode
    constant PRIV_S : PrivilegeModeType := "01"; -- Supervisor mode
    constant PRIV_M : PrivilegeModeType := "11"; -- Machine mode

    -- Constantes pour les adresses des CSRs
    -- CSRs Machine Mode (M-mode)
    constant CSR_MSTATUS   : std_logic_vector(11 downto 0) := X"300"; -- Machine status
    constant CSR_MISA      : std_logic_vector(11 downto 0) := X"301"; -- Machine ISA
    constant CSR_MEDELEG   : std_logic_vector(11 downto 0) := X"302"; -- Machine exception delegation
    constant CSR_MIDELEG   : std_logic_vector(11 downto 0) := X"303"; -- Machine interrupt delegation
    constant CSR_MIE       : std_logic_vector(11 downto 0) := X"304"; -- Machine interrupt enable
    constant CSR_MTVEC     : std_logic_vector(11 downto 0) := X"305"; -- Machine trap vector
    constant CSR_MEPC      : std_logic_vector(11 downto 0) := X"341"; -- Machine exception PC
    constant CSR_MCAUSE    : std_logic_vector(11 downto 0) := X"342"; -- Machine cause
    
    -- CSRs Supervisor Mode (S-mode)
    constant CSR_SSTATUS   : std_logic_vector(11 downto 0) := X"100"; -- Supervisor status
    constant CSR_SIE       : std_logic_vector(11 downto 0) := X"104"; -- Supervisor interrupt enable
    constant CSR_STVEC     : std_logic_vector(11 downto 0) := X"105"; -- Supervisor trap vector
    constant CSR_SEPC      : std_logic_vector(11 downto 0) := X"141"; -- Supervisor exception PC
    constant CSR_SCAUSE    : std_logic_vector(11 downto 0) := X"142"; -- Supervisor cause
    constant CSR_SATP      : std_logic_vector(11 downto 0) := X"180"; -- Supervisor address translation

    -- Bits de contrôle pour les registres de statut
    constant MSTATUS_MIE  : integer := 3;  -- Machine interrupt enable
    constant MSTATUS_MPIE : integer := 7;  -- Previous machine interrupt enable
    constant MSTATUS_MPP  : integer := 11; -- Previous privilege mode (M)
    constant SSTATUS_SIE  : integer := 1;  -- Supervisor interrupt enable
    constant SSTATUS_SPIE : integer := 5;  -- Previous supervisor interrupt enable
    constant SSTATUS_SPP  : integer := 8;  -- Previous privilege mode (S)
    constant COND_GE  : BranchCondType := "100001"; -- PZN (4)  - Greater or Equal (Sign Flag = 0 | Zero Flag = 1)
    constant COND_LTU : BranchCondType := "000010"; -- NZN (-4) - Less Than Unsigned (Carry Flag = 1)
    constant COND_GEU : BranchCondType := "100010"; -- PZN (5)  - Greater or Equal Unsigned (Carry Flag = 0)
    constant COND_BOF : BranchCondType := "000100"; -- NZZ (-3) - Branch on Overflow (Overflow Flag = 1)
    constant COND_BCF : BranchCondType := "001000"; -- NZP (-1) - Branch on Carry (Carry Flag = 1)
    constant COND_BSPEC : BranchCondType := "010000"; -- ZNN (-5) - Branch on Special (Extended Flag = 1)
    constant COND_B   : BranchCondType := "101010"; -- PZP (13) - Branch Always (Unconditional)
    
    -- Type pour les adresses CSR
    subtype CsrAddressType is std_logic_vector(11 downto 0);
    
    -- Constantes pour les adresses CSR
    constant CSR_MSTATUS_ADDR    : CsrAddressType := X"300"; -- Machine status register
    constant CSR_MSCRATCH_ADDR   : CsrAddressType := X"340"; -- Machine scratch register
    constant CSR_MEPC_ADDR       : CsrAddressType := X"341"; -- Machine exception program counter
    constant CSR_MCAUSE_ADDR     : CsrAddressType := X"342"; -- Machine cause register
    constant CSR_MTVEC_ADDR      : CsrAddressType := X"305"; -- Machine trap-handler base address
    
    -- Constantes pour les causes de trap (mcause)
    constant CAUSE_ECALL_U       : std_logic_vector(3 downto 0) := X"8"; -- Environment call from U-mode
    constant CAUSE_ECALL_S       : std_logic_vector(3 downto 0) := X"9"; -- Environment call from S-mode
    constant CAUSE_ECALL_M       : std_logic_vector(3 downto 0) := X"B"; -- Environment call from M-mode
    constant CAUSE_BREAKPOINT    : std_logic_vector(3 downto 0) := X"3"; -- Breakpoint
    
    -- Constantes pour les adresses MMIO UART
    constant UART_BASE_ADDR      : EncodedAddress := X"F0000000"; -- Base address for UART MMIO
    constant UART_TX_DATA_OFFSET : EncodedAddress := X"00000000"; -- Offset for TX data register
    constant UART_RX_DATA_OFFSET : EncodedAddress := X"00000004"; -- Offset for RX data register
    constant UART_STATUS_OFFSET  : EncodedAddress := X"00000008"; -- Offset for status register
    constant UART_CONTROL_OFFSET : EncodedAddress := X"0000000C"; -- Offset for control register
    
    -- Type pour les signaux de contrôle
    type ControlSignalsType is record
        -- Signaux pour le PC
        pc_inc      : std_logic;                    -- Incrémenter le PC
        pc_load     : std_logic;                    -- Charger une nouvelle valeur dans le PC
        pc_src      : std_logic_vector(1 downto 0); -- Source pour le PC (00: PC+1, 01: ALU, 10: immédiat, 11: target)
        
        -- Signaux pour l'ALU
        alu_op      : AluOpType;                    -- Opération ALU
        alu_src_a   : std_logic;                    -- Source A pour l'ALU (0: rs1, 1: PC)
        alu_src_b   : std_logic;                    -- Source B pour l'ALU (0: rs2, 1: immédiat)
        
        -- Signaux pour le banc de registres
        reg_write   : std_logic;                    -- Activer l'écriture dans le banc de registres
        reg_dst     : std_logic_vector(1 downto 0); -- Destination pour l'écriture (00: rd, 01: ra)
        reg_src     : std_logic_vector(1 downto 0); -- Source pour l'écriture (00: ALU, 01: mémoire, 10: PC+1, 11: CSR)
        
        -- Signaux pour le contrôle de flux
        branch_cond : BranchCondType;               -- Condition de branchement
        branch_taken: std_logic;                    -- Indique si le branchement est pris
        
        -- Signaux pour la mémoire
        mem_read    : std_logic;                    -- Activer la lecture mémoire
        mem_write   : std_logic;                    -- Activer l'écriture mémoire
        
        -- Signaux pour les CSR
        csr_read    : std_logic;                    -- Activer la lecture CSR
        csr_write   : std_logic;                    -- Activer l'écriture CSR
        csr_set     : std_logic;                    -- Activer l'opération SET (CSRRS)
        csr_clear   : std_logic;                    -- Activer l'opération CLEAR (CSRRC)
        csr_addr    : CsrAddressType;               -- Adresse du CSR
        
        -- Signaux pour le pipeline
        stall       : std_logic;                    -- Geler le pipeline
        flush       : std_logic;                    -- Vider le pipeline
        
        -- Signaux divers
        halted      : std_logic;                    -- CPU arrêté
    end record;
    
    -- Fonctions de conversion
    function to_integer(t: EncodedTrit) return integer;
    function to_encoded_trit(i: integer) return EncodedTrit;
    
end package prismchrono_types_pkg;

package body prismchrono_types_pkg is
    -- Conversion d'un trit encodé vers un entier
    function to_integer(t: EncodedTrit) return integer is
    begin
        case t is
            when TRIT_N => return -1;
            when TRIT_Z => return 0;
            when TRIT_P => return 1;
            when others => return 0; -- Valeur par défaut pour l'encodage non utilisé "11"
        end case;
    end function;
    
    -- Conversion d'un entier vers un trit encodé
    function to_encoded_trit(i: integer) return EncodedTrit is
    begin
        if i < 0 then
            return TRIT_N;
        elsif i > 0 then
            return TRIT_P;
        else
            return TRIT_Z;
        end if;
    end function;
    
end package body prismchrono_types_pkg;