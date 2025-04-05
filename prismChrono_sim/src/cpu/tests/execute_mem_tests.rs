// src/cpu/tests/execute_mem_tests.rs
// Tests pour les instructions de mémoire (LOAD/STORE)

use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_mem::MemoryOperations;
use crate::cpu::registers::Register;
use crate::memory::Memory;

// Trait CpuState pour les opérations mémoire
pub trait CpuState {
    fn read_gpr(&self, reg: Register) -> Word;
    fn write_gpr(&mut self, reg: Register, value: Word);
    fn memory(&self) -> &Memory;
    fn memory_mut(&mut self) -> &mut Memory;
}

// Structure de test qui implémente CpuState pour tester les opérations mémoire
struct TestCpu {
    registers: [Word; 8],
    memory: Memory,
}

impl TestCpu {
    fn new() -> Self {
        TestCpu {
            registers: [Word::from_int(0); 8],
            memory: Memory::new(256), // Petite mémoire pour les tests
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

    fn memory(&self) -> &Memory {
        &self.memory
    }

    fn memory_mut(&mut self) -> &mut Memory {
        &mut self.memory
    }
}

#[test]
fn test_load_word() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à charger en mémoire
    let test_word = Word::from_int(42);
    let addr = 100;

    // Écrire la valeur en mémoire
    cpu.memory.write_word(addr, test_word.clone()).unwrap();

    // Configurer le registre d'adresse
    cpu.write_gpr(Register::R1, Word::from_int(addr));

    // Exécuter LOAD R2, R1, 0
    cpu.execute_load(Register::R2, Register::R1, 0).unwrap();

    // Vérifier que la valeur a été chargée correctement
    assert_eq!(cpu.read_gpr(Register::R2), test_word);
}

#[test]
fn test_load_with_offset() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à charger en mémoire
    let test_word = Word::from_int(42);
    let base_addr = 100;
    let offset = 4;

    // Écrire la valeur en mémoire
    cpu.memory
        .write_word(base_addr + offset, test_word.clone())
        .unwrap();

    // Configurer le registre d'adresse
    cpu.write_gpr(Register::R1, Word::from_int(base_addr));

    // Exécuter LOAD R2, R1, offset
    cpu.execute_load(Register::R2, Register::R1, offset as i8)
        .unwrap();

    // Vérifier que la valeur a été chargée correctement
    assert_eq!(cpu.read_gpr(Register::R2), test_word);
}

#[test]
fn test_store_word() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à stocker
    let test_word = Word::from_int(42);
    let addr = 100;

    // Configurer les registres
    cpu.write_gpr(Register::R1, Word::from_int(addr)); // Adresse
    cpu.write_gpr(Register::R2, test_word.clone()); // Valeur à stocker

    // Exécuter STORE R1, R2, 0
    cpu.execute_store(Register::R1, Register::R2, 0).unwrap();

    // Vérifier que la valeur a été stockée correctement
    let stored_word = cpu.memory.read_word(addr).unwrap();
    assert_eq!(stored_word, test_word);
}

#[test]
fn test_store_with_offset() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à stocker
    let test_word = Word::from_int(42);
    let base_addr = 100;
    let offset = 4;

    // Configurer les registres
    cpu.write_gpr(Register::R1, Word::from_int(base_addr)); // Adresse de base
    cpu.write_gpr(Register::R2, test_word.clone()); // Valeur à stocker

    // Exécuter STORE R1, R2, offset
    cpu.execute_store(Register::R1, Register::R2, offset as i8)
        .unwrap();

    // Vérifier que la valeur a été stockée correctement
    let stored_word = cpu.memory.read_word(base_addr + offset).unwrap();
    assert_eq!(stored_word, test_word);
}

#[test]
fn test_load_tryte() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à charger en mémoire
    let test_tryte = Tryte::from_int(9); // Valeur 9 en ternaire équilibré
    let addr = 100;

    // Écrire la valeur en mémoire
    cpu.memory.write_tryte(addr, test_tryte.clone()).unwrap();

    // Configurer le registre d'adresse
    cpu.write_gpr(Register::R1, Word::from_int(addr));

    // Exécuter LOAD.T R2, R1, 0
    cpu.execute_load_tryte(Register::R2, Register::R1, 0)
        .unwrap();

    // Vérifier que la valeur a été chargée correctement (avec extension de signe)
    let result = cpu.read_gpr(Register::R2);

    // Vérifier que le premier tryte est correct
    assert_eq!(result.tryte(0).unwrap(), &test_tryte);

    // Vérifier que les autres trytes sont des extensions de signe
    // (tous identiques au signe du premier tryte)
    let sign_tryte = if test_tryte.is_negative() {
        Tryte::from_int(-13) // Tryte négatif maximal (-1 en décimal)
    } else {
        Tryte::from_int(0) // Tryte zéro
    };

    for i in 1..8 {
        assert_eq!(result.tryte(i).unwrap(), &sign_tryte);
    }
}

#[test]
fn test_load_tryte_unsigned() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à charger en mémoire
    let test_tryte = Tryte::from_int(9); // Valeur 9 en ternaire équilibré
    let addr = 100;

    // Écrire la valeur en mémoire
    cpu.memory.write_tryte(addr, test_tryte.clone()).unwrap();

    // Configurer le registre d'adresse
    cpu.write_gpr(Register::R1, Word::from_int(addr));

    // Exécuter LOAD.TU R2, R1, 0
    cpu.execute_load_tryte_unsigned(Register::R2, Register::R1, 0)
        .unwrap();

    // Vérifier que la valeur a été chargée correctement (sans extension de signe)
    let result = cpu.read_gpr(Register::R2);

    // Vérifier que le premier tryte est correct
    assert_eq!(result.tryte(0).unwrap(), &test_tryte);

    // Vérifier que les autres trytes sont zéro (pas d'extension de signe)
    let zero_tryte = Tryte::from_int(0);
    for i in 1..8 {
        assert_eq!(result.tryte(i).unwrap(), &zero_tryte);
    }
}

#[test]
fn test_store_tryte() {
    let mut cpu = TestCpu::new();

    // Préparer une valeur à stocker
    let test_word = Word::from_int(42);
    let addr = 100;

    // Configurer les registres
    cpu.write_gpr(Register::R1, Word::from_int(addr)); // Adresse
    cpu.write_gpr(Register::R2, test_word.clone()); // Valeur à stocker

    // Exécuter STORE.T R1, R2, 0
    cpu.execute_store_tryte(Register::R1, Register::R2, 0)
        .unwrap();

    // Vérifier que seul le premier tryte a été stocké
    let stored_tryte = cpu.memory.read_tryte(addr).unwrap();
    assert_eq!(stored_tryte, *test_word.tryte(0).unwrap());
}
