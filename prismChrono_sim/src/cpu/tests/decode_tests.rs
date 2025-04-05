// src/cpu/tests/decode_tests.rs
// Tests unitaires pour le décodeur d'instructions

use crate::core::{Trit, Tryte, Word};
use crate::cpu::decode::{DecodeError, decode};
use crate::cpu::isa::{AluOp, Condition, Instruction, InstructionFormat, Opcode};
use crate::cpu::registers::Register;

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
        assert_eq!(cond, Condition::Eq);
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
