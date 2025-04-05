// src/cpu/tests/delegation_tests.rs
// Tests pour les fonctionnalités de délégation des traps et des interruptions

use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_system::{CpuState, CsrOperations, DelegationOperations, SystemOperations};
use crate::cpu::registers::{PrivilegeLevel, Register, TrapCause};
use crate::cpu::supervisor_privilege::SupervisorPrivilegeOperations;

// Structure de test qui implémente CpuState pour tester les opérations de délégation
struct TestCpu {
    pc: Word,
    registers: [Word; 8],
    halted: bool,
    privilege: PrivilegeLevel,
    previous_privilege: PrivilegeLevel,
    csrs: [Word; 10], // mstatus_t, mtvec_t, mepc_t, mcause_t, sstatus_t, stvec_t, sepc_t, scause_t, medeleg_t, mideleg_t
    trap_cause: Option<TrapCause>,
}

impl TestCpu {
    fn new() -> Self {
        TestCpu {
            pc: Word::from_int(0),
            registers: [Word::from_int(0); 8],
            halted: false,
            privilege: PrivilegeLevel::Machine,
            previous_privilege: PrivilegeLevel::User,
            csrs: [Word::zero(); 10],
            trap_cause: None,
        }
    }

    fn with_privilege(privilege: PrivilegeLevel) -> Self {
        let mut cpu = Self::new();
        cpu.privilege = privilege;
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

    fn set_halted(&mut self, halted: bool) {
        self.halted = halted;
    }

    fn state_read_csr(&self, csr: i8) -> Result<Word, crate::cpu::registers::RegisterError> {
        if csr >= 0 && csr < 10 {
            Ok(self.csrs[csr as usize].clone())
        } else {
            Err(crate::cpu::registers::RegisterError::InvalidIndex)
        }
    }

    fn state_write_csr(
        &mut self,
        csr: i8,
        value: Word,
    ) -> Result<(), crate::cpu::registers::RegisterError> {
        if csr >= 0 && csr < 10 {
            self.csrs[csr as usize] = value;
            Ok(())
        } else {
            Err(crate::cpu::registers::RegisterError::InvalidIndex)
        }
    }

    fn state_set_csr(
        &mut self,
        csr: i8,
        value: Word,
    ) -> Result<(), crate::cpu::registers::RegisterError> {
        if csr >= 0 && csr < 10 {
            let current = self.csrs[csr as usize].clone();
            let mut result = current.clone();

            // Effectuer un OR bit à bit entre les trytes
            for i in 0..8 {
                if let (Some(current_tryte), Some(value_tryte)) = (current.tryte(i), value.tryte(i))
                {
                    if let (Tryte::Digit(current_val), Tryte::Digit(value_val)) =
                        (current_tryte, value_tryte)
                    {
                        // Convertir en valeurs Bal3
                        let current_bal3 = (*current_val as i8) - 13;
                        let value_bal3 = (*value_val as i8) - 13;

                        // Effectuer l'opération OR sur les trits individuels
                        let mut result_trits = [Trit::Z; 3];
                        let current_trits = Tryte::Digit(*current_val).to_trits();
                        let value_trits = Tryte::Digit(*value_val).to_trits();

                        for j in 0..3 {
                            // OR ternaire: max(a, b)
                            result_trits[j] = match (current_trits[j], value_trits[j]) {
                                (Trit::P, _) | (_, Trit::P) => Trit::P,
                                (Trit::Z, Trit::Z) => Trit::Z,
                                (Trit::N, Trit::Z) | (Trit::Z, Trit::N) => Trit::Z,
                                (Trit::N, Trit::N) => Trit::N,
                            };
                        }

                        // Convertir les trits en tryte
                        let result_tryte = Tryte::from_trits(result_trits);
                        if let Some(tryte) = result.tryte_mut(i) {
                            *tryte = result_tryte;
                        }
                    }
                }
            }

            self.csrs[csr as usize] = result;
            Ok(())
        } else {
            Err(crate::cpu::registers::RegisterError::InvalidIndex)
        }
    }

    fn state_get_privilege(&self) -> PrivilegeLevel {
        self.privilege
    }

    fn state_set_privilege(&mut self, privilege: PrivilegeLevel) {
        self.privilege = privilege;
    }

    fn state_get_previous_privilege(&self) -> PrivilegeLevel {
        self.previous_privilege
    }

    fn state_set_previous_privilege(&mut self, privilege: PrivilegeLevel) {
        self.previous_privilege = privilege;
    }

    fn state_set_trap_cause(&mut self, cause: TrapCause) {
        self.trap_cause = Some(cause);

        // Mettre à jour mcause_t (CSR 3)
        let code = cause.to_code();
        let mut cause_word = Word::zero();
        if let Some(tryte) = cause_word.tryte_mut(0) {
            // Convertir le code en ternaire équilibré (ajouter 13)
            *tryte = Tryte::Digit((code + 13) as u8);
        }
        self.csrs[3] = cause_word;
    }

    fn read_flags(&self) -> crate::cpu::registers::Flags {
        crate::cpu::registers::Flags::new() // Simplifié pour les tests
    }
}

#[test]
fn test_is_trap_delegated() {
    let mut cpu = TestCpu::new();
    
    // Par défaut, aucun trap n'est délégué
    assert!(!cpu.is_trap_delegated(TrapCause::EcallU));
    assert!(!cpu.is_trap_delegated(TrapCause::IllegalInstr));
    assert!(!cpu.is_trap_delegated(TrapCause::BreakPoint));
    
    // Configurer medeleg_t pour déléguer EcallU (code 0)
    let mut medeleg = Word::zero();
    if let Some(tryte) = medeleg.tryte_mut(0) {
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // Activer la délégation pour EcallU (code 0)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Vérifier que EcallU est maintenant délégué
    assert!(cpu.is_trap_delegated(TrapCause::EcallU));
    
    // Mais pas les autres causes
    assert!(!cpu.is_trap_delegated(TrapCause::IllegalInstr));
    assert!(!cpu.is_trap_delegated(TrapCause::BreakPoint));
    
    // Configurer medeleg_t pour déléguer aussi IllegalInstr (code 3)
    let mut medeleg = cpu.state_read_csr(8).unwrap();
    if let Some(tryte) = medeleg.tryte_mut(1) { // 3 / 3 = 1 (index du tryte)
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // 3 % 3 = 0 (index du trit)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Vérifier que EcallU et IllegalInstr sont maintenant délégués
    assert!(cpu.is_trap_delegated(TrapCause::EcallU));
    assert!(cpu.is_trap_delegated(TrapCause::IllegalInstr));
    assert!(!cpu.is_trap_delegated(TrapCause::BreakPoint));
}

#[test]
fn test_is_interrupt_delegated() {
    let mut cpu = TestCpu::new();
    
    // Par défaut, aucune interruption n'est déléguée
    assert!(!cpu.is_interrupt_delegated(0)); // Timer interrupt
    assert!(!cpu.is_interrupt_delegated(1)); // External interrupt
    assert!(!cpu.is_interrupt_delegated(2)); // Software interrupt
    
    // Configurer mideleg_t pour déléguer l'interruption timer (code 0)
    let mut mideleg = Word::zero();
    if let Some(tryte) = mideleg.tryte_mut(0) {
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // Activer la délégation pour l'interruption timer (code 0)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(9, mideleg).unwrap();
    
    // Vérifier que l'interruption timer est maintenant déléguée
    assert!(cpu.is_interrupt_delegated(0));
    
    // Mais pas les autres interruptions
    assert!(!cpu.is_interrupt_delegated(1));
    assert!(!cpu.is_interrupt_delegated(2));
    
    // Configurer mideleg_t pour déléguer aussi l'interruption externe (code 1)
    let mut mideleg = cpu.state_read_csr(9).unwrap();
    if let Some(tryte) = mideleg.tryte_mut(0) { // 1 / 3 = 0 (index du tryte)
        let mut trits = Tryte::Digit(*mideleg.tryte(0).unwrap().as_digit().unwrap()).to_trits();
        trits[1] = Trit::P; // 1 % 3 = 1 (index du trit)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(9, mideleg).unwrap();
    
    // Vérifier que les interruptions timer et externe sont maintenant déléguées
    assert!(cpu.is_interrupt_delegated(0));
    assert!(cpu.is_interrupt_delegated(1));
    assert!(!cpu.is_interrupt_delegated(2));
}

#[test]
fn test_set_trap_delegation() {
    let mut cpu = TestCpu::new();
    
    // Configurer la délégation pour EcallU
    cpu.set_trap_delegation(TrapCause::EcallU, true).unwrap();
    
    // Vérifier que EcallU est maintenant délégué
    assert!(cpu.is_trap_delegated(TrapCause::EcallU));
    
    // Désactiver la délégation pour EcallU
    cpu.set_trap_delegation(TrapCause::EcallU, false).unwrap();
    
    // Vérifier que EcallU n'est plus délégué
    assert!(!cpu.is_trap_delegated(TrapCause::EcallU));
    
    // Configurer la délégation pour plusieurs causes
    cpu.set_trap_delegation(TrapCause::EcallU, true).unwrap();
    cpu.set_trap_delegation(TrapCause::IllegalInstr, true).unwrap();
    cpu.set_trap_delegation(TrapCause::BreakPoint, true).unwrap();
    
    // Vérifier que toutes les causes sont déléguées
    assert!(cpu.is_trap_delegated(TrapCause::EcallU));
    assert!(cpu.is_trap_delegated(TrapCause::IllegalInstr));
    assert!(cpu.is_trap_delegated(TrapCause::BreakPoint));
}

#[test]
fn test_set_interrupt_delegation() {
    let mut cpu = TestCpu::new();
    
    // Configurer la délégation pour l'interruption timer
    cpu.set_interrupt_delegation(0, true).unwrap();
    
    // Vérifier que l'interruption timer est maintenant déléguée
    assert!(cpu.is_interrupt_delegated(0));
    
    // Désactiver la délégation pour l'interruption timer
    cpu.set_interrupt_delegation(0, false).unwrap();
    
    // Vérifier que l'interruption timer n'est plus déléguée
    assert!(!cpu.is_interrupt_delegated(0));
    
    // Configurer la délégation pour plusieurs interruptions
    cpu.set_interrupt_delegation(0, true).unwrap(); // Timer
    cpu.set_interrupt_delegation(1, true).unwrap(); // External
    cpu.set_interrupt_delegation(2, true).unwrap(); // Software
    
    // Vérifier que toutes les interruptions sont déléguées
    assert!(cpu.is_interrupt_delegated(0));
    assert!(cpu.is_interrupt_delegated(1));
    assert!(cpu.is_interrupt_delegated(2));
}

#[test]
fn test_privilege_violation_delegation() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);
    
    // Tenter de configurer la délégation depuis le mode User (devrait échouer)
    let result = cpu.set_trap_delegation(TrapCause::EcallU, true);
    
    // Vérifier que l'opération a déclenché un trap
    assert!(result.is_ok()); // L'opération réussit car elle déclenche un trap
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));
    
    // Réinitialiser pour le prochain test
    cpu = TestCpu::with_privilege(PrivilegeLevel::Supervisor);
    
    // Tenter de configurer la délégation depuis le mode Supervisor (devrait échouer)
    let result = cpu.set_trap_delegation(TrapCause::EcallU, true);
    
    // Vérifier que l'opération a déclenché un trap
    assert!(result.is_ok()); // L'opération réussit car elle déclenche un trap
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));
}

#[test]
fn test_ecall_delegation_chain() {
    let mut cpu = TestCpu::new();
    
    // Configurer mtvec_t (adresse de traitement des exceptions en mode Machine)
    let machine_trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, machine_trap_handler.clone()).unwrap();
    
    // Configurer stvec_t (adresse de traitement des exceptions en mode Supervisor)
    let supervisor_trap_handler = Word::from_int(0x2000);
    cpu.state_write_csr(5, supervisor_trap_handler.clone()).unwrap();
    
    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());
    
    // Configurer medeleg_t pour déléguer EcallU au mode Supervisor
    cpu.set_trap_delegation(TrapCause::EcallU, true).unwrap();
    
    // Exécuter ECALL depuis le mode User
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été délégué au mode Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
    assert_eq!(cpu.read_pc(), supervisor_trap_handler);
    
    // Exécuter ECALL depuis le mode Supervisor
    let new_pc = Word::from_int(0x200);
    cpu.write_pc(new_pc.clone());
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été traité en mode Machine
    // (car les traps depuis le mode Supervisor ne peuvent pas être délégués au mode Supervisor)
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
    assert_eq!(cpu.read_pc(), machine_trap_handler);
}

#[test]
fn test_delegation_with_supervisor_return() {
    let mut cpu = TestCpu::new();
    
    // Configurer mtvec_t et stvec_t
    let machine_trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, machine_trap_handler.clone()).unwrap();
    
    let supervisor_trap_handler = Word::from_int(0x2000);
    cpu.state_write_csr(5, supervisor_trap_handler.clone()).unwrap();
    
    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());
    
    // Configurer medeleg_t pour déléguer EcallU au mode Supervisor
    cpu.set_trap_delegation(TrapCause::EcallU, true).unwrap();
    
    // Exécuter ECALL depuis le mode User
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été délégué au mode Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
    assert_eq!(cpu.read_pc(), supervisor_trap_handler);
    
    // Configurer sepc_t pour le retour
    let return_addr = Word::from_int(0x300);
    cpu.state_write_csr(6, return_addr.clone()).unwrap();
    
    // Exécuter SRET pour retourner au mode User
    cpu.execute_sret().unwrap();
    
    // Vérifier que le retour s'est effectué correctement
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::User);
    assert_eq!(cpu.read_pc(), return_addr);
}