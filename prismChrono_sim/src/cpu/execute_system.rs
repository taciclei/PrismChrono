// src/cpu/execute_system.rs
// Implémentation des instructions système et spéciales pour l'architecture PrismChrono
//
// Ce module implémente un système de privilèges à trois niveaux :
// - Mode Machine (M-mode) : niveau le plus privilégié, accès complet au matériel et aux CSRs
// - Mode Supervisor (S-mode) : niveau intermédiaire, utilisé par le système d'exploitation
// - Mode User (U-mode) : niveau le moins privilégié, utilisé par les applications
//
// Chaque niveau de privilège dispose de ses propres registres CSR :
// - CSRs Machine (0-3) : mstatus_t, mtvec_t, mepc_t, mcause_t
// - CSRs Supervisor (4-7) : sstatus_t, stvec_t, sepc_t, scause_t
//
// Les traps (exceptions, interruptions, appels système) peuvent être délégués
// du mode Machine au mode Supervisor selon certaines conditions.

use crate::alu::add_24_trits;
use crate::core::{Trit, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::registers::{PrivilegeLevel, Register, TrapCause};
use crate::cpu::state::CpuState;
use crate::cpu::supervisor_privilege::SupervisorPrivilegeOperations;

/// Fonctions utilitaires pour la gestion des registres de délégation
pub trait DelegationOperations {
    /// Vérifie si une cause de trap est déléguée au mode Supervisor
    fn is_trap_delegated(&self, cause: TrapCause) -> bool;
    
    /// Vérifie si une interruption est déléguée au mode Supervisor
    fn is_interrupt_delegated(&self, interrupt_code: i8) -> bool;
    
    /// Configure la délégation d'une cause de trap au mode Supervisor
    fn set_trap_delegation(&mut self, cause: TrapCause, delegated: bool) -> Result<(), ExecuteError>;
    
    /// Configure la délégation d'une interruption au mode Supervisor
    fn set_interrupt_delegation(&mut self, interrupt_code: i8, delegated: bool) -> Result<(), ExecuteError>;
}

/// Implémentation des opérations de délégation pour le CPU
impl<T: CpuState> DelegationOperations for T {
    /// Vérifie si une cause de trap est déléguée au mode Supervisor
    fn is_trap_delegated(&self, cause: TrapCause) -> bool {
        // Lire medeleg_t (registre de délégation des exceptions)
        let medeleg = match self.state_read_csr(8) {
            Ok(value) => value,
            Err(_) => return false,
        };
        
        // Vérifier si le bit correspondant à la cause est activé
        let cause_code = cause.to_code();
        if cause_code >= 0 && cause_code < 24 {
            // Extraire le trit correspondant à la cause
            let tryte_index = cause_code / 3;
            let trit_index = cause_code % 3;
            
            if let Some(tryte) = medeleg.tryte(tryte_index as usize) {
                if let Tryte::Digit(val) = tryte {
                    let trits = Tryte::Digit(*val).to_trits();
                    // Si le trit est P, la délégation est activée
                    return trits[trit_index as usize] == Trit::P;
                }
            }
        }
        
        false
    }
    
    /// Vérifie si une interruption est déléguée au mode Supervisor
    fn is_interrupt_delegated(&self, interrupt_code: i8) -> bool {
        // Lire mideleg_t (registre de délégation des interruptions)
        let mideleg = match self.state_read_csr(9) {
            Ok(value) => value,
            Err(_) => return false,
        };
        
        // Vérifier si le bit correspondant à l'interruption est activé
        if interrupt_code >= 0 && interrupt_code < 24 {
            // Extraire le trit correspondant à l'interruption
            let tryte_index = interrupt_code / 3;
            let trit_index = interrupt_code % 3;
            
            if let Some(tryte) = mideleg.tryte(tryte_index as usize) {
                if let Tryte::Digit(val) = tryte {
                    let trits = Tryte::Digit(*val).to_trits();
                    // Si le trit est P, la délégation est activée
                    return trits[trit_index as usize] == Trit::P;
                }
            }
        }
        
        false
    }
    
    /// Configure la délégation d'une cause de trap au mode Supervisor
    fn set_trap_delegation(&mut self, cause: TrapCause, delegated: bool) -> Result<(), ExecuteError> {
        // Vérifier que nous sommes en mode Machine
        if self.get_privilege() != PrivilegeLevel::Machine {
            return self.handle_trap(TrapCause::IllegalInstr);
        }
        
        // Lire medeleg_t
        let mut medeleg = match self.state_read_csr(8) {
            Ok(value) => value,
            Err(_) => Word::zero(),
        };
        
        // Modifier le bit correspondant à la cause
        let cause_code = cause.to_code();
        if cause_code >= 0 && cause_code < 24 {
            // Calculer l'index du tryte et du trit
            let tryte_index = cause_code / 3;
            let trit_index = cause_code % 3;
            
            if let Some(tryte) = medeleg.tryte(tryte_index as usize) {
                if let Tryte::Digit(val) = tryte {
                    let mut trits = Tryte::Digit(*val).to_trits();
                    
                    // Modifier le trit correspondant
                    trits[trit_index as usize] = if delegated { Trit::P } else { Trit::Z };
                    
                    // Convertir les trits en tryte et mettre à jour medeleg_t
                    let new_tryte = Tryte::from_trits(trits);
                    if let Some(tryte_mut) = medeleg.tryte_mut(tryte_index as usize) {
                        *tryte_mut = new_tryte;
                    }
                }
            }
            
            // Écrire la nouvelle valeur dans medeleg_t
            self.write_csr(8, medeleg)
        } else {
            Err(ExecuteError::InvalidInstruction)
        }
    }
    
    /// Configure la délégation d'une interruption au mode Supervisor
    fn set_interrupt_delegation(&mut self, interrupt_code: i8, delegated: bool) -> Result<(), ExecuteError> {
        // Vérifier que nous sommes en mode Machine
        if self.get_privilege() != PrivilegeLevel::Machine {
            return self.handle_trap(TrapCause::IllegalInstr);
        }
        
        // Lire mideleg_t
        let mut mideleg = match self.state_read_csr(9) {
            Ok(value) => value,
            Err(_) => Word::zero(),
        };
        
        // Modifier le bit correspondant à l'interruption
        if interrupt_code >= 0 && interrupt_code < 24 {
            // Calculer l'index du tryte et du trit
            let tryte_index = interrupt_code / 3;
            let trit_index = interrupt_code % 3;
            
            if let Some(tryte) = mideleg.tryte(tryte_index as usize) {
                if let Tryte::Digit(val) = tryte {
                    let mut trits = Tryte::Digit(*val).to_trits();
                    
                    // Modifier le trit correspondant
                    trits[trit_index as usize] = if delegated { Trit::P } else { Trit::Z };
                    
                    // Convertir les trits en tryte et mettre à jour mideleg_t
                    let new_tryte = Tryte::from_trits(trits);
                    if let Some(tryte_mut) = mideleg.tryte_mut(tryte_index as usize) {
                        *tryte_mut = new_tryte;
                    }
                }
            }
            
            // Écrire la nouvelle valeur dans mideleg_t
            self.write_csr(9, mideleg)
        } else {
            Err(ExecuteError::InvalidInstruction)
        }
    }
}

/// Trait pour les opérations système et spéciales
pub trait SystemOperations {
    /// Exécute une instruction système
    fn execute_system(&mut self, func: i8) -> Result<(), ExecuteError>;

    /// Exécute une instruction LUI (Load Upper Immediate)
    fn execute_lui(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError>;

    /// Exécute une instruction AUIPC (Add Upper Immediate to PC)
    fn execute_auipc(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError>;

    /// Exécute une instruction MRET (Machine Return)
    fn execute_mret(&mut self) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction SRET (Supervisor Return)
    fn execute_sret(&mut self) -> Result<(), ExecuteError>;
    
    /// Exécute une instruction EBREAK (Environment BREAK)
    fn execute_ebreak(&mut self) -> Result<(), ExecuteError>;
}

/// Trait pour les opérations sur les registres de contrôle et de statut (CSR)
pub trait CsrOperations: CpuState + SupervisorPrivilegeOperations {
    /// Lit la valeur d'un CSR
    fn read_csr(&self, csr: i8) -> Result<Word, ExecuteError>;

    /// Écrit une valeur dans un CSR
    fn write_csr(&mut self, csr: i8, value: Word) -> Result<(), ExecuteError>;

    /// Exécute une instruction CSRRW (CSR Read & Write)
    fn execute_csrrw(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError>;

    /// Exécute une instruction CSRRS (CSR Read & Set)
    fn execute_csrrs(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError>;

    /// Exécute une instruction CSRRC (CSR Read & Clear)
    fn execute_csrrc(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError>;

    /// Exécute une instruction CSR avec un immédiat
    fn execute_csr_imm(&mut self, csr: u8, rd: Register, imm: i16) -> Result<(), ExecuteError>;

    /// Vérifie si l'accès à un CSR est autorisé
    fn check_csr_access(&self, csr: i8, write: bool) -> Result<(), ExecuteError>;

    /// Obtient le niveau de privilège actuel
    fn get_privilege(&self) -> PrivilegeLevel;

    /// Définit le niveau de privilège actuel
    fn set_privilege(&mut self, privilege: PrivilegeLevel);

    /// Obtient le niveau de privilège précédent à partir de mstatus_t.MPP_t
    fn get_previous_privilege(&self) -> PrivilegeLevel;

    /// Définit le niveau de privilège précédent dans mstatus_t.MPP_t
    fn set_previous_privilege(&mut self, privilege: PrivilegeLevel);

    /// Lit la valeur de mepc_t
    fn read_mepc(&self) -> Word;

    /// Écrit une valeur dans mepc_t
    fn write_mepc(&mut self, value: Word);
    
    /// Lit la valeur de sepc_t
    fn read_sepc(&self) -> Word;

    /// Écrit une valeur dans sepc_t
    fn write_sepc(&mut self, value: Word);

    /// Gère un trap (exception/syscall)
    fn handle_trap(&mut self, _cause: TrapCause) -> Result<(), ExecuteError>;
    
    /// Gère un trap en mode Supervisor
    /// Cette fonction est similaire à handle_trap mais utilise les CSR du mode Supervisor
    fn handle_supervisor_trap(&mut self, cause: TrapCause) -> Result<(), ExecuteError> {
        // 1. Sauvegarder PC dans sepc_t
        let pc = self.read_pc();
        self.write_sepc(pc);

        // 2. Sauvegarder la cause dans scause_t
        // Utiliser CSR 7 (scause_t)
        let mut cause_word = Word::zero();
        if let Some(tryte) = cause_word.tryte_mut(0) {
            *tryte = Tryte::from_bal3(cause.to_code()).unwrap_or(Tryte::Digit(13)); // 13 = 0 en ternaire équilibré
        }
        let _ = self.state_write_csr(7, cause_word);

        // 3. Sauvegarder le privilège actuel dans sstatus_t.SPP_t
        let current_privilege = self.get_privilege();
        self.set_supervisor_previous_privilege(current_privilege);

        // 4. Passer en mode Supervisor
        self.set_privilege(PrivilegeLevel::Supervisor);

        // 5. Sauter à l'adresse contenue dans stvec_t
        let stvec = match self.state_read_csr(5) {
            Ok(value) => value,
            Err(_) => Word::zero(), // En cas d'erreur, utiliser une adresse par défaut
        };
        self.write_pc(stvec);

        Ok(())
    }
}

/// Implémentation des opérations système pour le CPU
impl<T: CpuState> SystemOperations for T {
    /// Exécute une instruction système
    /// Format I: [opcode(3) | func(3) | unused(6)]
    fn execute_system(&mut self, func: i8) -> Result<(), ExecuteError> {
        match func {
            0 => {
                // HALT - Arrêter le processeur
                self.set_halted(true);
                Ok(())
            }
            1 => {
                // NOP - Ne rien faire
                Ok(())
            }
            2 => {
                // ECALL - Appel système
                // Vérifier le niveau de privilège actuel
                match self.get_privilege() {
                    PrivilegeLevel::User => {
                        // ECALL depuis U-mode déclenche un trap avec cause EcallU
                        self.handle_trap(TrapCause::EcallU)
                    }
                    PrivilegeLevel::Supervisor => {
                        // ECALL depuis S-mode déclenche un trap avec cause EcallS
                        self.handle_trap(TrapCause::EcallS)
                    }
                    PrivilegeLevel::Machine => {
                        // ECALL depuis M-mode déclenche un trap avec cause EcallM
                        self.handle_trap(TrapCause::EcallM)
                    }
                }
            }
            3 => {
                // EBREAK - Point d'arrêt pour le débogage
                self.execute_ebreak()
            }
            4 => {
                // MRET - Retour d'un trap en mode Machine
                self.execute_mret()
            }
            5 => {
                // SRET - Retour d'un trap en mode Supervisor
                self.execute_sret()
            }
            // Autres fonctions système à implémenter
            _ => Err(ExecuteError::Unimplemented),
        }
    }

    /// Exécute une instruction MRET (Machine Return)
    fn execute_mret(&mut self) -> Result<(), ExecuteError> {
        // Vérifier que nous sommes en mode Machine
        if self.get_privilege() != PrivilegeLevel::Machine {
            return self.handle_trap(TrapCause::IllegalInstr);
        }

        // Restaurer le niveau de privilège depuis mstatus_t.MPP_t
        let previous_privilege = self.get_previous_privilege();
        self.set_privilege(previous_privilege);

        // Restaurer le PC depuis mepc_t
        let mepc = self.read_mepc();
        self.write_pc(mepc);

        Ok(())
    }
    
    /// Exécute une instruction SRET (Supervisor Return)
    fn execute_sret(&mut self) -> Result<(), ExecuteError> {
        // Vérifier que nous sommes en mode Supervisor ou Machine
        // Seuls ces modes peuvent exécuter SRET
        match self.get_privilege() {
            PrivilegeLevel::User => {
                // En mode User, SRET est une instruction illégale
                return self.handle_trap(TrapCause::IllegalInstr);
            }
            PrivilegeLevel::Supervisor | PrivilegeLevel::Machine => {
                // En mode Supervisor ou Machine, SRET est autorisé
                // Restaurer le niveau de privilège depuis sstatus_t.SPP_t
                let previous_privilege = self.get_supervisor_previous_privilege();
                self.set_privilege(previous_privilege);
                
                // Restaurer le PC depuis sepc_t
                let sepc = self.read_sepc();
                self.write_pc(sepc);

                Ok(())
            }
        }
    }
    
    /// Exécute une instruction EBREAK (Environment BREAK)
    fn execute_ebreak(&mut self) -> Result<(), ExecuteError> {
        // EBREAK déclenche un trap avec cause BreakPoint
        // Cela permet au débogueur de reprendre le contrôle
        // Cette instruction est valide dans tous les niveaux de privilège
        self.handle_trap(TrapCause::BreakPoint)
    }

    /// Exécute une instruction LUI (Load Upper Immediate)
    /// Format U: [opcode(3t) | rd(2t) | immediate(7t)]
    /// Charge un immédiat dans les trytes supérieurs d'un registre
    fn execute_lui(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError> {
        // Ne rien faire si rd est R0
        if rd == Register::R0 {
            return Ok(());
        }

        // Créer un Word avec l'immédiat dans les trytes supérieurs
        let mut word = Word::zero();

        // Convertir l'immédiat en trytes et les placer dans les positions supérieures
        // L'immédiat est sur 7 trits, donc on peut le convertir en 3 trytes environ
        let imm_abs = imm.abs() as u16;
        let sign = if imm < 0 { -1 } else { 1 };

        // Placer les trytes de l'immédiat dans les positions 4, 5, 6 du Word
        // (les positions 0, 1, 2, 3 restent à zéro)
        for i in 0..3 {
            if let Some(tryte) = word.tryte_mut(i + 4) {
                // Extraire 3 trits (1 tryte) de l'immédiat
                let tryte_val = ((imm_abs >> (i * 3)) & 0x7) as i8;
                // Appliquer le signe
                let signed_val = tryte_val * sign as i8;
                // Convertir en Tryte::Digit (ajouter 13 pour le ternaire équilibré)
                *tryte = Tryte::Digit((signed_val + 13) as u8);
            }
        }

        // Écrire le Word dans le registre de destination
        self.write_gpr(rd, word);

        Ok(())
    }

    /// Exécute une instruction AUIPC (Add Upper Immediate to PC)
    /// Format U: [opcode(3t) | rd(2t) | immediate(7t)]
    /// Ajoute un immédiat au PC et stocke le résultat dans un registre
    fn execute_auipc(&mut self, rd: Register, imm: i16) -> Result<(), ExecuteError> {
        // Ne rien faire si rd est R0
        if rd == Register::R0 {
            return Ok(());
        }

        // 1. Lire le PC actuel
        let current_pc = self.read_pc();

        // 2. Créer un Word avec l'immédiat dans les trytes supérieurs
        let mut imm_word = Word::zero();

        // Convertir l'immédiat en trytes et les placer dans les positions supérieures
        // L'immédiat est sur 7 trits, donc on peut le convertir en 3 trytes environ
        let imm_abs = imm.abs() as u16;
        let sign = if imm < 0 { -1 } else { 1 };

        // Placer les trytes de l'immédiat dans les positions 4, 5, 6 du Word
        // (les positions 0, 1, 2, 3 restent à zéro)
        for i in 0..3 {
            if let Some(tryte) = imm_word.tryte_mut(i + 4) {
                // Extraire 3 trits (1 tryte) de l'immédiat
                let tryte_val = ((imm_abs >> (i * 3)) & 0x7) as i8;
                // Appliquer le signe
                let signed_val = tryte_val * sign as i8;
                // Convertir en Tryte::Digit (ajouter 13 pour le ternaire équilibré)
                *tryte = Tryte::Digit((signed_val + 13) as u8);
            }
        }

        // 3. Ajouter l'immédiat au PC
        let (result, _, _) = add_24_trits(current_pc, imm_word, Trit::Z);

        // 4. Écrire le résultat dans le registre de destination
        self.write_gpr(rd, result);

        Ok(())
    }
}

/// Implémentation des opérations CSR pour le CPU
impl<T: CpuState> CsrOperations for T {
    /// Lit la valeur d'un CSR
    fn read_csr(&self, csr: i8) -> Result<Word, ExecuteError> {
        self.state_read_csr(csr).map_err(ExecuteError::from)
    }

    /// Écrit une valeur dans un CSR
    fn write_csr(&mut self, csr: i8, value: Word) -> Result<(), ExecuteError> {
        self.state_write_csr(csr, value).map_err(ExecuteError::from)
    }

    /// Exécute une instruction CSRRW (CSR Read & Write)
    fn execute_csrrw(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError> {
        // Vérifier l'accès au CSR
        self.check_csr_access(csr, true)?;

        // Lire la valeur actuelle du CSR
        let old_value = self.read_csr(csr)?;

        // Lire la valeur du registre source
        let rs1_value = self.read_gpr(rs1);

        // Écrire la valeur du registre source dans le CSR
        self.write_csr(csr, rs1_value)?;

        // Si rd n'est pas R0, écrire l'ancienne valeur du CSR dans rd
        if rd != Register::R0 {
            self.write_gpr(rd, old_value);
        }

        Ok(())
    }

    /// Exécute une instruction CSRRS (CSR Read & Set)
    fn execute_csrrs(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError> {
        // Vérifier l'accès au CSR
        let write = rs1 != Register::R0;
        self.check_csr_access(csr, write)?;

        // Lire la valeur actuelle du CSR
        let old_value = self.read_csr(csr)?;

        // Si rd n'est pas R0, écrire l'ancienne valeur du CSR dans rd
        if rd != Register::R0 {
            self.write_gpr(rd, old_value);
        }

        // Si rs1 n'est pas R0, effectuer l'opération de set
        if rs1 != Register::R0 {
            // Lire la valeur du registre source
            let rs1_value = self.read_gpr(rs1);

            // Effectuer un OR bit à bit entre la valeur actuelle du CSR et rs1_value
            self.state_set_csr(csr, rs1_value).map_err(ExecuteError::from)?
        }

        Ok(())
    }

    /// Exécute une instruction CSRRC (CSR Read & Clear)
    fn execute_csrrc(&mut self, rd: Register, csr: i8, rs1: Register) -> Result<(), ExecuteError> {
        // Vérifier l'accès au CSR
        let write = rs1 != Register::R0;
        self.check_csr_access(csr, write)?;

        // Lire la valeur actuelle du CSR
        let old_value = self.read_csr(csr)?;

        // Si rd n'est pas R0, écrire l'ancienne valeur du CSR dans rd
        if rd != Register::R0 {
            self.write_gpr(rd, old_value);
        }

        // Si rs1 n'est pas R0, effectuer l'opération de clear
        if rs1 != Register::R0 {
            // Lire la valeur du registre source
            let rs1_value = self.read_gpr(rs1);

            // Effectuer un AND bit à bit entre la valeur actuelle du CSR et la négation de rs1_value
            self.state_clear_csr(csr, rs1_value).map_err(ExecuteError::from)?
        }

        Ok(())
    }

    /// Exécute une instruction CSR avec un immédiat
    fn execute_csr_imm(&mut self, csr: u8, rd: Register, imm: i16) -> Result<(), ExecuteError> {
        // Vérifier l'accès au CSR
        let write = imm != 0;
        self.check_csr_access(csr as i8, write)?;

        // Lire la valeur actuelle du CSR
        let old_value = self.read_csr(csr as i8)?;

        // Si rd n'est pas R0, écrire l'ancienne valeur du CSR dans rd
        if rd != Register::R0 {
            self.write_gpr(rd, old_value);
        }

        // Si imm n'est pas 0, effectuer l'opération de set
        if imm != 0 {
            // Créer une valeur Word à partir de l'immédiat
            let imm_value = Word::from_i16(imm);

            // Effectuer un OR bit à bit entre la valeur actuelle du CSR et imm_value
            self.write_csr(csr as i8, imm_value);
        }

        Ok(())
    }

    /// Vérifie si l'accès à un CSR est autorisé
    fn check_csr_access(&self, csr: i8, write: bool) -> Result<(), ExecuteError> {
        // Vérifier le niveau de privilège requis pour accéder au CSR
        let csr_privilege = (csr >> 6) & 0x3;
        
        // Vérifier si l'accès en écriture est autorisé
        let read_only = ((csr >> 5) & 0x1) == 1;
        
        if write && read_only {
            return Err(ExecuteError::IllegalCsrAccess);
        }
        
        // Vérifier le niveau de privilège
        let current_privilege = self.get_privilege() as i8;
        if current_privilege < csr_privilege {
            return Err(ExecuteError::IllegalCsrAccess);
        }
        
        Ok(())
    }

    /// Obtient le niveau de privilège actuel
    fn get_privilege(&self) -> PrivilegeLevel {
        self.state_get_privilege()
    }

    /// Définit le niveau de privilège actuel
    fn set_privilege(&mut self, privilege: PrivilegeLevel) {
        self.state_set_privilege(privilege);
    }

    /// Obtient le niveau de privilège précédent à partir de mstatus_t.MPP_t
    fn get_previous_privilege(&self) -> PrivilegeLevel {
        self.state_get_previous_privilege()
    }

    /// Définit le niveau de privilège précédent dans mstatus_t.MPP_t
    fn set_previous_privilege(&mut self, privilege: PrivilegeLevel) {
        self.state_set_previous_privilege(privilege);
    }

    /// Lit la valeur de mepc_t
    fn read_mepc(&self) -> Word {
        self.state_read_csr(0).unwrap_or_default()
    }

    /// Écrit une valeur dans mepc_t
    fn write_mepc(&mut self, value: Word) {
        self.state_write_csr(0, value);
    }

    /// Lit la valeur de sepc_t
    fn read_sepc(&self) -> Word {
        self.state_read_csr(4).unwrap_or_default()
    }

    /// Écrit une valeur dans sepc_t
    fn write_sepc(&mut self, value: Word) {
        self.state_write_csr(4, value);
    }

    /// Gère un trap (exception/syscall)
    fn handle_trap(&mut self, _cause: TrapCause) -> Result<(), ExecuteError> {
        // Implémentation de la gestion des traps
        Ok(())
    }
}
