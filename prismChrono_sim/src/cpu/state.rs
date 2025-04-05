// src/cpu/state.rs
// Définition centralisée du trait CpuState pour l'architecture PrismChrono

use crate::core::{Address, Tryte, Word};
use crate::cpu::execute::ExecuteError;
use crate::cpu::execute_core::Cpu;
use crate::cpu::registers::{Flags, PrivilegeLevel, Register, RegisterError, TrapCause};

/// Trait unifié pour accéder à l'état du CPU et à ses fonctionnalités
/// Ce trait combine les fonctionnalités précédemment dispersées dans plusieurs modules
pub trait CpuState {
    /// Obtient une référence mutable vers le CPU (utilisé pour les métriques)
    fn as_cpu_mut(&mut self) -> Option<&mut Cpu> {
        None // Par défaut, retourne None. Sera surchargé par l'implémentation réelle
    }
    
    /// Lit un registre général
    fn read_gpr(&self, reg: Register) -> Word;

    /// Écrit dans un registre général
    fn write_gpr(&mut self, reg: Register, value: Word);

    /// Lit le registre PC
    fn read_pc(&self) -> Word;

    /// Écrit dans le registre PC
    fn write_pc(&mut self, value: Word);

    /// Lit les flags
    fn read_flags(&self) -> Flags;

    /// Écrit les flags
    fn write_flags(&mut self, flags: Flags);

    /// Définit l'état d'arrêt du CPU
    fn set_halted(&mut self, halted: bool);

    /// Lit un tryte depuis la mémoire
    fn read_tryte(&self, addr: Address) -> Result<Tryte, ExecuteError>;

    /// Écrit un tryte dans la mémoire
    fn write_tryte(&mut self, addr: Address, value: Tryte) -> Result<(), ExecuteError>;

    /// Lit un mot depuis la mémoire
    fn read_word(&self, addr: Address) -> Result<Word, ExecuteError>;

    /// Écrit un mot dans la mémoire
    fn write_word(&mut self, addr: Address, value: Word) -> Result<(), ExecuteError>;

    /// Lit la valeur d'un CSR depuis l'état du processeur
    fn state_read_csr(&self, csr: i8) -> Result<Word, RegisterError>;

    /// Écrit une valeur dans un CSR dans l'état du processeur
    fn state_write_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError>;

    /// Effectue un OR bit à bit entre la valeur actuelle d'un CSR et une nouvelle valeur
    fn state_set_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError>;

    /// Obtient le niveau de privilège actuel depuis l'état du processeur
    fn state_get_privilege(&self) -> PrivilegeLevel;

    /// Définit le niveau de privilège actuel dans l'état du processeur
    fn state_set_privilege(&mut self, privilege: PrivilegeLevel);

    /// Obtient le niveau de privilège précédent depuis l'état du processeur
    fn state_get_previous_privilege(&self) -> PrivilegeLevel;

    /// Définit le niveau de privilège précédent dans l'état du processeur
    fn state_set_previous_privilege(&mut self, privilege: PrivilegeLevel);

    /// Définit la cause du trap dans l'état du processeur
    fn state_set_trap_cause(&mut self, cause: TrapCause);
}