// src/cpu/registers.rs

use crate::core::Word;
use crate::core::{Trit, Tryte};
use std::fmt;

/// Représente les drapeaux (flags) du processeur
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub struct Flags {
    pub zf: bool, // Zero Flag - Indique si le résultat est zéro
    pub sf: bool, // Sign Flag - Indique si le résultat est négatif
    pub xf: bool, // eXtended Flag - Utilisé pour les opérations spéciales ou les états spéciaux
    pub of: bool, // Overflow Flag - Indique un débordement lors d'une opération
    pub cf: bool, // Carry Flag - Indique une retenue lors d'une opération
}

impl Flags {
    /// Crée un nouvel ensemble de drapeaux avec toutes les valeurs à false
    pub fn new() -> Self {
        Flags {
            zf: false,
            sf: false,
            xf: false,
            of: false,
            cf: false,
        }
    }

    /// Réinitialise tous les drapeaux à false
    pub fn reset(&mut self) {
        self.zf = false;
        self.sf = false;
        self.xf = false;
        self.of = false;
        self.cf = false;
    }
}

impl Default for Flags {
    fn default() -> Self {
        Flags::new()
    }
}

impl fmt::Display for Flags {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "Z:{} S:{} X:{} O:{} C:{}",
            if self.zf { "1" } else { "0" },
            if self.sf { "1" } else { "0" },
            if self.xf { "1" } else { "0" },
            if self.of { "1" } else { "0" },
            if self.cf { "1" } else { "0" }
        )
    }
}

/// Énumération des registres généraux du processeur
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum Register {
    R0,
    R1,
    R2,
    R3,
    R4,
    R5,
    R6,
    R7,
}

impl Register {
    /// Convertit un registre en son index (0-7)
    pub fn to_index(&self) -> usize {
        match self {
            Register::R0 => 0,
            Register::R1 => 1,
            Register::R2 => 2,
            Register::R3 => 3,
            Register::R4 => 4,
            Register::R5 => 5,
            Register::R6 => 6,
            Register::R7 => 7,
        }
    }

    /// Crée un registre à partir d'un index (0-7)
    pub fn from_index(index: usize) -> Result<Self, RegisterError> {
        match index {
            0 => Ok(Register::R0),
            1 => Ok(Register::R1),
            2 => Ok(Register::R2),
            3 => Ok(Register::R3),
            4 => Ok(Register::R4),
            5 => Ok(Register::R5),
            6 => Ok(Register::R6),
            7 => Ok(Register::R7),
            _ => Err(RegisterError::InvalidIndex),
        }
    }
}

impl fmt::Display for Register {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "R{}", self.to_index())
    }
}

/// Erreurs possibles lors de l'accès aux registres
#[derive(Debug, PartialEq, Eq)]
pub enum RegisterError {
    InvalidIndex,       // Index de registre invalide (hors de la plage 0-7)
    PrivilegeViolation, // Tentative d'accès à un registre privilégié depuis un mode non privilégié
}

/// Niveaux de privilège du processeur
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum PrivilegeLevel {
    User,       // Mode utilisateur (non privilégié)
    Supervisor, // Mode superviseur (semi-privilégié)
    Machine,    // Mode machine (privilégié)
}

/// Codes de cause pour les traps
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub enum TrapCause {
    EcallU,       // Appel système depuis U-mode
    EcallS,       // Appel système depuis S-mode
    EcallM,       // Appel système depuis M-mode
    IllegalInstr, // Instruction illégale
    LoadFault,    // Erreur d'accès mémoire en lecture
    StoreFault,   // Erreur d'accès mémoire en écriture
    BreakPoint,   // Point d'arrêt pour le débogage (EBREAK)
}

impl TrapCause {
    /// Convertit une cause de trap en code numérique
    pub fn to_code(&self) -> i8 {
        match self {
            TrapCause::EcallU => 0,
            TrapCause::EcallS => 1,
            TrapCause::EcallM => 2,
            TrapCause::IllegalInstr => 3,
            TrapCause::LoadFault => 4,
            TrapCause::StoreFault => 5,
            TrapCause::BreakPoint => 6,
        }
    }

    /// Crée une cause de trap à partir d'un code numérique
    pub fn from_code(code: i8) -> Option<Self> {
        match code {
            0 => Some(TrapCause::EcallU),
            1 => Some(TrapCause::EcallS),
            2 => Some(TrapCause::EcallM),
            3 => Some(TrapCause::IllegalInstr),
            4 => Some(TrapCause::LoadFault),
            5 => Some(TrapCause::StoreFault),
            6 => Some(TrapCause::BreakPoint),
            _ => None,
        }
    }
}

/// Représente l'état complet du processeur
#[derive(Debug, Clone)]
pub struct ProcessorState {
    gpr: [Word; 8], // Registres généraux (General Purpose Registers)
    pc: Word,       // Compteur de programme (Program Counter)
    sp: Word,       // Pointeur de pile (Stack Pointer)
    fr: Flags,      // Drapeaux (Flags Register)

    // Niveau de privilège actuel
    pub current_privilege: PrivilegeLevel,

    // CSRs ternaires essentiels pour le mode Machine
    pub mstatus_t: Word, // Machine Status Register
    pub mtvec_t: Word,   // Machine Trap Vector Register
    pub mepc_t: Word,    // Machine Exception Program Counter
    pub mcause_t: Word,  // Machine Cause Register
    pub medeleg_t: Word, // Machine Exception Delegation Register
    pub mideleg_t: Word, // Machine Interrupt Delegation Register
    
    // CSRs ternaires pour le mode Supervisor
    pub sstatus_t: Word, // Supervisor Status Register
    pub stvec_t: Word,   // Supervisor Trap Vector Register
    pub sepc_t: Word,    // Supervisor Exception Program Counter
    pub scause_t: Word,  // Supervisor Cause Register
}

impl ProcessorState {
    /// Crée un nouvel état de processeur avec des valeurs par défaut
    pub fn new() -> Self {
        let state = ProcessorState {
            gpr: [Word::default_undefined(); 8],
            pc: Word::zero(),                           // PC commence à 0
            sp: Word::default_undefined(),              // SP sera initialisé à MAX_ADDRESS
            fr: Flags::new(),                           // Flags à 0
            current_privilege: PrivilegeLevel::Machine, // Démarre en mode Machine
            
            // CSRs du mode Machine
            mstatus_t: Word::zero(),                    // Machine Status Register initialisé à 0
            mtvec_t: Word::zero(),                      // Machine Trap Vector Register initialisé à 0
            mepc_t: Word::zero(),                       // Machine Exception Program Counter initialisé à 0
            mcause_t: Word::zero(),                     // Machine Cause Register initialisé à 0
            medeleg_t: Word::zero(),                    // Machine Exception Delegation Register initialisé à 0
            mideleg_t: Word::zero(),                    // Machine Interrupt Delegation Register initialisé à 0
            
            // CSRs du mode Supervisor
            sstatus_t: Word::zero(),                    // Supervisor Status Register initialisé à 0
            stvec_t: Word::zero(),                      // Supervisor Trap Vector Register initialisé à 0
            sepc_t: Word::zero(),                       // Supervisor Exception Program Counter initialisé à 0
            scause_t: Word::zero(),                     // Supervisor Cause Register initialisé à 0
        };

        // Initialise SP à MAX_ADDRESS (haut de la mémoire)
        // Note: Ceci est une simplification, dans un système réel,
        // nous devrions convertir MAX_ADDRESS en Word correctement
        // Pour l'instant, on utilise un Word par défaut

        // TODO: Implémenter la conversion de MAX_ADDRESS en Word
        // state.sp = Word::from_value(MAX_ADDRESS);

        state
    }

    /// Lit la valeur d'un registre général
    pub fn read_gpr(&self, reg: Register) -> Word {
        self.gpr[reg.to_index()].clone()
    }

    /// Écrit une valeur dans un registre général
    pub fn write_gpr(&mut self, reg: Register, value: Word) {
        self.gpr[reg.to_index()] = value;
    }

    /// Lit la valeur du compteur de programme (PC)
    pub fn read_pc(&self) -> Word {
        self.pc.clone()
    }

    /// Écrit une valeur dans le compteur de programme (PC)
    pub fn write_pc(&mut self, value: Word) {
        self.pc = value;
    }

    /// Lit la valeur du pointeur de pile (SP)
    pub fn read_sp(&self) -> Word {
        self.sp.clone()
    }

    /// Écrit une valeur dans le pointeur de pile (SP)
    pub fn write_sp(&mut self, value: Word) {
        self.sp = value;
    }

    /// Lit les drapeaux
    pub fn read_flags(&self) -> Flags {
        self.fr.clone()
    }

    /// Écrit de nouvelles valeurs dans les drapeaux
    pub fn write_flags(&mut self, flags: Flags) {
        self.fr = flags;
    }

    /// Réinitialise tous les drapeaux
    pub fn reset_flags(&mut self) {
        self.fr.reset();
    }

    /// Lit la valeur d'un CSR
    pub fn read_csr(&self, csr: i8) -> Result<Word, RegisterError> {
        match csr {
            // CSRs du mode Machine (0-3)
            0 => Ok(self.mstatus_t.clone()),
            1 => Ok(self.mtvec_t.clone()),
            2 => Ok(self.mepc_t.clone()),
            3 => Ok(self.mcause_t.clone()),
            
            // CSRs du mode Supervisor (4-7)
            4 => Ok(self.sstatus_t.clone()),
            5 => Ok(self.stvec_t.clone()),
            6 => Ok(self.sepc_t.clone()),
            7 => Ok(self.scause_t.clone()),
            
            // Registres de délégation (8-9)
            8 => Ok(self.medeleg_t.clone()),
            9 => Ok(self.mideleg_t.clone()),
            
            _ => Err(RegisterError::InvalidIndex),
        }
    }

    /// Écrit une valeur dans un CSR
    pub fn write_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError> {
        match csr {
            // CSRs du mode Machine (0-3)
            0 => {
                self.mstatus_t = value;
                Ok(())
            }
            1 => {
                self.mtvec_t = value;
                Ok(())
            }
            2 => {
                self.mepc_t = value;
                Ok(())
            }
            3 => {
                self.mcause_t = value;
                Ok(())
            }
            
            // CSRs du mode Supervisor (4-7)
            4 => {
                self.sstatus_t = value;
                Ok(())
            }
            5 => {
                self.stvec_t = value;
                Ok(())
            }
            6 => {
                self.sepc_t = value;
                Ok(())
            }
            7 => {
                self.scause_t = value;
                Ok(())
            }
            
            // Registres de délégation (8-9)
            8 => {
                self.medeleg_t = value;
                Ok(())
            }
            9 => {
                self.mideleg_t = value;
                Ok(())
            }
            
            _ => Err(RegisterError::InvalidIndex),
        }
    }

    /// Effectue un OR bit à bit entre la valeur actuelle d'un CSR et une nouvelle valeur
    pub fn set_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError> {
        let current = self.read_csr(csr)?;
        let mut result = current.clone();

        // Effectuer un OR bit à bit entre les trytes
        for i in 0..8 {
            if let (Some(current_tryte), Some(value_tryte)) = (current.tryte(i), value.tryte(i)) {
                if let (Tryte::Digit(current_val), Tryte::Digit(value_val)) =
                    (current_tryte, value_tryte)
                {
                    // Convertir en valeurs Bal3
                    let _current_bal3 = (*current_val as i8) - 13;
                    let _value_bal3 = (*value_val as i8) - 13;

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

        self.write_csr(csr, result)
    }

    /// Obtient le niveau de privilège précédent à partir de mstatus_t.MPP_t
    pub fn get_previous_privilege(&self) -> PrivilegeLevel {
        // Le champ MPP_t est stocké dans les 2 premiers trits du premier tryte de mstatus_t
        if let Some(tryte) = self.mstatus_t.tryte(0) {
            if let Tryte::Digit(val) = tryte {
                let trits = Tryte::Digit(*val).to_trits();
                // Utiliser les 2 premiers trits pour déterminer le niveau de privilège
                match (trits[0], trits[1]) {
                    (Trit::Z, Trit::Z) => PrivilegeLevel::User,       // 00 = User
                    (Trit::Z, Trit::P) => PrivilegeLevel::Supervisor, // 01 = Supervisor
                    (Trit::P, Trit::Z) => PrivilegeLevel::Machine,    // 10 = Machine
                    _ => PrivilegeLevel::User, // Par défaut, retourner User pour les combinaisons non définies
                }
            } else {
                PrivilegeLevel::User // Par défaut, retourner User
            }
        } else {
            PrivilegeLevel::User // Par défaut, retourner User
        }
    }

    /// Définit le niveau de privilège précédent dans mstatus_t.MPP_t
    pub fn set_previous_privilege(&mut self, privilege: PrivilegeLevel) {
        // Le champ MPP_t est stocké dans les 2 premiers trits du premier tryte de mstatus_t
        if let Some(tryte) = self.mstatus_t.tryte(0) {
            if let Tryte::Digit(val) = tryte {
                let mut trits = Tryte::Digit(*val).to_trits();

                // Définir les 2 premiers trits en fonction du niveau de privilège
                match privilege {
                    PrivilegeLevel::User => {
                        trits[0] = Trit::Z;
                        trits[1] = Trit::Z;
                    }
                    PrivilegeLevel::Supervisor => {
                        trits[0] = Trit::Z;
                        trits[1] = Trit::P;
                    }
                    PrivilegeLevel::Machine => {
                        trits[0] = Trit::P;
                        trits[1] = Trit::Z;
                    }
                }

                // Convertir les trits en tryte et mettre à jour mstatus_t
                let new_tryte = Tryte::from_trits(trits);
                if let Some(tryte_mut) = self.mstatus_t.tryte_mut(0) {
                    *tryte_mut = new_tryte;
                }
            }
        }
    }

    /// Définit la cause du trap dans mcause_t
    pub fn set_trap_cause(&mut self, cause: TrapCause) {
        // Convertir la cause en valeur numérique
        let code = cause.to_code();

        // Créer un Word avec le code de cause
        let mut cause_word = Word::zero();
        if let Some(tryte) = cause_word.tryte_mut(0) {
            *tryte = Tryte::from_bal3(code).unwrap_or(Tryte::Digit(13)); // 13 = 0 en ternaire équilibré
        }

        // Mettre à jour mcause_t
        self.mcause_t = cause_word;
    }

    /// Obtient la cause du trap à partir de mcause_t
    pub fn get_trap_cause(&self) -> Option<TrapCause> {
        // Lire le code de cause à partir du premier tryte de mcause_t
        if let Some(tryte) = self.mcause_t.tryte(0) {
            if let Tryte::Digit(val) = tryte {
                let bal3 = (*val as i8) - 13;
                return TrapCause::from_code(bal3);
            }
        }

        None
    }
}

impl Default for ProcessorState {
    fn default() -> Self {
        ProcessorState::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::Tryte;

    #[test]
    fn test_register_conversion() {
        // Test de conversion Register -> index -> Register
        for reg in [
            Register::R0,
            Register::R1,
            Register::R2,
            Register::R3,
            Register::R4,
            Register::R5,
            Register::R6,
            Register::R7,
        ]
        .iter()
        {
            let index = reg.to_index();
            let converted = Register::from_index(index).unwrap();
            assert_eq!(*reg, converted);
        }

        // Test d'index invalide
        assert!(Register::from_index(8).is_err());
    }

    #[test]
    fn test_flags() {
        let mut flags = Flags::new();
        assert!(!flags.zf);
        assert!(!flags.sf);
        assert!(!flags.xf);
        assert!(!flags.of);
        assert!(!flags.cf);

        flags.zf = true;
        flags.sf = true;
        flags.of = true;
        flags.cf = true;
        assert!(flags.zf);
        assert!(flags.sf);
        assert!(!flags.xf);
        assert!(flags.of);
        assert!(flags.cf);

        flags.reset();
        assert!(!flags.zf);
        assert!(!flags.sf);
        assert!(!flags.xf);
        assert!(!flags.of);
        assert!(!flags.cf);
    }

    #[test]
    fn test_processor_state() {
        let mut state = ProcessorState::new();

        // Test des registres généraux
        let test_word = Word([Tryte::Digit(5); 8]);
        state.write_gpr(Register::R3, test_word.clone());
        assert_eq!(state.read_gpr(Register::R3), test_word);

        // Test du PC
        let pc_value = Word([Tryte::Digit(10); 8]);
        state.write_pc(pc_value.clone());
        assert_eq!(state.read_pc(), pc_value);

        // Test du SP
        let sp_value = Word([Tryte::Digit(20); 8]);
        state.write_sp(sp_value.clone());
        assert_eq!(state.read_sp(), sp_value);

        // Test des flags
        let mut flags = Flags::new();
        flags.zf = true;
        flags.sf = false;
        flags.of = true;
        flags.cf = true;
        state.write_flags(flags.clone());
        assert_eq!(state.read_flags(), flags);

        state.reset_flags();
        assert!(!state.fr.zf);
        assert!(!state.fr.sf);
        assert!(!state.fr.xf);
        assert!(!state.fr.of);
        assert!(!state.fr.cf);
    }
}
