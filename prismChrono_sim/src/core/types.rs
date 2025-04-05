// src/core/types.rs
use std::fmt; // Pour implémenter l'affichage

// --- Trit ---
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)] // Dérivations utiles
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

    // Conversion depuis une valeur numérique (utile pour l'ALU)
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
// Représente soit un chiffre B24 (via sa valeur 0-23) soit un état spécial
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

    // Convertir en 3 trits (pour stockage mémoire ou logique trit-à-trit)
    pub fn to_trits(&self) -> [Trit; 3] {
        let bal3 = self.bal3_value();
        // Calcul classique Bal3 -> Trits (t0 = reste mod 3, t1 = (val/3) mod 3, ...)
        // Attention à l'arithmétique ternaire équilibrée
        let mut trits = [Trit::Z; 3];
        let mut current_val = bal3;

        for i in 0..3 {
            let remainder = (current_val + 1) % 3 - 1; // Remainder in {-1, 0, +1}
            trits[i] = Trit::from_value(remainder).unwrap_or(Trit::Z); // Should always unwrap
            // Division par 3 en ternaire équilibré: (val - remainder) / 3
            current_val = (current_val - remainder) / 3;
        }
        // Assurez-vous que l'ordre t0, t1, t2 est correct (ici t0 est trits[0])
        trits
    }

    // Créer un Tryte depuis 3 trits
    pub fn from_trits(trits: [Trit; 3]) -> Tryte {
        let t0 = trits[0].value();
        let t1 = trits[1].value();
        let t2 = trits[2].value();
        let bal3 = t2 * 9 + t1 * 3 + t0;
        Tryte::from_bal3(bal3).unwrap_or(Tryte::NaN) // Retourner NaN si la combinaison est invalide (ne devrait pas arriver)
    }
}

// Affichage (ex: chiffre B24 ou nom de l'état spécial)
impl fmt::Display for Tryte {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            // Afficher A-N pour 10-23? Pour l'instant, juste les chiffres.
            Tryte::Digit(d) => write!(f, "{}", d),
            Tryte::Undefined => write!(f, "UND"),
            Tryte::Null => write!(f, "NUL"),
            Tryte::NaN => write!(f, "NaN"),
        }
    }
}

// --- Word (24 Trits = 8 Trytes) ---
#[derive(Debug, Copy, Clone, PartialEq, Eq, Hash)]
pub struct Word(pub [Tryte; 8]); // Ajoute 'pub' devant le champ

impl Word {
    // Crée un mot avec une valeur par défaut (ex: Undefined)
    pub fn default_undefined() -> Self {
        Word([Tryte::Undefined; 8])
    }
    // Crée un mot zéro (tous trits Z, ce qui correspond à 8 trytes '13')
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
    // Accès direct au tableau (pour l'implémentation interne)
    pub fn trytes(&self) -> &[Tryte; 8] {
        &self.0
    }
    pub fn trytes_mut(&mut self) -> &mut [Tryte; 8] {
        &mut self.0
    }

    // TODO: Ajouter des méthodes pour convertir vers/depuis une valeur numérique 24 trits (Bal3),
    // manipuler les trits individuels, etc.

    // Crée un mot avec la valeur 1
    pub fn one() -> Self {
        let mut word = Word::zero();
        if let Some(tryte) = word.tryte_mut(0) {
            *tryte = Tryte::Digit(14); // 14 = 1 en ternaire équilibré (13+1=14)
        }
        word
    }

    // Crée un Word à partir d'une valeur entière
    pub fn from_int(val: i32) -> Self {
        let mut word = Word::zero();
        let mut remaining = val;

        // Convertir l'entier en trytes (base 27)
        for i in 0..8 {
            if remaining == 0 {
                break;
            }

            // Calculer la valeur du tryte courant
            let tryte_val = (remaining % 27) as i8 - 13; // Convertir en ternaire équilibré (-13 à +13)

            // Mettre à jour le tryte dans le mot
            if let Some(tryte) = word.tryte_mut(i) {
                *tryte = Tryte::from_bal3(tryte_val).unwrap_or(Tryte::Digit(13)); // 13 = 0 en ternaire équilibré
            }

            // Passer au tryte suivant
            remaining /= 27;
        }

        word
    }

    // Crée un Word à partir d'une valeur ternaire équilibrée (Bal3)
    pub fn from_bal3(val: i8) -> Self {
        let mut word = Word::zero();

        // Placer la valeur dans le premier tryte
        if let Some(tryte) = word.tryte_mut(0) {
            *tryte = Tryte::from_bal3(val).unwrap_or(Tryte::Digit(13)); // 13 = 0 en ternaire équilibré
        }

        word
    }

    // Vérifie si le mot est négatif (trit de poids fort = N)
    pub fn is_negative(&self) -> bool {
        // Trouver le tryte non-nul de poids fort
        for i in (0..8).rev() {
            if let Some(tryte) = self.tryte(i) {
                if *tryte != Tryte::Digit(13) {
                    // 13 = 0 en ternaire équilibré
                    // Vérifier le trit de poids fort de ce tryte
                    let trits = tryte.to_trits();
                    return trits[2] == Trit::N;
                }
            }
        }

        // Si tous les trytes sont nuls, le mot n'est pas négatif
        false
    }
}

// Affichage (ex: séquence de 8 trytes)
impl fmt::Display for Word {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Affiche les trytes T7..T0 (MS Tryte first)
        for i in (0..8).rev() {
            write!(f, "{}", self.0[i])?;
            if i > 0 {
                write!(f, ":")?;
            } // Séparateur
        }
        Ok(())
    }
}

// Implémente Default pour pouvoir utiliser .default() ou dériver sur d'autres structs
impl Default for Word {
    fn default() -> Self {
        Word::default_undefined() // Ou Word::zero() selon la sémantique voulue
    }
}

// --- Address (16 Trits) ---
// Pour la simplicité et l'efficacité de l'indexation mémoire, on utilise un type entier hôte.
// usize est souvent le plus pratique pour indexer Vec/slices.
// Sa taille dépend de l'architecture hôte (32 ou 64 bits),
// mais il peut contenir nos adresses 16 trits (max 16M).
pub type Address = usize;

// Fonction utilitaire (pourrait être dans un module `utils` ou `addr`)
// Vérifie si une adresse (en tant que nombre) est dans les limites valides 16 trits
pub const MAX_ADDRESS: usize = 16_777_216; // 16 MTrytes

pub fn is_valid_address(addr: Address) -> bool {
    addr < MAX_ADDRESS
}

// TODO: Fonctions pour convertir une Address (usize) en représentation 16 trits
// et vice-versa si nécessaire pour l'affichage ou certaines opérations.
