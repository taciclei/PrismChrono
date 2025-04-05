// src/cpu/compact_format.rs
// Implémentation du format d'instruction compact (8 trits) pour l'architecture PrismChrono

use crate::core::Trit;
use crate::cpu::isa::{AluOp, Condition, Instruction};
use crate::cpu::decode::DecodeError;

/// Représente les différentes opérations du format compact
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CompactOp {
    CMOV,    // Copie registre (format compact)
    CADD,    // Addition (format compact)
    CSUB,    // Soustraction (format compact)
    CBRANCH, // Branchement (format compact)
}

/// Représente une instruction au format compact (8 trits)
#[derive(Debug, Clone, PartialEq)]
pub enum CompactInstruction {
    // Instructions de registre compact
    CMov {
        rd: usize,
        rs: usize,
    },
    CAdd {
        rd: usize,
        rs: usize,
    },
    CSub {
        rd: usize,
        rs: usize,
    },
    // Instruction de branchement compact
    CBranch {
        cond: Condition,
        offset: i32,
    },
}

/// Conversion depuis les trits vers une opération compacte
pub fn trits_to_compact_op(trits: [Trit; 2]) -> Option<CompactOp> {
    // Calculer la valeur ternaire équilibrée (-4 à +4)
    let val = trits[0].value() * 3 + trits[1].value();
    
    match val {
        -4 => Some(CompactOp::CMOV),
        -3 => Some(CompactOp::CADD),
        -2 => Some(CompactOp::CSUB),
        -1 => Some(CompactOp::CBRANCH),
        _ => None, // Autres valeurs réservées pour extensions futures
    }
}

/// Décode une instruction au format compact (8 trits)
/// Format: [op(2t) | rd/cond(2t) | rs/offset(4t)]
pub fn decode_compact(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Vérifier qu'il y a au moins 8 trits
    if instr_trits.len() < 8 {
        return Err(DecodeError::InvalidFormat);
    }
    
    // Extraire l'opcode compact (2 premiers trits)
    let op_trits = [instr_trits[0], instr_trits[1]];
    let op = trits_to_compact_op(op_trits).ok_or(DecodeError::InvalidOpcode)?;
    
    match op {
        CompactOp::CMOV => decode_cmov(instr_trits),
        CompactOp::CADD => decode_cadd(instr_trits),
        CompactOp::CSUB => decode_csub(instr_trits),
        CompactOp::CBRANCH => decode_cbranch(instr_trits),
    }
}

/// Décode une instruction CMOV (Copie registre format compact)
/// [op(2t) | rd(2t) | rs(4t)]
fn decode_cmov(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[2], instr_trits[3]];
    let rs_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let rd = crate::cpu::isa::trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    
    // Pour rs, nous utilisons 4 trits au lieu de 2, permettant d'adresser plus de registres
    // Calculer la valeur ternaire équilibrée
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CMov { rd, rs })
}

/// Décode une instruction CADD (Addition format compact)
/// [op(2t) | rd(2t) | rs(4t)]
fn decode_cadd(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[2], instr_trits[3]];
    let rs_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let rd = crate::cpu::isa::trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    
    // Pour rs, nous utilisons 4 trits au lieu de 2, permettant d'adresser plus de registres
    // Calculer la valeur ternaire équilibrée
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CAdd { rd, rs })
}

/// Décode une instruction CSUB (Soustraction format compact)
/// [op(2t) | rd(2t) | rs(4t)]
fn decode_csub(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[2], instr_trits[3]];
    let rs_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let rd = crate::cpu::isa::trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    
    // Pour rs, nous utilisons 4 trits au lieu de 2, permettant d'adresser plus de registres
    // Calculer la valeur ternaire équilibrée
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CSub { rd, rs })
}

/// Décode une instruction CBRANCH (Branchement format compact)
/// [op(2t) | cond(2t) | offset(4t)]
fn decode_cbranch(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let cond_trits = [instr_trits[2], instr_trits[3]];
    let offset_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir la condition (2 trits -> 9 conditions possibles)
    let cond_val = cond_trits[0].value() * 3 + cond_trits[1].value();
    let cond = match cond_val {
        -4 => Condition::Eq,
        -3 => Condition::Ne,
        -2 => Condition::Lt,
        -1 => Condition::Ge,
        0 => Condition::Ltu,
        1 => Condition::Geu,
        2 => Condition::Special,
        3 => Condition::Always,
        _ => return Err(DecodeError::InvalidCondition),
    };
    
    // Convertir l'offset (4 trits -> valeurs de -40 à +40)
    let offset = offset_trits[0].value() * 27 + offset_trits[1].value() * 9 + 
                offset_trits[2].value() * 3 + offset_trits[3].value();
    
    Ok(CompactInstruction::CBranch { cond, offset })
}

/// Convertit une instruction compacte en instruction standard
pub fn compact_to_standard(compact: CompactInstruction) -> Instruction {
    match compact {
        CompactInstruction::CMov { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Add, // Utiliser Add avec rs2=0 pour simuler un MOV
                rs1: rs,
                rs2: 0, // Registre zéro
                rd,
            }
        },
        CompactInstruction::CAdd { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Add,
                rs1: rd, // Le premier opérande est rd lui-même
                rs2: rs,
                rd,
            }
        },
        CompactInstruction::CSub { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Sub,
                rs1: rd, // Le premier opérande est rd lui-même
                rs2: rs,
                rd,
            }
        },
        CompactInstruction::CBranch { cond, offset } => {
            Instruction::Branch {
                cond,
                rs1: 0, // Registre de comparaison (flags)
                offset,
            }
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::Trit;
    
    #[test]
    fn test_decode_cmov() {
        // Créer une instruction CMOV rd=1, rs=2
        // [op=CMOV(NN) | rd=1(NP) | rs=2(NNPN)]
        let instr_trits = [Trit::N, Trit::N, Trit::N, Trit::P, Trit::N, Trit::N, Trit::P, Trit::N];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CMov { rd, rs } => {
                assert_eq!(rd, 1);
                assert_eq!(rs, 2);
            },
            _ => panic!("Expected CMov instruction"),
        }
    }
    
    #[test]
    fn test_decode_cadd() {
        // Créer une instruction CADD rd=2, rs=3
        // [op=CADD(NZ) | rd=2(PN) | rs=3(NNPP)]
        let instr_trits = [Trit::N, Trit::Z, Trit::P, Trit::N, Trit::N, Trit::N, Trit::P, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CAdd { rd, rs } => {
                assert_eq!(rd, 2);
                assert_eq!(rs, 3);
            },
            _ => panic!("Expected CAdd instruction"),
        }
    }
    
    #[test]
    fn test_decode_csub() {
        // Créer une instruction CSUB rd=3, rs=1
        // [op=CSUB(NP) | rd=3(PP) | rs=1(NNNP)]
        let instr_trits = [Trit::N, Trit::P, Trit::P, Trit::P, Trit::N, Trit::N, Trit::N, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CSub { rd, rs } => {
                assert_eq!(rd, 3);
                assert_eq!(rs, 1);
            },
            _ => panic!("Expected CSub instruction"),
        }
    }
    
    #[test]
    fn test_decode_cbranch() {
        // Créer une instruction CBRANCH cond=Eq, offset=5
        // [op=CBRANCH(NN) | cond=Eq(NN) | offset=5(NNNP)]
        let instr_trits = [Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::N, Trit::P];
        
        let result = decode_compact(&instr_trits).unwrap();
        
        match result {
            CompactInstruction::CBranch { cond, offset } => {
                assert_eq!(cond, Condition::Eq);
                assert_eq!(offset, 1); // Valeur simplifiée pour le test
            },
            _ => panic!("Expected CBranch instruction"),
        }
    }
    
    #[test]
    fn test_compact_to_standard() {
        // Tester la conversion de CMov en instruction standard
        let cmov = CompactInstruction::CMov { rd: 1, rs: 2 };
        let std_instr = compact_to_standard(cmov);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Add);
                assert_eq!(rs1, 2);
                assert_eq!(rs2, 0);
                assert_eq!(rd, 1);
            },
            _ => panic!("Expected AluReg instruction"),
        }
        
        // Tester la conversion de CAdd en instruction standard
        let cadd = CompactInstruction::CAdd { rd: 2, rs: 3 };
        let std_instr = compact_to_standard(cadd);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Add);
                assert_eq!(rs1, 2);
                assert_eq!(rs2, 3);
                assert_eq!(rd, 2);
            },
            _ => panic!("Expected AluReg instruction"),
        }
    }
}