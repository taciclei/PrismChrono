// src/cpu/tests/execute_alu_tests.rs
// Tests pour les instructions ALU

use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_alu::AluOperations;
use crate::cpu::isa::AluOp;
use crate::cpu::registers::{Flags, Register};

// Trait CpuState pour les opérations ALU
pub trait CpuState {
    fn read_gpr(&self, reg: Register) -> Word;
    fn write_gpr(&mut self, reg: Register, value: Word);
    fn read_flags(&self) -> Flags;
    fn write_flags(&mut self, flags: Flags);
}

// Structure de test qui implémente CpuState pour tester les opérations ALU
struct TestCpu {
    registers: [Word; 8],
    flags: Flags,
}

impl TestCpu {
    fn new() -> Self {
        TestCpu {
            registers: [Word::from_int(0); 8],
            flags: Flags::new(),
        }
    }
}

impl CpuState for TestCpu {
    fn read_gpr(&self, reg: Register) -> Word {
        self.registers[reg.to_index()]
    }

    fn write_gpr(&mut self, reg: Register, value: Word) {
        self.registers[reg.to_index()] = value;
    }

    fn read_flags(&self) -> Flags {
        self.flags
    }

    fn write_flags(&mut self, flags: Flags) {
        self.flags = flags;
    }
}

#[test]
fn test_add_operation() {
    let mut cpu = TestCpu::new();

    // Configurer les registres source
    cpu.write_gpr(Register::R1, Word::from_int(5));
    cpu.write_gpr(Register::R2, Word::from_int(3));

    // Exécuter ADD R1, R2, R3
    cpu.execute_alu_reg(AluOp::Add, Register::R1, Register::R2, Register::R3)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R3), Word::from_int(8));

    // Vérifier les flags
    let flags = cpu.read_flags();
    assert_eq!(flags.zf, false); // Le résultat n'est pas zéro
    assert_eq!(flags.sf, false); // Le résultat n'est pas négatif
}

#[test]
fn test_sub_operation() {
    let mut cpu = TestCpu::new();

    // Configurer les registres source
    cpu.write_gpr(Register::R1, Word::from_int(10));
    cpu.write_gpr(Register::R2, Word::from_int(7));

    // Exécuter SUB R1, R2, R3
    cpu.execute_alu_reg(AluOp::Sub, Register::R1, Register::R2, Register::R3)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R3), Word::from_int(3));

    // Vérifier les flags
    let flags = cpu.read_flags();
    assert_eq!(flags.zf, false); // Le résultat n'est pas zéro
    assert_eq!(flags.sf, false); // Le résultat n'est pas négatif
}

#[test]
fn test_add_immediate() {
    let mut cpu = TestCpu::new();

    // Configurer le registre source
    cpu.write_gpr(Register::R1, Word::from_int(5));

    // Exécuter ADDI R1, R2, 10
    cpu.execute_alu_imm(AluOp::Add, Register::R1, Register::R2, 10)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R2), Word::from_int(15));
}

#[test]
fn test_sub_immediate() {
    let mut cpu = TestCpu::new();

    // Configurer le registre source
    cpu.write_gpr(Register::R1, Word::from_int(20));

    // Exécuter SUBI R1, R2, 8
    cpu.execute_alu_imm(AluOp::Sub, Register::R1, Register::R2, 8)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R2), Word::from_int(12));
}

#[test]
fn test_zero_flag() {
    let mut cpu = TestCpu::new();

    // Configurer les registres source pour obtenir un résultat zéro
    cpu.write_gpr(Register::R1, Word::from_int(5));
    cpu.write_gpr(Register::R2, Word::from_int(5));

    // Exécuter SUB R1, R2, R3 (5 - 5 = 0)
    cpu.execute_alu_reg(AluOp::Sub, Register::R1, Register::R2, Register::R3)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R3), Word::from_int(0));

    // Vérifier les flags
    let flags = cpu.read_flags();
    assert_eq!(flags.zf, true); // Le résultat est zéro
    assert_eq!(flags.sf, false); // Le résultat n'est pas négatif
}

#[test]
fn test_negative_flag() {
    let mut cpu = TestCpu::new();

    // Configurer les registres source pour obtenir un résultat négatif
    cpu.write_gpr(Register::R1, Word::from_int(3));
    cpu.write_gpr(Register::R2, Word::from_int(8));

    // Exécuter SUB R1, R2, R3 (3 - 8 = -5)
    cpu.execute_alu_reg(AluOp::Sub, Register::R1, Register::R2, Register::R3)
        .unwrap();

    // Vérifier le résultat
    assert_eq!(cpu.read_gpr(Register::R3), Word::from_int(-5));

    // Vérifier les flags
    let flags = cpu.read_flags();
    assert_eq!(flags.zf, false); // Le résultat n'est pas zéro
    assert_eq!(flags.sf, true); // Le résultat est négatif
}
