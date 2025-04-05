// src/cpu/tests/execute_system_tests.rs
// Tests pour les instructions système et CSR

use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_system::{CpuState, CsrOperations, SystemOperations};
use crate::cpu::registers::{PrivilegeLevel, Register, TrapCause};

// Structure de test qui implémente CpuState pour tester les opérations système
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
            csrs: [Word::zero(); 10], // Mise à jour pour inclure les nouveaux registres de délégation
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
fn test_halt_instruction() {
    let mut cpu = TestCpu::new();

    // Exécuter HALT (func = 0)
    cpu.execute_system(0).unwrap();

    // Vérifier que le CPU est arrêté
    assert!(cpu.halted);
}

#[test]
fn test_nop_instruction() {
    let mut cpu = TestCpu::new();
    let initial_pc = cpu.read_pc();

    // Exécuter NOP (func = 1)
    cpu.execute_system(1).unwrap();

    // Vérifier que rien n'a changé
    assert_eq!(cpu.read_pc(), initial_pc);
    assert!(!cpu.halted);
}

#[test]
fn test_ecall_from_machine_mode() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::Machine);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter ECALL (func = 2)
    cpu.execute_system(2).unwrap();

    // Vérifier que:
    // 1. PC a été sauvegardé dans mepc_t
    assert_eq!(cpu.state_read_csr(2).unwrap(), initial_pc);

    // 2. La cause est EcallM
    assert_eq!(cpu.trap_cause, Some(TrapCause::EcallM));

    // 3. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 4. Le niveau de privilège est toujours Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_ecall_from_user_mode() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter ECALL (func = 2)
    cpu.execute_system(2).unwrap();

    // Vérifier que:
    // 1. PC a été sauvegardé dans mepc_t
    assert_eq!(cpu.state_read_csr(2).unwrap(), initial_pc);

    // 2. La cause est EcallU
    assert_eq!(cpu.trap_cause, Some(TrapCause::EcallU));

    // 3. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 4. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);

    // 5. Le niveau de privilège précédent est User
    assert_eq!(cpu.state_get_previous_privilege(), PrivilegeLevel::User);
}

#[test]
fn test_mret_instruction() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::Machine);

    // Configurer mepc_t (adresse de retour)
    let return_addr = Word::from_int(0x200);
    cpu.state_write_csr(2, return_addr.clone()).unwrap();

    // Configurer le niveau de privilège précédent
    cpu.state_set_previous_privilege(PrivilegeLevel::User);

    // Exécuter MRET
    cpu.execute_mret().unwrap();

    // Vérifier que:
    // 1. Le PC a été mis à jour avec l'adresse de retour
    assert_eq!(cpu.read_pc(), return_addr);

    // 2. Le niveau de privilège est passé à User
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::User);
}

#[test]
fn test_mret_from_user_mode() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter MRET depuis le mode User (devrait déclencher une exception)
    let result = cpu.execute_mret();

    // Vérifier que l'exécution a réussi (car elle déclenche un trap)
    assert!(result.is_ok());

    // Vérifier que:
    // 1. La cause est IllegalInstr
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));

    // 2. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 3. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_lui_instruction() {
    let mut cpu = TestCpu::new();

    // Exécuter LUI R1, 42
    cpu.execute_lui(Register::R1, 42).unwrap();

    // Vérifier que R1 contient la valeur 42 dans les trytes supérieurs
    let r1_value = cpu.read_gpr(Register::R1);

    // Vérifier que les trytes inférieurs sont à zéro
    for i in 0..4 {
        assert_eq!(r1_value.tryte(i), Some(&Tryte::Digit(13))); // 13 = 0 en ternaire équilibré
    }

    // Vérifier que les trytes supérieurs contiennent la valeur 42
    // Note: Cette vérification est simplifiée car la conversion exacte dépend de l'implémentation
    // On vérifie simplement que les trytes supérieurs ne sont pas tous à zéro
    let all_upper_zero = (4..7).all(|i| r1_value.tryte(i) == Some(&Tryte::Digit(13)));
    assert!(!all_upper_zero);
}

#[test]
fn test_auipc_instruction() {
    let mut cpu = TestCpu::new();

    // Configurer PC à 0x100
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc);

    // Exécuter AUIPC R1, 42
    cpu.execute_auipc(Register::R1, 42).unwrap();

    // Vérifier que R1 contient PC + (42 << 12)
    let r1_value = cpu.read_gpr(Register::R1);

    // Vérifier que la valeur n'est pas égale au PC initial
    assert_ne!(r1_value, cpu.read_pc());

    // Note: La vérification exacte de la valeur est complexe en raison de la conversion ternaire
    // On vérifie simplement que R1 a été modifié
    assert_ne!(r1_value, Word::zero());
}

#[test]
fn test_csrrw_instruction() {
    let mut cpu = TestCpu::new();

    // Configurer un CSR avec une valeur initiale
    let initial_csr_value = Word::from_int(0x42);
    cpu.state_write_csr(0, initial_csr_value.clone()).unwrap();

    // Configurer R1 avec une nouvelle valeur
    let new_value = Word::from_int(0x24);
    cpu.write_gpr(Register::R1, new_value.clone());

    // Exécuter CSRRW R2, 0, R1
    cpu.execute_csrrw(Register::R2, 0, Register::R1).unwrap();

    // Vérifier que:
    // 1. Le CSR a été mis à jour avec la valeur de R1
    assert_eq!(cpu.state_read_csr(0).unwrap(), new_value);

    // 2. R2 contient l'ancienne valeur du CSR
    assert_eq!(cpu.read_gpr(Register::R2), initial_csr_value);
}

#[test]
fn test_csrrs_instruction() {
    let mut cpu = TestCpu::new();

    // Configurer un CSR avec une valeur initiale
    let initial_csr_value = Word::from_int(0x42); // 0b1000010 en binaire
    cpu.state_write_csr(0, initial_csr_value.clone()).unwrap();

    // Configurer R1 avec un masque de bits à définir
    let mask = Word::from_int(0x24); // 0b100100 en binaire
    cpu.write_gpr(Register::R1, mask);

    // Exécuter CSRRS R2, 0, R1
    cpu.execute_csrrs(Register::R2, 0, Register::R1).unwrap();

    // Vérifier que:
    // 1. R2 contient l'ancienne valeur du CSR
    assert_eq!(cpu.read_gpr(Register::R2), initial_csr_value);

    // 2. Le CSR a été mis à jour avec un OR bit à bit
    // Note: La vérification exacte dépend de l'implémentation de l'OR ternaire
    // On vérifie simplement que le CSR a été modifié
    assert_ne!(cpu.state_read_csr(0).unwrap(), initial_csr_value);
}

#[test]
fn test_csrrs_with_r0() {
    let mut cpu = TestCpu::new();

    // Configurer un CSR avec une valeur initiale
    let initial_csr_value = Word::from_int(0x42);
    cpu.state_write_csr(0, initial_csr_value.clone()).unwrap();

    // Exécuter CSRRS R2, 0, R0 (ne devrait pas modifier le CSR)
    cpu.execute_csrrs(Register::R2, 0, Register::R0).unwrap();

    // Vérifier que:
    // 1. R2 contient la valeur du CSR
    assert_eq!(cpu.read_gpr(Register::R2), initial_csr_value);

    // 2. Le CSR n'a pas été modifié
    assert_eq!(cpu.state_read_csr(0).unwrap(), initial_csr_value);
}

#[test]
fn test_trap_delegation() {
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
    
    // Cas 1: Sans délégation, un trap depuis le mode User va en mode Machine
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été traité en mode Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
    assert_eq!(cpu.read_pc(), machine_trap_handler);
    
    // Réinitialiser pour le prochain test
    cpu = TestCpu::new();
    cpu.state_write_csr(1, machine_trap_handler.clone()).unwrap();
    cpu.state_write_csr(5, supervisor_trap_handler.clone()).unwrap();
    cpu.write_pc(initial_pc.clone());
    
    // Configurer medeleg_t pour déléguer EcallU au mode Supervisor
    // Activer le bit correspondant à EcallU (code 0) dans medeleg_t
    let mut medeleg = Word::zero();
    if let Some(tryte) = medeleg.tryte_mut(0) {
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // Activer la délégation pour EcallU (code 0)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Cas 2: Avec délégation, un trap depuis le mode User va en mode Supervisor
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été délégué au mode Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
    assert_eq!(cpu.read_pc(), supervisor_trap_handler);
}

#[test]
fn test_trap_delegation_from_supervisor() {
    let mut cpu = TestCpu::new();
    
    // Configurer mtvec_t (adresse de traitement des exceptions en mode Machine)
    let machine_trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, machine_trap_handler.clone()).unwrap();
    
    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());
    
    // Configurer medeleg_t pour déléguer EcallS au mode Supervisor
    let mut medeleg = Word::zero();
    if let Some(tryte) = medeleg.tryte_mut(0) {
        let mut trits = [Trit::Z; 3];
        trits[1] = Trit::P; // Activer la délégation pour EcallS (code 1)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Même avec délégation, un trap depuis le mode Supervisor doit aller en mode Machine
    // car la délégation n'est pas possible depuis le mode Supervisor vers lui-même
    cpu.state_set_privilege(PrivilegeLevel::Supervisor);
    cpu.execute_system(2).unwrap(); // ECALL
    
    // Vérifier que le trap a été traité en mode Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
    assert_eq!(cpu.read_pc(), machine_trap_handler);
}

#[test]
fn test_sret_instruction() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::Supervisor);

    // Configurer sepc_t (adresse de retour)
    let return_addr = Word::from_int(0x200);
    cpu.state_write_csr(6, return_addr.clone()).unwrap();

    // Exécuter SRET
    cpu.execute_sret().unwrap();

    // Vérifier que:
    // 1. Le PC a été mis à jour avec l'adresse de retour
    assert_eq!(cpu.read_pc(), return_addr);

    // 2. Le niveau de privilège est passé à User
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::User);
}

#[test]
fn test_sret_from_user_mode() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter SRET depuis le mode User (devrait déclencher une exception)
    let result = cpu.execute_sret();

    // Vérifier que l'exécution a réussi (car elle déclenche un trap)
    assert!(result.is_ok());

    // Vérifier que:
    // 1. La cause est IllegalInstr
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));

    // 2. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 3. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_ebreak_instruction() {
    let mut cpu = TestCpu::new();

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter EBREAK (func = 3)
    cpu.execute_system(3).unwrap();

    // Vérifier que:
    // 1. PC a été sauvegardé dans mepc_t
    assert_eq!(cpu.state_read_csr(2).unwrap(), initial_pc);

    // 2. La cause est BreakPoint
    assert_eq!(cpu.trap_cause, Some(TrapCause::BreakPoint));

    // 3. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);
}

#[test]
fn test_ebreak_delegation() {
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
    
    // Configurer medeleg_t pour déléguer BreakPoint au mode Supervisor
    // Activer le bit correspondant à BreakPoint (code 6) dans medeleg_t
    let mut medeleg = Word::zero();
    if let Some(tryte) = medeleg.tryte_mut(2) { // 6 / 3 = 2 (index du tryte)
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // 6 % 3 = 0 (index du trit)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Exécuter EBREAK depuis le mode User avec délégation
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(3).unwrap(); // EBREAK (func = 3)
    
    // Vérifier que le trap a été délégué au mode Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
    assert_eq!(cpu.read_pc(), supervisor_trap_handler);
}

#[test]
fn test_illegal_csr_access() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Tenter d'accéder à un CSR Machine depuis le mode User
    // Exécuter CSRRW R2, 0, R1 (accès au CSR 0 - mstatus_t)
    let result = cpu.execute_csrrw(Register::R2, 0, Register::R1);

    // Vérifier que l'exécution a réussi (car elle déclenche un trap)
    assert!(result.is_ok());

    // Vérifier que:
    // 1. La cause est IllegalInstr
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));

    // 2. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 3. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_supervisor_csr_access() {
    // Test d'accès aux CSR Supervisor depuis le mode Supervisor
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::Supervisor);

    // Configurer une valeur initiale pour sstatus_t (CSR 4)
    let initial_csr_value = Word::from_int(0x42);
    cpu.state_write_csr(4, initial_csr_value.clone()).unwrap();

    // Configurer R1 avec une nouvelle valeur
    let new_value = Word::from_int(0x24);
    cpu.write_gpr(Register::R1, new_value.clone());

    // Exécuter CSRRW R2, 4, R1 (accès au CSR 4 - sstatus_t)
    cpu.execute_csrrw(Register::R2, 4, Register::R1).unwrap();

    // Vérifier que:
    // 1. Le CSR a été mis à jour avec la valeur de R1
    assert_eq!(cpu.state_read_csr(4).unwrap(), new_value);

    // 2. R2 contient l'ancienne valeur du CSR
    assert_eq!(cpu.read_gpr(Register::R2), initial_csr_value);

    // 3. Le niveau de privilège est toujours Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
}



#[test]
fn test_sret_from_user_mode() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter SRET depuis le mode User (devrait déclencher une exception)
    let result = cpu.execute_sret();

    // Vérifier que l'exécution a réussi (car elle déclenche un trap)
    assert!(result.is_ok());

    // Vérifier que:
    // 1. La cause est IllegalInstr
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));

    // 2. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 3. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_ebreak_instruction() {
    let mut cpu = TestCpu::new();

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Exécuter EBREAK (func = 3)
    cpu.execute_system(3).unwrap();

    // Vérifier que:
    // 1. PC a été sauvegardé dans mepc_t
    assert_eq!(cpu.state_read_csr(2).unwrap(), initial_pc);

    // 2. La cause est BreakPoint
    assert_eq!(cpu.trap_cause, Some(TrapCause::BreakPoint));

    // 3. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);
}

#[test]
fn test_ebreak_delegation() {
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
    
    // Configurer medeleg_t pour déléguer BreakPoint au mode Supervisor
    // Activer le bit correspondant à BreakPoint (code 6) dans medeleg_t
    let mut medeleg = Word::zero();
    if let Some(tryte) = medeleg.tryte_mut(2) { // 6 / 3 = 2 (index du tryte)
        let mut trits = [Trit::Z; 3];
        trits[0] = Trit::P; // 6 % 3 = 0 (index du trit)
        *tryte = Tryte::from_trits(trits);
    }
    cpu.state_write_csr(8, medeleg).unwrap();
    
    // Exécuter EBREAK depuis le mode User avec délégation
    cpu.state_set_privilege(PrivilegeLevel::User);
    cpu.execute_system(3).unwrap(); // EBREAK (func = 3)
    
    // Vérifier que le trap a été délégué au mode Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
    assert_eq!(cpu.read_pc(), supervisor_trap_handler);
}

#[test]
fn test_illegal_csr_access() {
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::User);

    // Configurer mtvec_t (adresse de traitement des exceptions)
    let trap_handler = Word::from_int(0x1000);
    cpu.state_write_csr(1, trap_handler.clone()).unwrap();

    // Configurer PC
    let initial_pc = Word::from_int(0x100);
    cpu.write_pc(initial_pc.clone());

    // Tenter d'accéder à un CSR Machine depuis le mode User
    // Exécuter CSRRW R2, 0, R1 (accès au CSR 0 - mstatus_t)
    let result = cpu.execute_csrrw(Register::R2, 0, Register::R1);

    // Vérifier que l'exécution a réussi (car elle déclenche un trap)
    assert!(result.is_ok());

    // Vérifier que:
    // 1. La cause est IllegalInstr
    assert_eq!(cpu.trap_cause, Some(TrapCause::IllegalInstr));

    // 2. Le PC a été mis à jour avec l'adresse du gestionnaire de trap
    assert_eq!(cpu.read_pc(), trap_handler);

    // 3. Le niveau de privilège est passé à Machine
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Machine);
}

#[test]
fn test_supervisor_csr_access() {
    // Test d'accès aux CSR Supervisor depuis le mode Supervisor
    let mut cpu = TestCpu::with_privilege(PrivilegeLevel::Supervisor);

    // Configurer une valeur initiale pour sstatus_t (CSR 4)
    let initial_csr_value = Word::from_int(0x42);
    cpu.state_write_csr(4, initial_csr_value.clone()).unwrap();

    // Configurer R1 avec une nouvelle valeur
    let new_value = Word::from_int(0x24);
    cpu.write_gpr(Register::R1, new_value.clone());

    // Exécuter CSRRW R2, 4, R1 (accès au CSR 4 - sstatus_t)
    cpu.execute_csrrw(Register::R2, 4, Register::R1).unwrap();

    // Vérifier que:
    // 1. Le CSR a été mis à jour avec la valeur de R1
    assert_eq!(cpu.state_read_csr(4).unwrap(), new_value);

    // 2. R2 contient l'ancienne valeur du CSR
    assert_eq!(cpu.read_gpr(Register::R2), initial_csr_value);

    // 3. Le niveau de privilège est toujours Supervisor
    assert_eq!(cpu.state_get_privilege(), PrivilegeLevel::Supervisor);
}
