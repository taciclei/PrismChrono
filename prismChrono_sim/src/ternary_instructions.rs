// src/ternary_instructions.rs
// Implémentation des instructions spécialisées ternaires pour PrismChrono

use crate::core::{Trit, Tryte, Word};
use crate::alu;

/// Effectue une comparaison ternaire entre deux mots
/// Retourne:
/// - TRIT_N (-1) si a < b
/// - TRIT_Z (0) si a = b
/// - TRIT_P (+1) si a > b
pub fn tcmp3(a: Word, b: Word) -> Word {
    let mut result = Word::default_zero();
    
    // Comparaison des mots
    if a == b {
        // Les mots sont égaux, on retourne 0 (Z)
        if let Some(tryte_result) = result.tryte_mut(0) {
            *tryte_result = Tryte::from_i8(0);
        }
    } else {
        // Comparaison trit par trit, en commençant par les plus significatifs
        for i in (0..8).rev() {
            if let (Some(tryte_a), Some(tryte_b)) = (a.tryte(i), b.tryte(i)) {
                let val_a = tryte_a.to_i8();
                let val_b = tryte_b.to_i8();
                
                if val_a != val_b {
                    // On a trouvé une différence
                    if let Some(tryte_result) = result.tryte_mut(0) {
                        if val_a < val_b {
                            // a < b, on retourne -1 (N)
                            *tryte_result = Tryte::from_i8(-1);
                        } else {
                            // a > b, on retourne 1 (P)
                            *tryte_result = Tryte::from_i8(1);
                        }
                    }
                    break;
                }
            }
        }
    }
    
    result
}

/// Calcule la valeur absolue ternaire d'un mot
/// Si le mot est négatif, inverse tous les trits
/// Si le mot est positif ou zéro, le laisse inchangé
pub fn abs_t(a: Word) -> Word {
    // Vérifier si le mot est négatif en examinant le trit le plus significatif
    if let Some(msb_tryte) = a.tryte(7) {
        let msb_trit = msb_tryte.get_trit(2); // Trit le plus significatif
        
        if msb_trit == Trit::N {
            // Le mot est négatif, on inverse tous les trits
            return alu::trit_inv_word(a);
        }
    }
    
    // Le mot est positif ou zéro, on le retourne tel quel
    a
}

/// Extrait le signe d'un mot sous forme ternaire
/// Retourne:
/// - TRIT_N (-1) si a < 0
/// - TRIT_Z (0) si a = 0
/// - TRIT_P (+1) si a > 0
pub fn signum_t(a: Word) -> Word {
    let mut result = Word::default_zero();
    
    // Vérifier si le mot est nul
    let mut is_zero = true;
    for i in 0..8 {
        if let Some(tryte) = a.tryte(i) {
            if tryte.to_i8() != 0 {
                is_zero = false;
                break;
            }
        }
    }
    
    if is_zero {
        // Le mot est nul, on retourne 0 (Z)
        return result;
    }
    
    // Vérifier le signe en examinant le trit le plus significatif
    if let Some(msb_tryte) = a.tryte(7) {
        let msb_trit = msb_tryte.get_trit(2); // Trit le plus significatif
        
        if let Some(tryte_result) = result.tryte_mut(0) {
            match msb_trit {
                Trit::N => *tryte_result = Tryte::from_i8(-1), // Négatif
                Trit::P => *tryte_result = Tryte::from_i8(1),  // Positif
                _ => {} // Cas impossible car on a déjà vérifié que le mot n'est pas nul
            }
        }
    }
    
    result
}

/// Extrait un tryte spécifique d'un mot
/// Retourne un mot avec le tryte extrait dans les trits de poids faible
pub fn extract_tryte(a: Word, index: usize) -> Word {
    let mut result = Word::default_zero();
    
    if index < 8 {
        if let (Some(tryte_a), Some(tryte_result)) = (a.tryte(index), result.tryte_mut(0)) {
            *tryte_result = tryte_a;
        }
    }
    
    result
}

/// Insère un tryte dans un mot à la position spécifiée
/// Retourne une copie de a avec le tryte remplacé à la position index
pub fn insert_tryte(a: Word, index: usize, tryte_value: Tryte) -> Word {
    let mut result = a;
    
    if index < 8 {
        if let Some(tryte_result) = result.tryte_mut(index) {
            *tryte_result = tryte_value;
        }
    }
    
    result
}

/// Vérifie si un mot est valide (ne contient aucun tryte spécial)
/// Retourne un mot avec TRIT_P (1) si valide, TRIT_N (-1) sinon
pub fn checkw_valid(a: Word) -> Word {
    let mut result = Word::default_zero();
    let mut is_valid = true;
    
    // Vérifier chaque tryte
    for i in 0..8 {
        if let Some(tryte) = a.tryte(i) {
            if tryte.is_undef() || tryte.is_null() || tryte.is_nan() {
                is_valid = false;
                break;
            }
        }
    }
    
    // Mettre le résultat dans le premier tryte
    if let Some(tryte_result) = result.tryte_mut(0) {
        if is_valid {
            *tryte_result = Tryte::from_i8(1); // Valide (P)
        } else {
            *tryte_result = Tryte::from_i8(-1); // Invalide (N)
        }
    }
    
    result
}

/// Vérifie si un tryte spécifique est un état spécial
/// Retourne un mot avec TRIT_P (1) si c'est un état spécial, TRIT_N (-1) sinon
pub fn is_special_tryte(a: Word, index: usize) -> Word {
    let mut result = Word::default_zero();
    
    if index < 8 {
        if let (Some(tryte), Some(tryte_result)) = (a.tryte(index), result.tryte_mut(0)) {
            if tryte.is_undef() || tryte.is_null() || tryte.is_nan() {
                *tryte_result = Tryte::from_i8(1); // C'est un état spécial (P)
            } else {
                *tryte_result = Tryte::from_i8(-1); // Ce n'est pas un état spécial (N)
            }
        }
    }
    
    result
}

/// Convertit une valeur décimale en base 60 (pour les applications temporelles)
/// Retourne un mot contenant les composantes en base 60 (heures, minutes, secondes)
pub fn decimal_to_base60(value: f64) -> Word {
    let mut result = Word::default_zero();
    
    // Convertir en secondes totales
    let total_seconds = (value * 3600.0) as i32;
    
    // Extraire les heures, minutes et secondes
    let hours = total_seconds / 3600;
    let minutes = (total_seconds % 3600) / 60;
    let seconds = total_seconds % 60;
    
    // Stocker les valeurs dans le mot résultat
    // Secondes dans le premier tryte
    if let Some(tryte) = result.tryte_mut(0) {
        *tryte = Tryte::from_i8(seconds as i8);
    }
    
    // Minutes dans le deuxième tryte
    if let Some(tryte) = result.tryte_mut(1) {
        *tryte = Tryte::from_i8(minutes as i8);
    }
    
    // Heures dans le troisième tryte
    if let Some(tryte) = result.tryte_mut(2) {
        *tryte = Tryte::from_i8(hours as i8);
    }
    
    result
}

/// Convertit un mot contenant des composantes en base 60 en valeur décimale
pub fn base60_to_decimal(a: Word) -> f64 {
    let mut decimal = 0.0;
    
    // Extraire les secondes du premier tryte
    if let Some(tryte) = a.tryte(0) {
        decimal += tryte.to_i8() as f64 / 3600.0;
    }
    
    // Extraire les minutes du deuxième tryte
    if let Some(tryte) = a.tryte(1) {
        decimal += tryte.to_i8() as f64 / 60.0;
    }
    
    // Extraire les heures du troisième tryte
    if let Some(tryte) = a.tryte(2) {
        decimal += tryte.to_i8() as f64;
    }
    
    decimal
}

/// Effectue une addition en base 60 de deux mots
pub fn add_base60(a: Word, b: Word) -> Word {
    let mut result = Word::default_zero();
    
    // Extraire les composantes
    let mut seconds = 0;
    let mut minutes = 0;
    let mut hours = 0;
    
    // Extraire les secondes
    if let (Some(tryte_a), Some(tryte_b)) = (a.tryte(0), b.tryte(0)) {
        seconds = tryte_a.to_i8() as i32 + tryte_b.to_i8() as i32;
    }
    
    // Extraire les minutes
    if let (Some(tryte_a), Some(tryte_b)) = (a.tryte(1), b.tryte(1)) {
        minutes = tryte_a.to_i8() as i32 + tryte_b.to_i8() as i32;
    }
    
    // Extraire les heures
    if let (Some(tryte_a), Some(tryte_b)) = (a.tryte(2), b.tryte(2)) {
        hours = tryte_a.to_i8() as i32 + tryte_b.to_i8() as i32;
    }
    
    // Normaliser les valeurs
    minutes += seconds / 60;
    seconds %= 60;
    
    hours += minutes / 60;
    minutes %= 60;
    
    // Stocker les valeurs normalisées
    if let Some(tryte) = result.tryte_mut(0) {
        *tryte = Tryte::from_i8(seconds as i8);
    }
    
    if let Some(tryte) = result.tryte_mut(1) {
        *tryte = Tryte::from_i8(minutes as i8);
    }
    
    if let Some(tryte) = result.tryte_mut(2) {
        *tryte = Tryte::from_i8(hours as i8);
    }
    
    result
}