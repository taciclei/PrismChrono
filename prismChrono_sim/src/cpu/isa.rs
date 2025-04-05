// src/cpu/isa.rs
// Définition de l'ISA (Instruction Set Architecture) pour l'architecture PrismChrono

use crate::core::Trit;
use crate::cpu::registers::Register;

/// Représente les différents formats d'instructions sur 12 trits
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum InstructionFormat {
    /// Format R: opérations registre-registre
    /// [opcode(3t) | rd(2t) | rs1(2t) | rs2(2t) | func(3t)]
    R,

    /// Format I: opérations avec immédiat
    /// [opcode(3t) | rd(2t) | rs1(2t) | immediate(5t)]
    I,

    /// Format S: opérations de stockage (store)
    /// [opcode(3t) | src(2t) | base(2t) | offset(5t)]
    S,

    /// Format B: opérations de branchement
    /// [opcode(3t) | cond(3t) | rs1(2t) | offset(4t)]
    B,

    /// Format U: opérations avec immédiat étendu
    /// [opcode(3t) | rd(2t) | immediate(7t)]
    U,

    /// Format J: opérations de saut (jump)
    /// [opcode(3t) | rd(2t) | offset(7t)]
    J,
}

/// Représente les différentes opérations de l'ALU
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AluOp {
    // Opérations arithmétiques
    Add, // Addition
    Sub, // Soustraction
    Mul, // Multiplication
    Div, // Division
    Mod, // Modulo

    // Opérations logiques trit-à-trit
    TritInv, // Inverseur logique
    TritMin, // Minimum logique
    TritMax, // Maximum logique

    // Opérations de décalage
    Shl, // Décalage à gauche
    Shr, // Décalage à droite

    // Opérations de comparaison
    Cmp, // Comparaison (met à jour les flags)
}

/// Représente les conditions pour les instructions de branchement
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Condition {
    Eq,      // Égal (ZF = 1)
    Ne,      // Non égal (ZF = 0)
    Lt,      // Inférieur (SF = 1)
    Ge,      // Supérieur ou égal (SF = 0)
    Ltu,     // Inférieur non signé
    Geu,     // Supérieur ou égal non signé
    Special, // État spécial (XF = 1)
    Always,  // Toujours vrai
}

/// Représente les différents opcodes de l'architecture
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Opcode {
    // Opérations ALU (format R)
    Alu,

    // Opérations avec immédiat (format I)
    AluI,

    // Opérations de chargement/stockage (formats I/S)
    Load,
    Store,

    // Opérations de branchement (format B)
    Branch,

    // Opérations de saut (format J)
    Jump,
    Call,

    // Opérations avec immédiat supérieur (format U)
    Lui,   // Load Upper Immediate
    Auipc, // Add Upper Immediate to PC

    // Opérations CSR (format I)
    Csr, // Control and Status Register operations

    // Opérations de saut indirect (format I)
    Jalr, // Jump And Link Register

    // Opérations spéciales
    System,
}

/// Représente une instruction décodée
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Instruction {
    // Instructions spéciales
    Nop,
    Halt,
    EBreak,

    // Format R: opérations registre-registre
    AluReg {
        op: AluOp,
        rs1: Register,
        rs2: Register,
        rd: Register,
    },

    // Format I: opérations avec immédiat
    AluImm {
        op: AluOp,
        rs1: Register,
        rd: Register,
        imm: i16, // Valeur immédiate (5 trits => -121 à +121)
    },

    // Format I: opérations de chargement
    Load {
        rd: Register,
        rs1: Register,
        offset: i16, // Offset d'adresse
    },

    // Format S: opérations de stockage
    Store {
        rs1: Register, // Adresse de base
        rs2: Register, // Valeur à stocker
        offset: i16,   // Offset d'adresse
    },

    // Format B: opérations de branchement
    Branch {
        rs1: Register,
        cond: Condition,
        offset: i16, // Offset de branchement
    },

    // Format J: opérations de saut
    Jump {
        rd: Register, // Registre de destination (pour sauvegarder PC+1)
        offset: i16,  // Offset de saut (6 trits => plus grand offset)
    },

    // Format J: opérations d'appel
    Call {
        rd: Register, // Registre de destination (pour sauvegarder PC+1)
        offset: i16,  // Offset d'appel
    },

    // Format U: opérations avec immédiat supérieur
    Lui {
        rd: Register,
        imm: i16, // Immédiat 7 trits
    },

    Auipc {
        rd: Register,
        imm: i16, // Immédiat 7 trits
    },

    // Format I: saut indirect
    Jalr {
        rd: Register,
        rs1: Register,
        offset: i16, // Offset 5 trits
    },

    // Opérations CSR
    CsrRw {
        rd: Register,
        csr: i8,
        rs1: Register,
    }, // CSR Read & Write
    CsrRs {
        rd: Register,
        csr: i8,
        rs1: Register,
    }, // CSR Read & Set

    // Opérations de retour de trap
    MRet, // Machine Return

    // Format I: opérations système
    System {
        func: i8, // Code de fonction système
    },
}

/// Conversion des trits en valeurs pour les opcodes
pub fn trits_to_opcode(trits: [Trit; 3]) -> Option<Opcode> {
    // Convertir les 3 trits en valeur ternaire équilibrée (-13 à +13)
    let t0 = trits[0].value();
    let t1 = trits[1].value();
    let t2 = trits[2].value();
    let value = t0 + t1 * 3 + t2 * 9;

    match value {
        -13 => Some(Opcode::Alu),
        -12 => Some(Opcode::AluI),
        -11 => Some(Opcode::Load),
        -10 => Some(Opcode::Store),
        -9 => Some(Opcode::Branch),
        -8 => Some(Opcode::Jump),
        -7 => Some(Opcode::Call),
        -6 => Some(Opcode::System),
        -5 => Some(Opcode::Lui),
        -4 => Some(Opcode::Auipc),
        -3 => Some(Opcode::Jalr),
        _ => None, // Opcode invalide
    }
}

/// Conversion des trits en valeurs pour les opérations ALU
pub fn trits_to_aluop(trits: [Trit; 3]) -> Option<AluOp> {
    // Convertir les 3 trits en valeur ternaire équilibrée (-13 à +13)
    let t0 = trits[0].value();
    let t1 = trits[1].value();
    let t2 = trits[2].value();
    let value = t0 + t1 * 3 + t2 * 9;

    match value {
        -13 => Some(AluOp::Add),
        -12 => Some(AluOp::Sub),
        -11 => Some(AluOp::Mul),
        -10 => Some(AluOp::Div),
        -9 => Some(AluOp::Mod),
        -8 => Some(AluOp::TritInv),
        -7 => Some(AluOp::TritMin),
        -6 => Some(AluOp::TritMax),
        -5 => Some(AluOp::Shl),
        -4 => Some(AluOp::Shr),
        -3 => Some(AluOp::Cmp),
        _ => None, // Opération ALU invalide
    }
}

/// Conversion des trits en valeurs pour les conditions de branchement
pub fn trits_to_condition(trits: [Trit; 3]) -> Option<Condition> {
    // Convertir les 3 trits en valeur ternaire équilibrée (-13 à +13)
    let t0 = trits[0].value();
    let t1 = trits[1].value();
    let t2 = trits[2].value();
    let value = t0 + t1 * 3 + t2 * 9;

    match value {
        -13 => Some(Condition::Eq),
        -12 => Some(Condition::Ne),
        -11 => Some(Condition::Lt),
        -10 => Some(Condition::Ge),
        -9 => Some(Condition::Ltu),
        -8 => Some(Condition::Geu),
        -7 => Some(Condition::Special),
        -6 => Some(Condition::Always),
        _ => None, // Condition invalide
    }
}

/// Conversion des trits en valeur immédiate signée (3 trits)
pub fn trits_to_imm3(trits: [Trit; 3]) -> i8 {
    let t0 = trits[0].value();
    let t1 = trits[1].value();
    let t2 = trits[2].value();
    t0 + t1 * 3 + t2 * 9
}

/// Conversion des trits en valeur immédiate signée (4 trits)
pub fn trits_to_imm4(trits: [Trit; 4]) -> i16 {
    let mut value: i16 = 0;
    let mut weight: i16 = 1;

    for i in 0..4 {
        value += trits[i].value() as i16 * weight;
        weight *= 3;
    }

    value
}

/// Conversion des trits en valeur immédiate signée (5 trits)
pub fn trits_to_imm5(trits: [Trit; 5]) -> i16 {
    let mut value: i16 = 0;
    let mut weight: i16 = 1;

    for i in 0..5 {
        value += trits[i].value() as i16 * weight;
        weight *= 3;
    }

    value
}

/// Conversion des trits en valeur immédiate signée (6 trits)
pub fn trits_to_imm6(trits: [Trit; 6]) -> i16 {
    let mut value: i16 = 0;
    let mut weight: i16 = 1;

    for i in 0..6 {
        value += trits[i].value() as i16 * weight;
        weight *= 3;
    }

    value
}

/// Conversion des trits en valeur immédiate signée (7 trits)
pub fn trits_to_imm7(trits: [Trit; 7]) -> i16 {
    let mut value: i16 = 0;
    let mut weight: i16 = 1;

    for i in 0..7 {
        value += trits[i].value() as i16 * weight;
        weight *= 3;
    }

    value
}

/// Conversion des trits en registre
pub fn trits_to_register(trits: [Trit; 2]) -> Option<Register> {
    // Convertir les 2 trits en valeur ternaire équilibrée (-4 à +4)
    let t0 = trits[0].value();
    let t1 = trits[1].value();
    let value = t0 + t1 * 3;

    // Mapper les valeurs aux registres selon l'encodage défini dans p3.md
    // R0 = (N,N), R1 = (N,Z), R2 = (N,P), R3 = (Z,N), R4 = (Z,Z), R5 = (Z,P), R6 = (P,N), R7 = (P,P)
    match value {
        -4 => Some(Register::R0), // (N,N)
        -3 => Some(Register::R1), // (N,Z)
        -2 => Some(Register::R2), // (N,P)
        -1 => Some(Register::R3), // (Z,N)
        0 => Some(Register::R4),  // (Z,Z)
        1 => Some(Register::R5),  // (Z,P)
        2 => Some(Register::R6),  // (P,N)
        4 => Some(Register::R7),  // (P,P) - Valeur: 1 + 3*1 = 4
        _ => None,                // Registre invalide
    }
}
