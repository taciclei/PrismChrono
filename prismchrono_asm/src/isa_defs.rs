//! Définitions de l'ISA PrismChrono
//!
//! Ce module contient les constantes et définitions liées à l'ISA PrismChrono,
//! comme les opcodes, les formats d'instructions, etc.

use crate::core_types::Trit;

/// Taille d'une instruction standard en trits
pub const INSTRUCTION_SIZE_TRITS: usize = 12;

/// Taille d'une instruction compacte en trits
pub const COMPACT_INSTRUCTION_SIZE_TRITS: usize = 8;

/// Taille d'une instruction en octets (pour le calcul des adresses)
pub const INSTRUCTION_SIZE_BYTES: u32 = 4;

/// Taille d'une instruction compacte en octets
pub const COMPACT_INSTRUCTION_SIZE_BYTES: u32 = 3;

/// Formats d'instructions
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InstructionFormat {
    /// Format R: opcode[2:0] | func[2:0] | rs2[2:0] | rs1[2:0] | rd[2:0]
    R,
    /// Format I: opcode[2:0] | imm[5:0] | rs1[2:0] | rd[2:0]
    I,
    /// Format S: opcode[2:0] | imm[5:0] | rs2[2:0] | rs1[2:0]
    S,
    /// Format B: opcode[2:0] | imm[2:0] | rs2[2:0] | rs1[2:0] | cond[2:0]
    B,
    /// Format U: opcode[2:0] | imm[8:0] | rd[2:0]
    U,
    /// Format J: opcode[2:0] | imm[8:0] | rd[2:0]
    J,
    /// Format C: op[1:0] | rd/cond[1:0] | rs/offset[3:0] (format compact 8 trits)
    C,
}

/// OpCodes pour les différentes instructions
pub mod opcode {
    use crate::core_types::Trit;

    // OpCodes pour les instructions de base
    pub const NOP: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z]; // 000
    pub const HALT: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P]; // 001
    
    // Format R (ALU)
    pub const R_TYPE: [Trit; 3] = [Trit::Z, Trit::P, Trit::Z]; // 0+0
    
    // Format I
    pub const ADDI: [Trit; 3] = [Trit::Z, Trit::P, Trit::N]; // 0+-
    pub const SUBI: [Trit; 3] = [Trit::Z, Trit::P, Trit::P]; // 0++
    pub const SLTI: [Trit; 3] = [Trit::P, Trit::Z, Trit::P]; // +0+
    pub const MINI: [Trit; 3] = [Trit::P, Trit::P, Trit::Z]; // ++0
    pub const MAXI: [Trit; 3] = [Trit::P, Trit::P, Trit::P]; // +++
    
    // Format I (Loads)
    pub const LOADW: [Trit; 3] = [Trit::N, Trit::Z, Trit::Z]; // -00
    pub const LOADT: [Trit; 3] = [Trit::N, Trit::Z, Trit::P]; // -0+
    pub const LOADTU: [Trit; 3] = [Trit::N, Trit::P, Trit::Z]; // -+0
    
    // Format I (Jump and Link Register)
    pub const JALR: [Trit; 3] = [Trit::P, Trit::N, Trit::P]; // +-+
    
    // Format S (Stores)
    pub const STOREW: [Trit; 3] = [Trit::N, Trit::P, Trit::N]; // -+-
    pub const STORET: [Trit; 3] = [Trit::N, Trit::P, Trit::P]; // -++
    
    // Format B (Branches)
    pub const BRANCH: [Trit; 3] = [Trit::N, Trit::N, Trit::Z]; // --0
    
    // Format U
    pub const LUI: [Trit; 3] = [Trit::P, Trit::Z, Trit::N];  // +0-
    pub const AUIPC: [Trit; 3] = [Trit::P, Trit::Z, Trit::Z]; // +00
    
    // Format J
    pub const JAL: [Trit; 3] = [Trit::P, Trit::N, Trit::N];  // +--
    
    // System & CSR
    pub const SYSTEM: [Trit; 3] = [Trit::N, Trit::N, Trit::N]; // ---
    pub const CSR: [Trit; 3] = [Trit::N, Trit::N, Trit::P]; // --+
    
    // Format C (Compact)
    // Ces opcodes sont sur 2 trits au lieu de 3
    pub mod compact {
        use crate::core_types::Trit;
        
        pub const CMOV: [Trit; 2] = [Trit::N, Trit::N]; // NN (-4)
        pub const CADD: [Trit; 2] = [Trit::N, Trit::Z]; // NZ (-3)
        pub const CSUB: [Trit; 2] = [Trit::N, Trit::P]; // NP (-2)
        pub const CBRANCH: [Trit; 2] = [Trit::Z, Trit::N]; // ZN (-1)
    }
}

/// Fonctions pour les instructions de format R
pub mod func {
    use crate::core_types::Trit;

    // Fonctions pour les instructions arithmétiques
    pub const ADD: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z]; // 000
    pub const SUB: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P]; // 001
    pub const AND: [Trit; 3] = [Trit::Z, Trit::P, Trit::Z]; // 0+0
    pub const OR: [Trit; 3] = [Trit::Z, Trit::P, Trit::P];  // 0++
    pub const XOR: [Trit; 3] = [Trit::P, Trit::Z, Trit::Z];  // +00
    pub const MIN: [Trit; 3] = [Trit::P, Trit::Z, Trit::P];  // +0+
    pub const MAX: [Trit; 3] = [Trit::P, Trit::P, Trit::Z];  // ++0
    pub const SLT: [Trit; 3] = [Trit::P, Trit::P, Trit::P];  // +++
    pub const INV: [Trit; 3] = [Trit::N, Trit::Z, Trit::Z];  // -00
    pub const SLL: [Trit; 3] = [Trit::N, Trit::Z, Trit::P];  // -0+ (Shift Left Logical)
    pub const SRL: [Trit; 3] = [Trit::N, Trit::P, Trit::Z];  // -+0 (Shift Right Logical)
    pub const SRA: [Trit; 3] = [Trit::N, Trit::P, Trit::P];  // -++ (Shift Right Arithmetic)
}

/// Fonctions pour les instructions système
pub mod system_func {
    use crate::core_types::Trit;
    
    pub const ECALL: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z];  // 000
    pub const EBREAK: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P]; // 001
    pub const MRET_T: [Trit; 3] = [Trit::Z, Trit::P, Trit::Z]; // 0+0
}

/// Fonctions pour les instructions CSR
pub mod csr_func {
    use crate::core_types::Trit;
    
    pub const CSRRW_T: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z]; // 000 (CSR Read & Write)
    pub const CSRRS_T: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P]; // 001 (CSR Read & Set)
}

/// Codes CSR
pub mod csr_code {
    use crate::core_types::Trit;
    
    pub const MSTATUS_T: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z]; // 000
    pub const MTVEC_T: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P];   // 001
    pub const MEPC_T: [Trit; 3] = [Trit::Z, Trit::P, Trit::Z];    // 0+0
    pub const MCAUSE_T: [Trit; 3] = [Trit::Z, Trit::P, Trit::P];  // 0++
}

/// Conditions pour les instructions de branchement
pub mod cond {
    use crate::core_types::Trit;

    pub const EQ: [Trit; 3] = [Trit::Z, Trit::Z, Trit::Z]; // 000 (Equal)
    pub const NE: [Trit; 3] = [Trit::Z, Trit::Z, Trit::P]; // 001 (Not Equal)
    pub const LT: [Trit; 3] = [Trit::Z, Trit::P, Trit::Z]; // 0+0 (Less Than)
    pub const GE: [Trit; 3] = [Trit::Z, Trit::P, Trit::P]; // 0++ (Greater or Equal)
    pub const GT: [Trit; 3] = [Trit::P, Trit::Z, Trit::Z]; // +00 (Greater Than)
    pub const LE: [Trit; 3] = [Trit::P, Trit::Z, Trit::P]; // +0+ (Less or Equal)
}

/// Limites pour les valeurs immédiates selon le format d'instruction
pub mod imm_limits {
    // Format I: 6 trits signés (-364 à +364)
    pub const I_MIN: i32 = -364;
    pub const I_MAX: i32 = 364;

    // Format U: 9 trits signés (-9841 à +9841)
    pub const U_MIN: i32 = -9841;
    pub const U_MAX: i32 = 9841;

    // Format J: 9 trits signés pour offset (-1093 à +1093)
    pub const J_MIN: i32 = -1093;
    pub const J_MAX: i32 = 1093;
    
    // Format B: 3 trits signés pour offset (-40 à +40)
    pub const B_MIN: i32 = -40;
    pub const B_MAX: i32 = 40;
    
    // Format C: 4 trits signés pour offset (-40 à +40)
    pub const C_OFFSET_MIN: i32 = -40;
    pub const C_OFFSET_MAX: i32 = 40;
    
    // Format C: 4 trits pour registre (0 à 7)
    pub const C_REG_MIN: i32 = 0;
    pub const C_REG_MAX: i32 = 7;
}