//! Module AST (Abstract Syntax Tree) pour l'assembleur PrismChrono
//!
//! Ce module définit les structures de données représentant l'arbre syntaxique abstrait
//! du code assembleur après l'analyse syntaxique.

use crate::core_types::Address;

/// Représente un opérande dans une instruction
#[derive(Debug, Clone, PartialEq)]
pub enum Operand {
    /// Registre (ex: R0, R1, R2)
    Register(u8),
    /// Valeur immédiate (ex: 42)
    Immediate(i32),
    /// Référence à un label (ex: "loop" dans "JAL loop")
    Label(String),
}

/// Représente une instruction assembleur
#[derive(Debug, Clone, PartialEq)]
pub enum Instruction {
    /// No Operation
    Nop,
    /// Halt
    Halt,
    /// Add Immediate: ADDI rd, rs1, imm
    Addi {
        rd: u8,
        rs1: u8,
        imm: i32,
    },
    /// Load Upper Immediate: LUI rd, imm
    Lui {
        rd: u8,
        imm: i32,
    },
    /// Jump And Link: JAL rd, label
    Jal {
        rd: u8,
        label: String,
    },
    /// Store Word: STOREW rs1, rs2, imm
    Storew {
        rs1: u8,
        rs2: u8,
        imm: i32,
    },
    /// Store Tryte: STORET rs1, rs2, imm
    Storet {
        rs1: u8,
        rs2: u8,
        imm: i32,
    },
    /// Branch: BRANCH rs1, rs2, condition, label
    Branch {
        rs1: u8,
        rs2: u8,
        condition: String,
        label: String,
    },
    /// Add: ADD rd, rs1, rs2
    Add {
        rd: u8,
        rs1: u8,
        rs2: u8,
    },
    /// Subtract: SUB rd, rs1, rs2
    Sub {
        rd: u8,
        rs1: u8,
        rs2: u8,
    },
    /// Environment Call: ECALL
    Ecall,
    /// Environment Break: EBREAK
    Ebreak,
    /// Machine Return: MRET_T
    Mret,
    /// CSR Read & Write: CSRRW_T rd, csr_code, rs1
    Csrrw {
        rd: u8,
        csr_code: String,
        rs1: u8,
    },
    /// CSR Read & Set: CSRRS_T rd, csr_code, rs1
    Csrrs {
        rd: u8,
        csr_code: String,
        rs1: u8,
    }
}

/// Représente une directive assembleur
#[derive(Debug, Clone, PartialEq)]
pub enum Directive {
    /// .org <address> - Définit l'adresse de départ
    Org(Address),
    /// .align <alignment> - Aligne l'adresse courante
    Align(u32),
    /// .tryte <value> - Définit un tryte
    Tryte(i32),
    /// .word <value> - Définit un mot (8 trytes)
    Word(i32),
}

/// Représente un nœud dans l'AST
#[derive(Debug, Clone, PartialEq)]
pub enum AstNode {
    /// Instruction assembleur
    Instruction(Instruction),
    /// Directive assembleur
    Directive(Directive),
    /// Définition de label
    Label(String),
    /// Ligne vide ou commentaire
    Empty,
}

/// Représente une ligne de code assembleur avec son numéro de ligne
#[derive(Debug, Clone)]
pub struct SourceLine {
    /// Numéro de ligne dans le fichier source
    pub line_number: usize,
    /// Nœud AST correspondant
    pub node: AstNode,
}

/// Représente le programme assembleur complet
#[derive(Debug, Clone)]
pub struct Program {
    /// Lignes de code avec leur numéro de ligne
    pub lines: Vec<SourceLine>,
}

impl Program {
    /// Crée un nouveau programme vide
    pub fn new() -> Self {
        Program { lines: Vec::new() }
    }

    /// Ajoute une ligne au programme
    pub fn add_line(&mut self, line_number: usize, node: AstNode) {
        self.lines.push(SourceLine { line_number, node });
    }
}