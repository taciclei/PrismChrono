// src/memory.rs

use crate::core::{Address, MAX_ADDRESS, Tryte, Word, is_valid_address}; // Importe les types nécessaires
use std::vec::Vec; // Utilise le vecteur dynamique de Rust pour stocker les trytes

// Erreurs possibles lors de l'accès mémoire
#[derive(Debug, PartialEq, Eq)]
pub enum MemoryError {
    OutOfBounds, // Adresse en dehors de la plage [0, MAX_ADDRESS-1]
    Misaligned,  // Tentative d'accès Mot (Word) à une adresse non multiple de 8
}

pub struct Memory {
    trytes: Vec<Tryte>, // Le stockage principal
}

impl Memory {
    // Crée une nouvelle mémoire de taille MAX_ADDRESS, initialisée à Undefined
    pub fn new() -> Self {
        Memory {
            trytes: vec![Tryte::Undefined; MAX_ADDRESS],
        }
    }

    // Crée une nouvelle mémoire d'une taille spécifique (utile pour tests)
    pub fn with_size(size: usize) -> Self {
        Memory {
            trytes: vec![Tryte::Undefined; size],
        }
    }

    // Retourne la taille totale de la mémoire en trytes
    pub fn size(&self) -> usize {
        self.trytes.len()
    }

    // Lit un Tryte à une adresse donnée
    pub fn read_tryte(&self, addr: Address) -> Result<Tryte, MemoryError> {
        if !is_valid_address(addr) || addr >= self.size() {
            // Vérifie les limites
            Err(MemoryError::OutOfBounds)
        } else {
            // Accès direct via indexation, Rust garantit que l'index est valide ici
            // .clone() est nécessaire car Vec::get retourne une référence,
            // mais Tryte est Copy donc le clonage est très peu coûteux.
            Ok(self.trytes[addr].clone())
        }
    }

    // Écrit un Tryte à une adresse donnée
    pub fn write_tryte(&mut self, addr: Address, data: Tryte) -> Result<(), MemoryError> {
        if !is_valid_address(addr) || addr >= self.size() {
            // Vérifie les limites
            Err(MemoryError::OutOfBounds)
        } else {
            self.trytes[addr] = data; // Écrit la donnée
            Ok(())
        }
    }

    // Vérifie si une adresse est alignée pour un accès Mot (multiple de 8)
    fn is_word_aligned(addr: Address) -> bool {
        addr % 8 == 0
    }

    // Lit un Mot (Word = 8 Trytes) à une adresse donnée (doit être alignée)
    pub fn read_word(&self, addr: Address) -> Result<Word, MemoryError> {
        if !Self::is_word_aligned(addr) {
            return Err(MemoryError::Misaligned);
        }
        // Vérifie si l'adresse + la taille du mot sont dans les limites
        if !is_valid_address(addr)
            || addr
                .checked_add(7)
                .map_or(true, |end_addr| end_addr >= self.size())
        {
            return Err(MemoryError::OutOfBounds);
        }

        // Crée un buffer temporaire pour le mot
        let mut word_trytes = [Tryte::Undefined; 8];
        // Lecture Little-Endian : Tryte 0 à addr, Tryte 1 à addr+1, ...
        for i in 0..8 {
            // read_tryte gère déjà les limites individuellement, mais la vérif globale est plus propre.
            // On peut utiliser un accès direct ici car on a déjà vérifié les bornes globales.
            word_trytes[i] = self.trytes[addr + i].clone();
        }

        Ok(Word(word_trytes)) // Retourne le mot construit
    }

    // Écrit un Mot (Word = 8 Trytes) à une adresse donnée (doit être alignée)
    pub fn write_word(&mut self, addr: Address, word_data: Word) -> Result<(), MemoryError> {
        if !Self::is_word_aligned(addr) {
            return Err(MemoryError::Misaligned);
        }
        // Vérifie si l'adresse + la taille du mot sont dans les limites
        if !is_valid_address(addr)
            || addr
                .checked_add(7)
                .map_or(true, |end_addr| end_addr >= self.size())
        {
            return Err(MemoryError::OutOfBounds);
        }

        // Écriture Little-Endian : Tryte 0 à addr, Tryte 1 à addr+1, ...
        let source_trytes = word_data.trytes(); // Récupère les trytes du mot à écrire
        for i in 0..8 {
            // Accès direct car les bornes globales sont vérifiées.
            self.trytes[addr + i] = source_trytes[i].clone();
        }

        Ok(())
    }
}

// --- Tests Unitaires pour la Mémoire ---
#[cfg(test)]
mod tests {
    use super::*; // Importe Memory, MemoryError, etc.
    use crate::core::{Address, Tryte, Word};

    #[test]
    fn test_memory_init() {
        let mem = Memory::new();
        assert_eq!(mem.size(), MAX_ADDRESS);
        // Vérifie que le premier et dernier tryte sont Undefined
        assert_eq!(mem.read_tryte(0), Ok(Tryte::Undefined));
        assert_eq!(mem.read_tryte(MAX_ADDRESS - 1), Ok(Tryte::Undefined));
    }

    #[test]
    fn test_tryte_read_write() {
        let mut mem = Memory::with_size(100); // Utilise une petite mémoire pour tests
        let addr: Address = 50;
        let data = Tryte::Digit(10); // 'A'

        // Écrire
        assert_eq!(mem.write_tryte(addr, data), Ok(()));

        // Lire
        assert_eq!(mem.read_tryte(addr), Ok(data));

        // Lire une autre adresse (devrait être Undefined)
        assert_eq!(mem.read_tryte(addr + 1), Ok(Tryte::Undefined));
    }

    #[test]
    fn test_tryte_out_of_bounds() {
        let mut mem = Memory::with_size(100);
        assert_eq!(mem.read_tryte(100), Err(MemoryError::OutOfBounds));
        assert_eq!(
            mem.write_tryte(100, Tryte::Null),
            Err(MemoryError::OutOfBounds)
        );
        // Test avec une adresse négative (si Address était signé) ou très grande
        assert_eq!(mem.read_tryte(usize::MAX), Err(MemoryError::OutOfBounds));
    }

    #[test]
    fn test_word_read_write_aligned() {
        let mut mem = Memory::with_size(100);
        let addr: Address = 16; // Adresse alignée (16 % 8 == 0)
        let word_val = Word([
            Tryte::Digit(0),
            Tryte::Digit(1),
            Tryte::Digit(2),
            Tryte::Digit(3),
            Tryte::Digit(4),
            Tryte::Digit(5),
            Tryte::Digit(6),
            Tryte::Digit(7),
        ]);

        // Écrire
        assert_eq!(mem.write_word(addr, word_val), Ok(()));

        // Lire
        assert_eq!(mem.read_word(addr), Ok(word_val));

        // Vérifier les trytes individuellement (endianness)
        assert_eq!(mem.read_tryte(addr), Ok(Tryte::Digit(0))); // T0
        assert_eq!(mem.read_tryte(addr + 1), Ok(Tryte::Digit(1))); // T1
        assert_eq!(mem.read_tryte(addr + 7), Ok(Tryte::Digit(7))); // T7
    }

    #[test]
    fn test_word_misaligned() {
        let mut mem = Memory::with_size(100);
        let addr: Address = 17; // Adresse non alignée
        let word_val = Word::zero();

        assert_eq!(mem.read_word(addr), Err(MemoryError::Misaligned));
        assert_eq!(mem.write_word(addr, word_val), Err(MemoryError::Misaligned));
    }

    #[test]
    fn test_word_out_of_bounds() {
        let mut mem = Memory::with_size(100);
        let word_val = Word::zero();

        // Adresse de début valide mais fin hors limites
        let addr_near_end: Address = 96; // 96 est aligné. 96+7 = 103. Taille = 100.
        assert!(addr_near_end % 8 == 0);
        assert_eq!(mem.read_word(addr_near_end), Err(MemoryError::OutOfBounds));
        assert_eq!(
            mem.write_word(addr_near_end, word_val),
            Err(MemoryError::OutOfBounds)
        );

        // Adresse de début hors limites
        let addr_out: Address = 104; // 104 est aligné
        assert!(addr_out % 8 == 0);
        assert_eq!(mem.read_word(addr_out), Err(MemoryError::OutOfBounds));
        assert_eq!(
            mem.write_word(addr_out, word_val),
            Err(MemoryError::OutOfBounds)
        );
    }
}
