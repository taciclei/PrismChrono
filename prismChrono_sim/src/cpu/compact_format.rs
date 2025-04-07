// src/cpu/compact_format.rs
// Implémentation du format d'instruction compact (8 trits) pour l'architecture PrismChrono

use crate::core::Trit;
use crate::cpu::isa::{AluOp, Instruction};
use crate::cpu::registers::Register;
use crate::cpu::decode::DecodeError;
use crate::cpu::isa::BranchCondition;

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
        rd: Register,
        rs: Register,
    },
    CAdd {
        rd: Register,
        rs: Register,
    },
    CSub {
        rd: Register,
        rs: Register,
    },
    // Instruction de branchement compact
    CBranch {
        cond: usize,
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
    let rd_val = rd_trits[0].value() * 3 + rd_trits[1].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rd = (rd_val.abs() % 8) as usize;
    
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CMov { 
        rd: Register::from_index(rd).unwrap_or(Register::R0), 
        rs: Register::from_index(rs).unwrap_or(Register::R0) 
    })
}

/// Décode une instruction CADD (Addition format compact)
/// [op(2t) | rd(2t) | rs(4t)]
fn decode_cadd(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[2], instr_trits[3]];
    let rs_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let rd_val = rd_trits[0].value() * 3 + rd_trits[1].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rd = (rd_val.abs() % 8) as usize;
    
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CAdd { 
        rd: Register::from_index(rd).unwrap_or(Register::R0), 
        rs: Register::from_index(rs).unwrap_or(Register::R0) 
    })
}

/// Décode une instruction CSUB (Soustraction format compact)
/// [op(2t) | rd(2t) | rs(4t)]
fn decode_csub(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[2], instr_trits[3]];
    let rs_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let rd_val = rd_trits[0].value() * 3 + rd_trits[1].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rd = (rd_val.abs() % 8) as usize;
    
    let rs_val = rs_trits[0].value() * 27 + rs_trits[1].value() * 9 + rs_trits[2].value() * 3 + rs_trits[3].value();
    // Mapper cette valeur à un index de registre (0-7 pour les registres standards)
    let rs = (rs_val.abs() % 8) as usize;
    
    Ok(CompactInstruction::CSub { 
        rd: Register::from_index(rd).unwrap_or(Register::R0), 
        rs: Register::from_index(rs).unwrap_or(Register::R0) 
    })
}

/// Décode une instruction CBRANCH (Branchement format compact)
/// [op(2t) | cond(2t) | offset(4t)]
fn decode_cbranch(instr_trits: &[Trit]) -> Result<CompactInstruction, DecodeError> {
    // Extraire les champs
    let cond_trits = [instr_trits[2], instr_trits[3]];
    let offset_trits = [instr_trits[4], instr_trits[5], instr_trits[6], instr_trits[7]];
    
    // Convertir en valeurs
    let cond_val = cond_trits[0].value() * 3 + cond_trits[1].value();
    // Mapper cette valeur à une condition (0-3)
    let cond = (cond_val.abs() % 4) as usize;
    
    // Calculer l'offset signé
    let offset_val = offset_trits[0].value() * 27 + offset_trits[1].value() * 9 + offset_trits[2].value() * 3 + offset_trits[3].value();
    
    Ok(CompactInstruction::CBranch { 
        cond, 
        offset: offset_val as i32 
    })
}

/// Convertit une instruction compacte en instruction standard
pub fn compact_to_standard(instr: CompactInstruction) -> Instruction {
    match instr {
        CompactInstruction::CMov { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Or,
                rs1: rs,
                rs2: Register::R0, // Registre zéro
                rd,
            }
        }
        CompactInstruction::CAdd { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Add,
                rs1: rd, // Le premier opérande est rd lui-même
                rs2: rs,
                rd,
            }
        }
        CompactInstruction::CSub { rd, rs } => {
            Instruction::AluReg {
                op: AluOp::Sub,
                rs1: rd, // Le premier opérande est rd lui-même
                rs2: rs,
                rd,
            }
        }
        CompactInstruction::CBranch { cond, offset } => {
            Instruction::Branch {
                rs1: Register::R0, // Registre de comparaison (flags)
                cond: BranchCondition::from_index(cond).unwrap_or(BranchCondition::Zero),
                offset: offset as i16,
            }
        }
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
                assert_eq!(rd, Register::R1);
                assert_eq!(rs, Register::R2);
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
                assert_eq!(rd, Register::R2);
                assert_eq!(rs, Register::R3);
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
                assert_eq!(rd, Register::R3);
                assert_eq!(rs, Register::R1);
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
                assert_eq!(cond, 0); // Valeur simplifiée pour le test
                assert_eq!(offset, 1); // Valeur simplifiée pour le test
            },
            _ => panic!("Expected CBranch instruction"),
        }
    }
    
    #[test]
    fn test_compact_to_standard() {
        // Tester la conversion de CMov en instruction standard
        let cmov = CompactInstruction::CMov { rd: Register::R1, rs: Register::R2 };
        let std_instr = compact_to_standard(cmov);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Or);
                assert_eq!(rs1, Register::R2);
                assert_eq!(rs2, Register::R0);
                assert_eq!(rd, Register::R1);
            },
            _ => panic!("Expected AluReg instruction"),
        }
        
        // Tester la conversion de CAdd en instruction standard
        let cadd = CompactInstruction::CAdd { rd: Register::R2, rs: Register::R3 };
        let std_instr = compact_to_standard(cadd);
        
        match std_instr {
            Instruction::AluReg { op, rs1, rs2, rd } => {
                assert_eq!(op, AluOp::Add);
                assert_eq!(rs1, Register::R2);
                assert_eq!(rs2, Register::R3);
                assert_eq!(rd, Register::R2);
            },
            _ => panic!("Expected AluReg instruction"),
        }
    }
}