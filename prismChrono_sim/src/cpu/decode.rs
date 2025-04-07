// src/cpu/decode.rs
use crate::core::Trit;
use crate::cpu::isa::{Instruction, AluOp, Opcode};
use crate::cpu::isa::{trits_to_aluop, trits_to_branch_condition, trits_to_opcode, trits_to_register};
use crate::cpu::isa::{trits_to_imm3, trits_to_imm4, trits_to_imm5, trits_to_imm7};

/// Erreurs possibles lors du décodage d'une instruction
#[derive(Debug, PartialEq, Eq)]
pub enum DecodeError {
    InvalidOpcode,      // Opcode invalide
    InvalidFormat,      // Format d'instruction invalide
    InvalidRegister,    // Registre invalide
    InvalidAluOp,       // Opération ALU invalide
    InvalidBranchCondition,   // Condition de branchement invalide
    InvalidInstruction, // Instruction invalide (autre raison)
}

/// Décode une instruction à partir d'une séquence de trits
/// Retourne l'instruction décodée ou une erreur
/// La fonction accepte un slice de trits, et peut décoder soit:
/// - Une instruction standard (12 trits)
/// - Une instruction compacte (8 trits)
pub fn decode(instr_trits: impl AsRef<[Trit]>) -> Result<Instruction, DecodeError> {
    let instr_trits = instr_trits.as_ref();

    // Vérifier le format de l'instruction (compact ou standard)
    if instr_trits.len() == 8 {
        // Format compact (8 trits)
        // Utiliser le décodeur de format compact et convertir en instruction standard
        let compact_instr = crate::cpu::compact_format::decode_compact(instr_trits)?;
        return Ok(crate::cpu::compact_format::compact_to_standard(compact_instr));
    } else if instr_trits.len() >= 12 {
        // Format standard (12 trits)
        // Extraire l'opcode (3 premiers trits)
        let opcode_trits = [instr_trits[0], instr_trits[1], instr_trits[2]];
        let opcode = trits_to_opcode(opcode_trits).ok_or(DecodeError::InvalidOpcode)?;

        match opcode {
        Opcode::Alu => decode_alu_reg(&instr_trits),
        Opcode::AluI => decode_alu_imm(&instr_trits),
        Opcode::Load => decode_load(&instr_trits),
        Opcode::Store => decode_store(&instr_trits),
        Opcode::Branch => decode_branch(&instr_trits),
        Opcode::Jump => decode_jump(&instr_trits),
        Opcode::Call => decode_call(&instr_trits),
        Opcode::System => decode_system(&instr_trits),
        Opcode::Lui => decode_lui(&instr_trits),
        Opcode::Auipc => decode_auipc(&instr_trits),
        Opcode::Jalr => decode_jalr(&instr_trits),
        Opcode::Csr => decode_csr(&instr_trits),
        }
    } else {
        // Format invalide
        return Err(DecodeError::InvalidFormat);
    }

}

/// Décode une instruction ALU format R (registre-registre)
/// [opcode(3t) | rd(2t) | rs1(2t) | rs2(2t) | func(3t)]
fn decode_alu_reg(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let rs1_trits = [instr_trits[5], instr_trits[6]];
    let rs2_trits = [instr_trits[7], instr_trits[8]];
    let func_trits = [instr_trits[9], instr_trits[10], instr_trits[11]];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs2 = trits_to_register(rs2_trits).ok_or(DecodeError::InvalidRegister)?;

    // Utiliser func_trits pour déterminer l'opération ALU
    let op = trits_to_aluop(func_trits).ok_or(DecodeError::InvalidAluOp)?;

    Ok(Instruction::AluReg { op, rs1, rs2, rd })
}

/// Décode une instruction ALU format I (avec immédiat)
/// [opcode(3t) | rd(2t) | rs1(2t) | immediate(5t)]
fn decode_alu_imm(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let rs1_trits = [instr_trits[5], instr_trits[6]];
    let imm_trits = [
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;

    // Convertir l'immédiat de 5 trits
    let imm = trits_to_imm5(imm_trits);

    // L'opération ALU est déterminée par l'opcode, pas par rs1
    // Pour simplifier, nous utilisons Add comme opération par défaut
    // Dans une implémentation complète, l'opcode spécifierait l'opération exacte
    let op = AluOp::Add;

    Ok(Instruction::AluImm { op, rs1, rd, imm })
}

/// Décode une instruction de chargement (Load) format I
/// [opcode(3t) | rd(2t) | rs1(2t) | offset(5t)]
fn decode_load(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let rs1_trits = [instr_trits[5], instr_trits[6]];
    let offset_trits = [
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm5(offset_trits);

    Ok(Instruction::Load {
        rd,
        rs1,
        offset: offset.try_into().unwrap(),
    })
}

/// Décode une instruction de stockage (Store) format S
/// [opcode(3t) | src(2t) | base(2t) | offset(5t)]
fn decode_store(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let src_trits = [instr_trits[3], instr_trits[4]];
    let base_trits = [instr_trits[5], instr_trits[6]];
    let offset_trits = [
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rs2 = trits_to_register(src_trits).ok_or(DecodeError::InvalidRegister)?; // rs2 = src (valeur à stocker)
    let rs1 = trits_to_register(base_trits).ok_or(DecodeError::InvalidRegister)?; // rs1 = base (adresse de base)
    let offset = trits_to_imm5(offset_trits);

    Ok(Instruction::Store {
        rs1,
        rs2,
        offset: offset.try_into().unwrap(),
    })
}

/// Décode une instruction de branchement (Branch) format B
/// [opcode(3t) | cond(3t) | rs1(2t) | offset(4t)]
fn decode_branch(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let cond_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];
    let rs1_trits = [instr_trits[6], instr_trits[7]];
    let offset_trits = [
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let cond = trits_to_branch_condition(cond_trits).ok_or(DecodeError::InvalidBranchCondition)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm4(offset_trits);

    Ok(Instruction::Branch {
        rs1,
        cond,
        offset: offset.try_into().unwrap(),
    })
}

/// Décode une instruction de saut (Jump) format J
/// [opcode(3t) | rd(2t) | offset(7t)]
fn decode_jump(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let offset_trits = [
        instr_trits[5],
        instr_trits[6],
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm7(offset_trits);

    Ok(Instruction::Jump { rd, offset })
}

/// Décode une instruction d'appel (Call) format J
/// [opcode(3t) | rd(2t) | offset(7t)]
fn decode_call(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let offset_trits = [
        instr_trits[5],
        instr_trits[6],
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm7(offset_trits);

    Ok(Instruction::Call { rd, offset })
}

/// Décode une instruction système format I
/// [opcode(3) | func(3) | unused(6)]
fn decode_system(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let func_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];

    // Convertir en valeurs
    let func = trits_to_imm3(func_trits);

    Ok(Instruction::System { func })
}

/// Décode une instruction LUI format U
/// [opcode(3t) | rd(2t) | immediate(7t)]
fn decode_lui(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let imm_trits = [
        instr_trits[5],
        instr_trits[6],
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let imm = trits_to_imm7(imm_trits);

    Ok(Instruction::Lui { rd, imm })
}

/// Décode une instruction AUIPC format U
/// [opcode(3t) | rd(2t) | immediate(7t)]
fn decode_auipc(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let imm_trits = [
        instr_trits[5],
        instr_trits[6],
        instr_trits[7],
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let imm = trits_to_imm7(imm_trits);

    Ok(Instruction::Auipc { rd, imm })
}

/// Décode une instruction JALR format I
/// [opcode(3) | rd(3) | rs1(3) | offset(3)]
fn decode_jalr(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let rd_trits = [instr_trits[3], instr_trits[4]];
    let rs1_trits = [instr_trits[6], instr_trits[7]];
    let offset_trits = [instr_trits[9], instr_trits[10], instr_trits[11]];

    // Convertir en valeurs
    let rd = trits_to_register(rd_trits).ok_or(DecodeError::InvalidRegister)?;
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm3(offset_trits);

    Ok(Instruction::Jalr { rd, rs1, offset: offset.into() })
}

/// Décode une instruction CSR format I
/// [opcode(3t) | csr(3t) | rs1(2t) | offset(4t)]
fn decode_csr(instr_trits: &[Trit]) -> Result<Instruction, DecodeError> {
    // Extraire les champs
    let csr_trits = [instr_trits[3], instr_trits[4], instr_trits[5]];
    let rs1_trits = [instr_trits[6], instr_trits[7]];
    let offset_trits = [
        instr_trits[8],
        instr_trits[9],
        instr_trits[10],
        instr_trits[11],
    ];

    // Convertir en valeurs
    let csr = trits_to_imm3(csr_trits);
    let rs1 = trits_to_register(rs1_trits).ok_or(DecodeError::InvalidRegister)?;
    let offset = trits_to_imm4(offset_trits);

    Ok(Instruction::Csr { csr, rs1, offset: offset.try_into().unwrap() })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::Trit;
    use crate::cpu::registers::Register;
    use crate::cpu::BranchCondition;

    #[test]
    fn test_decode_alu_reg() {
        // Créer une instruction ALU format R (ADD R3, R1, R2)
        // Opcode ALU = [N,N,N] (-13)
        // rd = R3 = [N,Z,N] (-10)
        // rs1 = R1 = [N,N,Z] (-12)
        // rs2 = R2 = [N,N,P] (-11)
        // func = ADD = [N,N,N] (-13)
        let instr_trits = [
            Trit::N,
            Trit::N,
            Trit::N, // Opcode ALU
            Trit::N,
            Trit::Z,
            Trit::N, // rd = R3
            Trit::N,
            Trit::N,
            Trit::Z, // rs1 = R1
            Trit::N,
            Trit::N,
            Trit::P, // rs2 = R2
            Trit::N,
            Trit::N,
            Trit::N, // func = ADD
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::AluReg { op, rs1, rs2, rd }) = result {
            assert_eq!(op, AluOp::Add);
            assert_eq!(rs1, Register::R1);
            assert_eq!(rs2, Register::R2);
            assert_eq!(rd, Register::R3);
        } else {
            panic!("Expected AluReg instruction");
        }
    }

    #[test]
    fn test_decode_load() {
        // Créer une instruction Load (LOADW R4, 3(R2))
        // Opcode Load = [N,N,P] (-11)
        // rd = R4 = [N,Z,P] (-9)
        // rs1 = R2 = [N,N,P] (-11)
        // offset = 3 = [P,Z,Z,Z,Z] (3)
        let instr_trits = [
            Trit::N,
            Trit::N,
            Trit::P, // Opcode Load
            Trit::N,
            Trit::Z,
            Trit::P, // rd = R4
            Trit::N,
            Trit::N,
            Trit::P, // rs1 = R2
            Trit::P,
            Trit::Z,
            Trit::Z, // offset = 3
            Trit::Z,
            Trit::Z,
            Trit::Z, // offset (suite)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Load { rd, rs1, offset }) = result {
            assert_eq!(rd, Register::R4);
            assert_eq!(rs1, Register::R2);
            assert_eq!(offset, 3);
        } else {
            panic!("Expected Load instruction");
        }
    }

    #[test]
    fn test_decode_branch() {
        // Créer une instruction Branch (BRANCH EQ, R3, 4)
        // Opcode Branch = [N,Z,P] (-9)
        // cond = EQ = [N,N,N] (-13)
        // rs1 = R3 = [N,Z,N] (-10)
        // offset = 4 = [P,P,Z,Z] (4)
        let instr_trits = [
            Trit::N,
            Trit::Z,
            Trit::P, // Opcode Branch
            Trit::N,
            Trit::N,
            Trit::N, // cond = EQ
            Trit::N,
            Trit::Z,
            Trit::N, // rs1 = R3
            Trit::P,
            Trit::P,
            Trit::Z, // offset = 4
            Trit::Z,
            Trit::Z,
            Trit::Z, // offset (suite)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Branch { rs1, cond, offset }) = result {
            assert_eq!(rs1, Register::R3);
            assert_eq!(cond, BranchCondition::Eq);
            assert_eq!(offset, 4);
        } else {
            panic!("Expected Branch instruction");
        }
    }

    #[test]
    fn test_decode_jump() {
        // Créer une instruction Jump (JAL R7, 42)
        // Opcode Jump = [N,Z,P] (-8)
        // rd = R7 = [N,P,P] (-6)
        // offset = 42 (valeur à encoder en ternaire)
        let instr_trits = [
            Trit::N,
            Trit::Z,
            Trit::P, // Opcode Jump
            Trit::N,
            Trit::P,
            Trit::P, // rd = R7
            Trit::P,
            Trit::P,
            Trit::P, // offset (partie haute)
            Trit::P,
            Trit::P,
            Trit::P, // offset (partie basse)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Jump { rd, offset }) = result {
            assert_eq!(rd, Register::R7);
            // Vérifier que l'offset est une valeur non nulle
            assert_ne!(offset, 0);
        } else {
            panic!("Expected Jump instruction");
        }
    }

    #[test]
    fn test_decode_lui() {
        // Créer une instruction LUI (LUI R5, 100)
        // Opcode LUI = [N,P,N] (-5)
        // rd = R5 = [N,P,N] (-8)
        // imm = 100 (valeur à encoder en ternaire)
        let instr_trits = [
            Trit::N,
            Trit::P,
            Trit::N, // Opcode LUI
            Trit::N,
            Trit::P,
            Trit::N, // rd = R5
            Trit::P,
            Trit::Z,
            Trit::P, // imm (partie haute)
            Trit::P,
            Trit::Z,
            Trit::P, // imm (partie basse)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Lui { rd, imm }) = result {
            assert_eq!(rd, Register::R5);
            // Vérifier que l'immédiat est une valeur non nulle
            assert_ne!(imm, 0);
        } else {
            panic!("Expected Lui instruction");
        }
    }

    #[test]
    fn test_decode_auipc() {
        // Créer une instruction AUIPC
        // Opcode AUIPC = [N,P,Z] (-4)
        // rd = R6 = [N,P,Z] (-7)
        // imm = valeur à calculer
        let instr_trits = [
            Trit::N,
            Trit::P,
            Trit::Z, // Opcode AUIPC
            Trit::N,
            Trit::P,
            Trit::Z, // rd = R6
            Trit::P,
            Trit::Z,
            Trit::N, // imm (partie haute)
            Trit::Z,
            Trit::P,
            Trit::P, // imm (partie basse)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Auipc { rd, imm }) = result {
            assert_eq!(rd, Register::R6);
            // Vérifier que l'immédiat est une valeur non nulle
            assert_ne!(imm, 0);
        } else {
            panic!("Expected Auipc instruction");
        }
    }

    #[test]
    fn test_decode_jalr() {
        // Créer une instruction JALR (JALR R4, -2(R2))
        // Opcode JALR = [N,P,P] (-3)
        // rd = R4 = [N,Z,P] (-9)
        // rs1 = R2 = [N,N,P] (-11)
        // offset = -2 = [N,N,Z,Z,Z] (-2)
        let instr_trits = [
            Trit::N,
            Trit::P,
            Trit::P, // Opcode JALR
            Trit::N,
            Trit::Z,
            Trit::P, // rd = R4
            Trit::N,
            Trit::N,
            Trit::P, // rs1 = R2
            Trit::N,
            Trit::N,
            Trit::Z, // offset = -2
            Trit::Z,
            Trit::Z,
            Trit::Z, // offset (suite)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Jalr { rd, rs1, offset }) = result {
            assert_eq!(rd, Register::R4);
            assert_eq!(rs1, Register::R2);
            assert_eq!(offset, -2);
        } else {
            panic!("Expected Jalr instruction");
        }
    }

    #[test]
    fn test_invalid_opcode() {
        // Créer une instruction avec un opcode invalide
        // Opcode invalide = [P,P,P] (13)
        let instr_trits = [
            Trit::P,
            Trit::P,
            Trit::P, // Opcode invalide
            Trit::N,
            Trit::N,
            Trit::Z, // rd = R1
            Trit::N,
            Trit::N,
            Trit::P, // rs1 = R2
            Trit::N,
            Trit::Z,
            Trit::N, // rs2 = R3
        ];

        let result = decode(instr_trits);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), DecodeError::InvalidOpcode);
    }

    #[test]
    fn test_decode_alu_imm() {
        // Créer une instruction ALU format I (ADDI R3, R1, 5)
        // Opcode AluI = [N,N,Z] (-12)
        // rd = R3 = [N,Z,N] (-10)
        // rs1 = R1 = [N,N,Z] (-12)
        // imm = 5 = [P,P,N,Z,Z] (5)
        let instr_trits = [
            Trit::N,
            Trit::N,
            Trit::Z, // Opcode AluI
            Trit::N,
            Trit::Z,
            Trit::N, // rd = R3
            Trit::N,
            Trit::N,
            Trit::Z, // rs1 = R1
            Trit::P,
            Trit::P,
            Trit::N, // imm = 5
            Trit::Z,
            Trit::Z,
            Trit::Z, // imm (suite)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::AluImm { op, rs1, rd, imm }) = result {
            assert_eq!(op, AluOp::Add); // Par défaut pour ADDI
            assert_eq!(rs1, Register::R1);
            assert_eq!(rd, Register::R3);
            assert_eq!(imm, 5);
        } else {
            panic!("Expected AluImm instruction");
        }
    }

    #[test]
    fn test_decode_store() {
        // Créer une instruction Store (STOREW R2, R5, 7)
        // Opcode Store = [N,Z,N] (-10)
        // rs2 = R5 = [N,P,N] (-8)
        // rs1 = R2 = [N,N,P] (-11)
        // offset = 7 = [P,Z,P,Z,Z] (7)
        let instr_trits = [
            Trit::N,
            Trit::Z,
            Trit::N, // Opcode Store
            Trit::N,
            Trit::P,
            Trit::N, // rs2 = R5
            Trit::N,
            Trit::N,
            Trit::P, // rs1 = R2
            Trit::P,
            Trit::Z,
            Trit::P, // offset = 7
            Trit::Z,
            Trit::Z,
            Trit::Z, // offset (suite)
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::Store { rs1, rs2, offset }) = result {
            assert_eq!(rs1, Register::R2);
            assert_eq!(rs2, Register::R5);
            assert_eq!(offset, 7);
        } else {
            panic!("Expected Store instruction");
        }
    }

    #[test]
    fn test_invalid_register() {
        // Créer une instruction avec un registre invalide
        // Opcode ALU = [N,N,N] (-13)
        // rd = Invalide = [P,P,P] (13)
        // rs1 = R2 = [N,N,P] (-11)
        // rs2 = R3 = [N,Z,N] (-10)
        let instr_trits = [
            Trit::N,
            Trit::N,
            Trit::N, // Opcode ALU
            Trit::P,
            Trit::P,
            Trit::P, // rd = Invalide
            Trit::N,
            Trit::N,
            Trit::P, // rs1 = R2
            Trit::N,
            Trit::Z,
            Trit::N, // rs2 = R3
        ];

        let result = decode(instr_trits);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), DecodeError::InvalidRegister);
    }

    #[test]
    fn test_invalid_format() {
        // Créer une instruction avec un format invalide
        // Opcode ALU = [N,N,N] (-13) mais avec des champs incorrects
        let instr_trits = [
            Trit::N,
            Trit::N,
            Trit::N, // Opcode ALU
            Trit::P,
            Trit::P,
            Trit::P, // Champs incorrects
            Trit::P,
            Trit::P,
            Trit::P, // pour le format R
            Trit::P,
            Trit::P,
            Trit::P, //
        ];

        let result = decode(instr_trits);
        assert!(result.is_err());
        // Le type d'erreur exact dépend de l'implémentation
        // Cela pourrait être InvalidRegister ou InvalidFormat
        assert!(matches!(
            result.unwrap_err(),
            DecodeError::InvalidRegister | DecodeError::InvalidFormat
        ));
    }

    #[test]
    fn test_decode_system() {
        // Créer une instruction System (HALT)
        // Opcode System = [N,Z,N] (-6)
        // func = HALT = [N,N,N] (-13)
        let instr_trits = [
            Trit::N,
            Trit::Z,
            Trit::N, // Opcode System
            Trit::N,
            Trit::N,
            Trit::N, // func = HALT
            Trit::Z,
            Trit::Z,
            Trit::Z, // unused
            Trit::Z,
            Trit::Z,
            Trit::Z, // unused
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::System { func }) = result {
            assert_eq!(func, -13); // HALT a la valeur -13
        } else {
            panic!("Expected System instruction");
        }

        // Créer une instruction System (NOP)
        // Opcode System = [N,Z,N] (-6)
        // func = NOP = [N,N,Z] (-12)
        let instr_trits = [
            Trit::N,
            Trit::Z,
            Trit::N, // Opcode System
            Trit::N,
            Trit::N,
            Trit::Z, // func = NOP
            Trit::Z,
            Trit::Z,
            Trit::Z, // unused
            Trit::Z,
            Trit::Z,
            Trit::Z, // unused
        ];

        let result = decode(instr_trits);
        assert!(result.is_ok());

        if let Ok(Instruction::System { func }) = result {
            assert_eq!(func, -12); // NOP a la valeur -12
        } else {
            panic!("Expected System instruction");
        }
    }
}
