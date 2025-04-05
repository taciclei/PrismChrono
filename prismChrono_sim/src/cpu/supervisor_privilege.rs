// src/cpu/supervisor_privilege.rs
// Implémentation des fonctionnalités de gestion du privilège Supervisor

use crate::core::{Trit, Tryte, Word};
use crate::cpu::registers::PrivilegeLevel;

/// Fonctions utilitaires pour la gestion du champ SPP_t dans sstatus_t
pub trait SupervisorPrivilegeOperations {
    /// Obtient le niveau de privilège précédent à partir de sstatus_t.SPP_t
    fn get_supervisor_previous_privilege(&self) -> PrivilegeLevel;

    /// Définit le niveau de privilège précédent dans sstatus_t.SPP_t
    fn set_supervisor_previous_privilege(&mut self, privilege: PrivilegeLevel);
}

impl<T: crate::cpu::state::CpuState> SupervisorPrivilegeOperations for T {
    /// Obtient le niveau de privilège précédent à partir de sstatus_t.SPP_t
    /// Le champ SPP_t est stocké dans le premier trit du premier tryte de sstatus_t
    fn get_supervisor_previous_privilege(&self) -> PrivilegeLevel {
        // Lire sstatus_t (CSR 4)
        if let Ok(sstatus) = self.state_read_csr(4) {
            if let Some(tryte) = sstatus.tryte(0) {
                // Extraire le premier trit (SPP_t)
                if let Tryte::Digit(val) = tryte {
                    let trits = Tryte::Digit(*val).to_trits();
                    // SPP_t est le premier trit
                    match trits[0] {
                        Trit::Z => PrivilegeLevel::User,       // 0 = User
                        Trit::P => PrivilegeLevel::Supervisor, // 1 = Supervisor (ne devrait pas arriver en pratique)
                        Trit::N => PrivilegeLevel::User,       // -1 = User (par défaut)
                    }
                } else {
                    PrivilegeLevel::User // Par défaut, retourner User
                }
            } else {
                PrivilegeLevel::User // Par défaut, retourner User
            }
        } else {
            PrivilegeLevel::User // Par défaut, retourner User
        }
    }

    /// Définit le niveau de privilège précédent dans sstatus_t.SPP_t
    /// Le champ SPP_t est stocké dans le premier trit du premier tryte de sstatus_t
    fn set_supervisor_previous_privilege(&mut self, privilege: PrivilegeLevel) {
        // Lire sstatus_t (CSR 4)
        if let Ok(mut sstatus) = self.state_read_csr(4) {
            if let Some(tryte) = sstatus.tryte(0) {
                // Extraire les trits actuels
                let mut trits = [Trit::Z; 3];
                if let Tryte::Digit(val) = tryte {
                    trits = Tryte::Digit(*val).to_trits();
                }

                // Modifier le premier trit (SPP_t) selon le niveau de privilège
                match privilege {
                    PrivilegeLevel::User => {
                        trits[0] = Trit::Z; // 0 = User
                    },
                    PrivilegeLevel::Supervisor => {
                        trits[0] = Trit::P; // 1 = Supervisor
                    },
                    PrivilegeLevel::Machine => {
                        // Ne devrait pas arriver, mais par sécurité, mettre à User
                        trits[0] = Trit::Z; // 0 = User
                    },
                }

                // Convertir les trits en tryte et mettre à jour sstatus_t
                let new_tryte = Tryte::from_trits(trits);
                if let Some(tryte_mut) = sstatus.tryte_mut(0) {
                    *tryte_mut = new_tryte;
                }

                // Écrire la nouvelle valeur dans sstatus_t
                let _ = self.state_write_csr(4, sstatus);
            }
        }
    }
}