// src/cpu/tests/execute_branch_tests.rs
// Tests pour les instructions de branchement

use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_branch::{BranchOperations, CpuState};
use crate::cpu::isa::Condition;
use crate::cpu::registers::{Flags, Register};
use crate::memory::Memory;

// Structure de test qui implémente CpuState pour tester les opérations de branchement
struct TestCpu {
    pc: Word,
    registers: [Word; 8],
    flags: Flags,
}

impl TestCpu {
    fn new() -> Self {
        TestCpu {
            pc: Word::from_int(0),
            registers: [Word::from_int(0); 8],
            flags: Flags::new(),
        }
    }

    fn with_flags(zf: bool, sf: bool, xf: bool) -> Self {
        let mut cpu = Self::new();
        cpu.flags.zf = zf;
        cpu.flags.sf = sf;
        cpu.flags.xf = xf;
        cpu
    }
}

impl CpuState for TestCpu {
    fn read_gpr(&self, reg: Register) -> Word {
        self.registers[reg.to_index()]
    }

    fn write_gpr(&mut self, reg: Register, value: Word) {
        self.registers[reg.to_index()] = value;
    }

    fn read_pc(&self) -> Word {
        self.pc
    }

    fn write_pc(&mut self, value: Word) {
        self.pc = value;
    }

    fn read_flags(&self) -> Flags {
        self.flags
    }
}

#[test]
fn test_branch_eq_taken() {
    // Condition EQ (ZF=1) - devrait prendre le branchement
    let mut cpu = TestCpu::with_flags(true, false, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH EQ, R1, 10
    cpu.execute_branch(Register::R1, Condition::Eq, 10).unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_eq_not_taken() {
    // Condition EQ (ZF=1) - ne devrait pas prendre le branchement car ZF=0
    let mut cpu = TestCpu::with_flags(false, false, false);
    let initial_pc = Word::from_int(0);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH EQ, R1, 10
    cpu.execute_branch(Register::R1, Condition::Eq, 10).unwrap();

    // Vérifier que le PC n'a pas changé
    assert_eq!(cpu.read_pc(), initial_pc);
}

#[test]
fn test_branch_ne_taken() {
    // Condition NE (ZF=0) - devrait prendre le branchement
    let mut cpu = TestCpu::with_flags(false, false, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH NE, R1, 10
    cpu.execute_branch(Register::R1, Condition::Ne, 10).unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_ne_not_taken() {
    // Condition NE (ZF=0) - ne devrait pas prendre le branchement car ZF=1
    let mut cpu = TestCpu::with_flags(true, false, false);
    let initial_pc = Word::from_int(0);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH NE, R1, 10
    cpu.execute_branch(Register::R1, Condition::Ne, 10).unwrap();

    // Vérifier que le PC n'a pas changé
    assert_eq!(cpu.read_pc(), initial_pc);
}

#[test]
fn test_branch_lt_taken() {
    // Condition LT (SF=1) - devrait prendre le branchement
    let mut cpu = TestCpu::with_flags(false, true, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH LT, R1, 10
    cpu.execute_branch(Register::R1, Condition::Lt, 10).unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_lt_not_taken() {
    // Condition LT (SF=1) - ne devrait pas prendre le branchement car SF=0
    let mut cpu = TestCpu::with_flags(false, false, false);
    let initial_pc = Word::from_int(0);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH LT, R1, 10
    cpu.execute_branch(Register::R1, Condition::Lt, 10).unwrap();

    // Vérifier que le PC n'a pas changé
    assert_eq!(cpu.read_pc(), initial_pc);
}

#[test]
fn test_branch_ge_taken() {
    // Condition GE (SF=0) - devrait prendre le branchement
    let mut cpu = TestCpu::with_flags(false, false, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH GE, R1, 10
    cpu.execute_branch(Register::R1, Condition::Ge, 10).unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_ge_not_taken() {
    // Condition GE (SF=0) - ne devrait pas prendre le branchement car SF=1
    let mut cpu = TestCpu::with_flags(false, true, false);
    let initial_pc = Word::from_int(0);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH GE, R1, 10
    cpu.execute_branch(Register::R1, Condition::Ge, 10).unwrap();

    // Vérifier que le PC n'a pas changé
    assert_eq!(cpu.read_pc(), initial_pc);
}

#[test]
fn test_branch_special_taken() {
    // Condition Special (XF=1) - devrait prendre le branchement
    let mut cpu = TestCpu::with_flags(false, false, true);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH Special, R1, 10
    cpu.execute_branch(Register::R1, Condition::Special, 10)
        .unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_special_not_taken() {
    // Condition Special (XF=1) - ne devrait pas prendre le branchement car XF=0
    let mut cpu = TestCpu::with_flags(false, false, false);
    let initial_pc = Word::from_int(0);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH Special, R1, 10
    cpu.execute_branch(Register::R1, Condition::Special, 10)
        .unwrap();

    // Vérifier que le PC n'a pas changé
    assert_eq!(cpu.read_pc(), initial_pc);
}

#[test]
fn test_branch_always_taken() {
    // Condition Always - devrait toujours prendre le branchement
    let mut cpu = TestCpu::with_flags(false, false, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH Always, R1, 10
    cpu.execute_branch(Register::R1, Condition::Always, 10)
        .unwrap();

    // Vérifier que le PC a été mis à jour (100 + 10 = 110)
    assert_eq!(cpu.read_pc(), Word::from_int(110));
}

#[test]
fn test_branch_negative_offset() {
    // Test avec un offset négatif
    let mut cpu = TestCpu::with_flags(true, false, false);

    // Configurer le registre de base (R1) avec une adresse
    cpu.write_gpr(Register::R1, Word::from_int(100));

    // Exécuter BRANCH EQ, R1, -10
    cpu.execute_branch(Register::R1, Condition::Eq, -10)
        .unwrap();

    // Vérifier que le PC a été mis à jour (100 - 10 = 90)
    assert_eq!(cpu.read_pc(), Word::from_int(90));
}
