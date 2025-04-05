//! Types fondamentaux pour l'assembleur PrismChrono
//!
//! Ce module contient les définitions des types ternaires fondamentaux
//! utilisés par l'assembleur PrismChrono, copiés depuis le simulateur.

use std::fmt;

// --- Trit ---
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Trit {
    N, // -1
    Z, //  0
    P, // +1
}

impl Trit {
    // Conversion vers une valeur numérique pour les calculs
    pub fn value(&self) -> i8 {
        match self {
            Trit::N => -1,
            Trit::Z => 0,
            Trit::P => 1,
        }
    }

    // Conversion depuis une valeur numérique
    pub fn from_value(val: i8) -> Option<Trit> {
        match val {
            -1 => Some(Trit::N),
            0 => Some(Trit::Z),
            1 => Some(Trit::P),
            _ => None, // Gérer les cas invalides
        }
    }

    // Implémenter l'inverseur ternaire
    pub fn inv(&self) -> Trit {
        match self {
            Trit::N => Trit::P,
            Trit::Z => Trit::Z,
            Trit::P => Trit::N,
        }
    }
}

// Affichage simple (N, Z, P)
impl fmt::Display for Trit {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{}",
            match self {
                Trit::N => 'N',
                Trit::Z => 'Z',
                Trit::P => 'P',
            }
        )
    }
}

// --- Tryte (3 Trits) ---
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub enum Tryte {
    Digit(u8), // Stocke 0-23
    Undefined, // UNDEF (P,P,N => Bal3 +11)
    Null,      // NULL  (P,P,Z => Bal3 +12)
    NaN,       // NaN   (P,P,P => Bal3 +13)
}

impl Tryte {
    // Valeur Bal3 (-13 à +10 pour Digit, +11/12/13 pour Spéciaux)
    pub fn bal3_value(&self) -> i8 {
        match self {
            Tryte::Digit(d) => (*d as i8) - 13, // Convert 0-23 to -13 to +10
            Tryte::Undefined => 11,
            Tryte::Null => 12,
            Tryte::NaN => 13,
        }
    }

    // Créer un Tryte depuis une valeur Bal3 (-13 à +13)
    pub fn from_bal3(val: i8) -> Option<Tryte> {
        match val {
            -13..=10 => Some(Tryte::Digit((val + 13) as u8)),
            11 => Some(Tryte::Undefined),
            12 => Some(Tryte::Null),
            13 => Some(Tryte::NaN),
            _ => None, // Valeur Bal3 invalide
        }
    }

    // Convertir en 3 trits
    pub fn to_trits(&self) -> [Trit; 3] {
        let bal3 = self.bal3_value();
        let mut trits = [Trit::Z; 3];
        let mut current_val = bal3;

        for i in 0..3 {
            let remainder = (current_val + 1) % 3 - 1; // Remainder in {-1, 0, +1}
            trits[i] = Trit::from_value(remainder).unwrap_or(Trit::Z);
            current_val = (current_val - remainder) / 3;
        }
        trits
    }

    // Créer un Tryte depuis 3 trits
    pub fn from_trits(trits: [Trit; 3]) -> Tryte {
        let t0 = trits[0].value();
        let t1 = trits[1].value();
        let t2 = trits[2].value();
        let bal3 = t2 * 9 + t1 * 3 + t0;
        Tryte::from_bal3(bal3).unwrap_or(Tryte::NaN)
    }
}

// Affichage
impl fmt::Display for Tryte {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Tryte::Digit(d) => write!(f, "{}", d),
            Tryte::Undefined => write!(f, "UND"),
            Tryte::Null => write!(f, "NUL"),
            Tryte::NaN => write!(f, "NaN"),
        }
    }
}

// --- Word (24 Trits = 8 Trytes) ---
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct Word(pub [Tryte; 8]);

impl Word {
    // Crée un mot avec une valeur par défaut
    pub fn default_undefined() -> Self {
        Word([Tryte::Undefined; 8])
    }
    
    // Crée un mot zéro
    pub fn zero() -> Self {
        Word([Tryte::Digit(13); 8]) // Tryte 13 a Bal3 = 0, donc (Z,Z,Z)
    }
    
    // Accès aux trytes individuels
    pub fn tryte(&self, index: usize) -> Option<&Tryte> {
        self.0.get(index)
    }
    
    pub fn tryte_mut(&mut self, index: usize) -> Option<&mut Tryte> {
        self.0.get_mut(index)
    }
    
    // Accès direct au tableau
    pub fn trytes(&self) -> &[Tryte; 8] {
        &self.0
    }
    
    pub fn trytes_mut(&mut self) -> &mut [Tryte; 8] {
        &mut self.0
    }
}

// Type pour les adresses mémoire
pub type Address = u32;

// Constante pour l'adresse maximale
pub const MAX_ADDRESS: Address = 0xFFFFFFFF;

// Fonction pour vérifier si une adresse est valide
pub fn is_valid_address(addr: Address) -> bool {
    addr <= MAX_ADDRESS
}