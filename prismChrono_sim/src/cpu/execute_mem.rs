// src/cpu/execute_mem.rs
// Implémentation des instructions de chargement/stockage pour l'architecture PrismChrono

use crate::core::{Address, Trit, Tryte, Word, is_valid_address};
use crate::cpu::execute::ExecuteError;
use crate::cpu::registers::Register;
use crate::memory::MemoryError;

/// Trait pour les opérations mémoire
pub trait MemoryOperations {
    /// Exécute une instruction de chargement (LOADW Rd, imm(Rs1))
    fn execute_load(&mut self, rd: Register, rs1: Register, offset: i8)
    -> Result<(), ExecuteError>;

    /// Exécute une instruction de chargement d'un tryte avec extension de signe (LOADT)
    fn execute_load_tryte(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError>;

    /// Exécute une instruction de chargement d'un tryte sans extension de signe (LOADTU)
    fn execute_load_tryte_unsigned(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError>;

    /// Exécute une instruction de stockage (STOREW Rs2, imm(Rs1))
    fn execute_store(
        &mut self,
        rs1: Register,
        rs2: Register,
        offset: i8,
    ) -> Result<(), ExecuteError>;

    /// Exécute une instruction de stockage d'un tryte (STORET)
    fn execute_store_tryte(
        &mut self,
        rs1: Register,
        rs2: Register,
        offset: i8,
    ) -> Result<(), ExecuteError>;
}

/// Implémentation des opérations mémoire pour le CPU
impl<T: CpuState> MemoryOperations for T {
    /// Exécute une instruction de chargement (LOADW Rd, imm(Rs1))
    /// Charge un mot (Word) de 24 trits depuis la mémoire vers un registre
    fn execute_load(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Calculer l'adresse effective = Rs1 + offset
        let base_addr_word = self.read_gpr(rs1);

        // Convertir le Word en adresse (utiliser les premiers trytes)
        let mut base_addr: Address = 0;
        for i in 0..5 {
            // Utiliser les 5 premiers trytes (15 trits)
            if let Some(tryte) = base_addr_word.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        base_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Ajouter l'offset (avec extension de signe)
        let effective_addr = base_addr.wrapping_add(offset as Address);

        // 2. Vérifier l'alignement de l'adresse (multiple de 8 pour un Word)
        if effective_addr % 8 != 0 {
            return Err(ExecuteError::MemoryError(MemoryError::Misaligned));
        }

        // 3. Vérifier que l'adresse est valide
        if !is_valid_address(effective_addr) {
            return Err(ExecuteError::MemoryError(MemoryError::OutOfBounds));
        }

        // 4. Lire le mot depuis la mémoire
        let word = self.read_word(effective_addr)?;

        // 5. Écrire le mot dans le registre de destination
        self.write_gpr(rd, word);

        Ok(())
    }

    /// Exécute une instruction de chargement d'un tryte avec extension de signe (LOADT)
    /// Charge un seul tryte depuis la mémoire et étend son signe sur 24 trits
    fn execute_load_tryte(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Calculer l'adresse effective = Rs1 + offset
        let base_addr_word = self.read_gpr(rs1);

        // Convertir le Word en adresse (utiliser les premiers trytes)
        let mut base_addr: Address = 0;
        for i in 0..5 {
            // Utiliser les 5 premiers trytes (15 trits)
            if let Some(tryte) = base_addr_word.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        base_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Ajouter l'offset (avec extension de signe)
        let effective_addr = base_addr.wrapping_add(offset as Address);

        // 2. Vérifier que l'adresse est valide
        if !is_valid_address(effective_addr) {
            return Err(ExecuteError::MemoryError(MemoryError::OutOfBounds));
        }

        // 3. Lire le tryte depuis la mémoire
        let tryte = self.read_tryte(effective_addr)?;

        // 4. Créer un Word avec extension de signe
        let mut word = Word::zero();

        // Placer le tryte lu dans le premier tryte du Word
        if let Some(first_tryte) = word.tryte_mut(0) {
            *first_tryte = tryte;
        }

        // Extension de signe: si le tryte est négatif, remplir les autres trytes avec -1
        // Sinon, ils restent à 0 (déjà fait par Word::zero())
        let is_negative = match tryte {
            Tryte::Digit(val) => {
                // Vérifier si le trit de poids fort est négatif
                let trits = Tryte::Digit(val).to_trits();
                trits[2] == Trit::N
            }
            _ => false, // Pour les autres types de trytes, pas d'extension de signe
        };

        if is_negative {
            // Remplir les autres trytes avec -1 (tous les trits à N)
            for i in 1..8 {
                if let Some(t) = word.tryte_mut(i) {
                    *t = Tryte::Digit(0); // 0 en ternaire équilibré = -13 en décimal
                }
            }
        }

        // 5. Écrire le Word dans le registre de destination
        self.write_gpr(rd, word);

        Ok(())
    }

    /// Exécute une instruction de chargement d'un tryte sans extension de signe (LOADTU)
    /// Charge un seul tryte depuis la mémoire sans extension de signe
    fn execute_load_tryte_unsigned(
        &mut self,
        rd: Register,
        rs1: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Calculer l'adresse effective = Rs1 + offset
        let base_addr_word = self.read_gpr(rs1);

        // Convertir le Word en adresse (utiliser les premiers trytes)
        let mut base_addr: Address = 0;
        for i in 0..5 {
            // Utiliser les 5 premiers trytes (15 trits)
            if let Some(tryte) = base_addr_word.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        base_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Ajouter l'offset (avec extension de signe)
        let effective_addr = base_addr.wrapping_add(offset as Address);

        // 2. Vérifier que l'adresse est valide
        if !is_valid_address(effective_addr) {
            return Err(ExecuteError::MemoryError(MemoryError::OutOfBounds));
        }

        // 3. Lire le tryte depuis la mémoire
        let tryte = self.read_tryte(effective_addr)?;

        // 4. Créer un Word avec le tryte lu (sans extension de signe)
        let mut word = Word::zero(); // Tous les trytes à 0

        // Placer le tryte lu dans le premier tryte du Word
        if let Some(first_tryte) = word.tryte_mut(0) {
            *first_tryte = tryte;
        }

        // 5. Écrire le Word dans le registre de destination
        self.write_gpr(rd, word);

        Ok(())
    }

    /// Exécute une instruction de stockage (STOREW Rs2, imm(Rs1))
    /// Stocke un mot (Word) de 24 trits depuis un registre vers la mémoire
    fn execute_store(
        &mut self,
        rs1: Register,
        rs2: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Calculer l'adresse effective = Rs1 + offset
        let base_addr_word = self.read_gpr(rs1);

        // Convertir le Word en adresse (utiliser les premiers trytes)
        let mut base_addr: Address = 0;
        for i in 0..5 {
            // Utiliser les 5 premiers trytes (15 trits)
            if let Some(tryte) = base_addr_word.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        base_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Ajouter l'offset (avec extension de signe)
        let effective_addr = base_addr.wrapping_add(offset as Address);

        // 2. Vérifier l'alignement de l'adresse (multiple de 8 pour un Word)
        if effective_addr % 8 != 0 {
            return Err(ExecuteError::MemoryError(MemoryError::Misaligned));
        }

        // 3. Vérifier que l'adresse est valide
        if !is_valid_address(effective_addr) {
            return Err(ExecuteError::MemoryError(MemoryError::OutOfBounds));
        }

        // 4. Lire la valeur du registre source
        let word = self.read_gpr(rs2);

        // 5. Écrire le mot dans la mémoire
        self.write_word(effective_addr, word)?;

        Ok(())
    }

    /// Exécute une instruction de stockage d'un tryte (STORET)
    /// Stocke un seul tryte depuis un registre vers la mémoire
    fn execute_store_tryte(
        &mut self,
        rs1: Register,
        rs2: Register,
        offset: i8,
    ) -> Result<(), ExecuteError> {
        // 1. Calculer l'adresse effective = Rs1 + offset
        let base_addr_word = self.read_gpr(rs1);

        // Convertir le Word en adresse (utiliser les premiers trytes)
        let mut base_addr: Address = 0;
        for i in 0..5 {
            // Utiliser les 5 premiers trytes (15 trits)
            if let Some(tryte) = base_addr_word.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        base_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Ajouter l'offset (avec extension de signe)
        let effective_addr = base_addr.wrapping_add(offset as Address);

        // 2. Vérifier que l'adresse est valide
        if !is_valid_address(effective_addr) {
            return Err(ExecuteError::MemoryError(MemoryError::OutOfBounds));
        }

        // 3. Lire la valeur du registre source (prendre seulement le premier tryte)
        let word = self.read_gpr(rs2);
        let tryte = match word.tryte(0) {
            Some(t) => t.clone(),
            None => Tryte::Undefined,
        };

        // 4. Écrire le tryte dans la mémoire
        self.write_tryte(effective_addr, tryte)?;

        Ok(())
    }
}

// Le trait CpuState est maintenant importé depuis le module state
use crate::cpu::state::CpuState;
