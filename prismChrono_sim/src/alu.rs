// src/alu.rs
// Implémentation des opérations logiques et arithmétiques de l'ALU

use crate::core::{Trit, Tryte, Word};
use crate::cpu::Flags;

/// Inverse tous les trits d'un mot (24 trits)
/// Chaque trit est inversé selon la règle: N -> P, Z -> Z, P -> N
pub fn trit_inv_word(a: Word) -> Word {
    let mut result = Word::default_undefined();

    // Parcourir chaque tryte du mot
    for i in 0..8 {
        if let (Some(tryte_a), Some(tryte_result)) = (a.tryte(i), result.tryte_mut(i)) {
            // Pour les états spéciaux, on les préserve
            match tryte_a {
                Tryte::Undefined => *tryte_result = Tryte::Undefined,
                Tryte::Null => *tryte_result = Tryte::Null,
                Tryte::NaN => *tryte_result = Tryte::NaN,
                Tryte::Digit(_) => {
                    // Convertir le tryte en trits, inverser chaque trit, puis reconvertir en tryte
                    let trits_a = tryte_a.to_trits();
                    let mut inverted_trits = [Trit::Z; 3];

                    for j in 0..3 {
                        inverted_trits[j] = trits_a[j].inv();
                    }

                    *tryte_result = Tryte::from_trits(inverted_trits);
                }
            }
        }
    }

    result
}

/// Calcule le minimum trit-à-trit de deux mots (24 trits)
/// Pour chaque position, le résultat est le trit de valeur minimale entre a et b
/// Règle: min(N, X) = N, min(Z, X) = min(Z, X), min(P, X) = X
pub fn trit_min_word(a: Word, b: Word) -> Word {
    let mut result = Word::default_undefined();

    // Parcourir chaque tryte des mots
    for i in 0..8 {
        if let (Some(tryte_a), Some(tryte_b), Some(tryte_result)) =
            (a.tryte(i), b.tryte(i), result.tryte_mut(i))
        {
            // Convertir les trytes en trits
            let trits_a = tryte_a.to_trits();
            let trits_b = tryte_b.to_trits();
            let mut min_trits = [Trit::Z; 3];

            // Calculer le minimum pour chaque trit
            for j in 0..3 {
                min_trits[j] = match (trits_a[j], trits_b[j]) {
                    (Trit::N, _) => Trit::N,
                    (_, Trit::N) => Trit::N,
                    (Trit::Z, Trit::Z) => Trit::Z,
                    (Trit::Z, Trit::P) => Trit::Z,
                    (Trit::P, Trit::Z) => Trit::Z,
                    (Trit::P, Trit::P) => Trit::P,
                };
            }

            *tryte_result = Tryte::from_trits(min_trits);
        }
    }

    result
}

/// Calcule le maximum trit-à-trit de deux mots (24 trits)
/// Pour chaque position, le résultat est le trit de valeur maximale entre a et b
/// Règle: max(P, X) = P, max(Z, X) = max(Z, X), max(N, X) = X
pub fn trit_max_word(a: Word, b: Word) -> Word {
    let mut result = Word::default_undefined();

    // Parcourir chaque tryte des mots
    for i in 0..8 {
        if let (Some(tryte_a), Some(tryte_b), Some(tryte_result)) =
            (a.tryte(i), b.tryte(i), result.tryte_mut(i))
        {
            // Convertir les trytes en trits
            let trits_a = tryte_a.to_trits();
            let trits_b = tryte_b.to_trits();
            let mut max_trits = [Trit::Z; 3];

            // Calculer le maximum pour chaque trit
            for j in 0..3 {
                max_trits[j] = match (trits_a[j], trits_b[j]) {
                    (Trit::P, _) => Trit::P,
                    (_, Trit::P) => Trit::P,
                    (Trit::Z, Trit::Z) => Trit::Z,
                    (Trit::Z, Trit::N) => Trit::Z,
                    (Trit::N, Trit::Z) => Trit::Z,
                    (Trit::N, Trit::N) => Trit::N,
                };
            }

            *tryte_result = Tryte::from_trits(max_trits);
        }
    }

    result
}

/// Implémente un additionneur complet 1-trit
/// Prend deux trits a et b, ainsi qu'une retenue d'entrée cin
/// Retourne un tuple (sum, cout) où sum est le trit résultat et cout la retenue de sortie
pub fn ternary_full_adder(a: Trit, b: Trit, cin: Trit) -> (Trit, Trit) {
    // Convertir les trits en valeurs numériques pour faciliter le calcul
    let a_val = a.value();
    let b_val = b.value();
    let cin_val = cin.value();

    // Calculer la somme totale (entre -3 et +3)
    let total = a_val + b_val + cin_val;

    // Déterminer le trit résultat et la retenue
    match total {
        -3 => (Trit::Z, Trit::N),                       // -3 = 0 + (-1 * 3)
        -2 => (Trit::N, Trit::N),                       // -2 = -1 + (-1 * 1)
        -1 => (Trit::N, Trit::Z),                       // -1 = -1 + (0 * 3)
        0 => (Trit::Z, Trit::Z),                        // 0 = 0 + (0 * 3)
        1 => (Trit::P, Trit::Z),                        // 1 = 1 + (0 * 3)
        2 => (Trit::N, Trit::P),                        // 2 = -1 + (1 * 3)
        3 => (Trit::Z, Trit::P),                        // 3 = 0 + (1 * 3)
        _ => panic!("Invalid ternary addition result"), // Ne devrait jamais arriver
    }
}

/// Implémente l'addition de deux mots de 24 trits (8 trytes)
/// Prend deux mots a et b, ainsi qu'une retenue d'entrée cin
/// Retourne un tuple (result, cout, flags) où result est le mot résultat,
/// cout est la retenue de sortie et flags contient les drapeaux mis à jour
pub fn add_24_trits(a: Word, b: Word, cin: Trit) -> (Word, Trit, Flags) {
    let mut result = Word::default_undefined();
    let mut carry = cin;
    let mut flags = Flags::new();
    let mut all_zeros = true;
    let mut has_special = false;

    // Parcourir chaque tryte des mots (de poids faible à poids fort)
    for i in 0..8 {
        if let (Some(tryte_a), Some(tryte_b), Some(tryte_result)) =
            (a.tryte(i), b.tryte(i), result.tryte_mut(i))
        {
            // Gestion des états spéciaux
            match (tryte_a, tryte_b) {
                // Si l'un des opérandes est NaN, le résultat est NaN
                (Tryte::NaN, _) | (_, Tryte::NaN) => {
                    *tryte_result = Tryte::NaN;
                    has_special = true;
                }
                // Si l'un des opérandes est Null et l'autre n'est pas NaN, le résultat est Null
                (Tryte::Null, _) | (_, Tryte::Null) => {
                    *tryte_result = Tryte::Null;
                    has_special = true;
                }
                // Si l'un des opérandes est Undefined et l'autre n'est ni NaN ni Null, le résultat est Undefined
                (Tryte::Undefined, _) | (_, Tryte::Undefined) => {
                    *tryte_result = Tryte::Undefined;
                    has_special = true;
                }
                // Sinon, effectuer l'addition normale
                (Tryte::Digit(_), Tryte::Digit(_)) => {
                    // Convertir les trytes en trits
                    let trits_a = tryte_a.to_trits();
                    let trits_b = tryte_b.to_trits();
                    let mut sum_trits = [Trit::Z; 3];

                    // Additionner chaque trit avec propagation de la retenue
                    for j in 0..3 {
                        let (sum, cout) = ternary_full_adder(trits_a[j], trits_b[j], carry);
                        sum_trits[j] = sum;
                        carry = cout;
                    }

                    // Convertir le résultat en tryte
                    *tryte_result = Tryte::from_trits(sum_trits);

                    // Vérifier si le tryte résultat est non-nul pour le flag ZF
                    if *tryte_result != Tryte::Digit(13) {
                        // 13 = (Z,Z,Z) = 0
                        all_zeros = false;
                    }
                }
            }
        }
    }

    // Mettre à jour les flags
    flags.zf = all_zeros && !has_special; // ZF = 1 si tous les trits sont Z et pas d'état spécial

    // SF = 1 si le trit de poids fort est N (négatif)
    if let Some(msb_tryte) = result.tryte(7) {
        // Tryte de poids fort
        if let Tryte::Digit(_) = msb_tryte {
            let msb_trits = msb_tryte.to_trits();
            flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
        }
    }

    // XF = 1 si des états spéciaux sont présents
    flags.xf = has_special;

    (result, carry, flags)
}

/// Implémente la soustraction de deux mots de 24 trits (8 trytes)
/// Prend deux mots a et b, ainsi qu'un emprunt d'entrée bin
/// Retourne un tuple (result, bout, flags) où result est le mot résultat,
/// bout est l'emprunt de sortie et flags contient les drapeaux mis à jour
pub fn sub_24_trits(a: Word, b: Word, bin: Trit) -> (Word, Trit, Flags) {
    let mut result = Word::default_undefined();
    let mut borrow = bin;
    let mut flags = Flags::new();
    let mut all_zeros = true;
    let mut has_special = false;

    // Parcourir chaque tryte des mots (de poids faible à poids fort)
    for i in 0..8 {
        if let (Some(tryte_a), Some(tryte_b), Some(tryte_result)) =
            (a.tryte(i), b.tryte(i), result.tryte_mut(i))
        {
            // Gestion des états spéciaux
            match (tryte_a, tryte_b) {
                // Si l'un des opérandes est NaN, le résultat est NaN
                (Tryte::NaN, _) | (_, Tryte::NaN) => {
                    *tryte_result = Tryte::NaN;
                    has_special = true;
                }
                // Si l'un des opérandes est Null et l'autre n'est pas NaN, le résultat est Null
                (Tryte::Null, _) | (_, Tryte::Null) => {
                    *tryte_result = Tryte::Null;
                    has_special = true;
                }
                // Si l'un des opérandes est Undefined et l'autre n'est ni NaN ni Null, le résultat est Undefined
                (Tryte::Undefined, _) | (_, Tryte::Undefined) => {
                    *tryte_result = Tryte::Undefined;
                    has_special = true;
                }
                // Sinon, effectuer la soustraction normale
                (Tryte::Digit(_), Tryte::Digit(_)) => {
                    // Convertir les trytes en trits
                    let trits_a = tryte_a.to_trits();
                    let trits_b = tryte_b.to_trits();
                    let mut diff_trits = [Trit::Z; 3];

                    // Soustraire chaque trit avec propagation de l'emprunt
                    for j in 0..3 {
                        // Inverser le trit de b et ajouter
                        let neg_b_trit = trits_b[j].inv();
                        let (diff, cout) = ternary_full_adder(trits_a[j], neg_b_trit, borrow.inv());
                        diff_trits[j] = diff;
                        borrow = cout.inv(); // L'emprunt est l'inverse de la retenue
                    }

                    // Convertir le résultat en tryte
                    *tryte_result = Tryte::from_trits(diff_trits);

                    // Vérifier si le tryte résultat est non-nul pour le flag ZF
                    if *tryte_result != Tryte::Digit(13) {
                        // 13 = (Z,Z,Z) = 0
                        all_zeros = false;
                    }
                }
            }
        }
    }

    // Mettre à jour les flags
    flags.zf = all_zeros && !has_special; // ZF = 1 si tous les trits sont Z et pas d'état spécial

    // SF = 1 si le trit de poids fort est N (négatif)
    if let Some(msb_tryte) = result.tryte(7) {
        // Tryte de poids fort
        if let Tryte::Digit(_) = msb_tryte {
            let msb_trits = msb_tryte.to_trits();
            flags.sf = msb_trits[2] == Trit::N; // Trit de poids fort = N?
        }
    }

    // XF = 1 si des états spéciaux sont présents
    flags.xf = has_special;

    (result, borrow, flags)
}

/// Implémente la comparaison de deux mots de 24 trits (8 trytes)
/// Retourne les flags mis à jour après une soustraction (sans modifier les opérandes)
pub fn compare_24_trits(a: Word, b: Word) -> Flags {
    // Effectue une soustraction a - b sans emprunt d'entrée
    let (_, _, flags) = sub_24_trits(a, b, Trit::Z);

    // Retourne les flags calculés par sub_24_trits
    flags
}

/// Implémente la multiplication de deux mots de 24 trits (8 trytes)
/// Retourne le résultat de la multiplication
pub fn mul_24_trits(a: Word, b: Word) -> Word {
    let mut result = Word::zero();

    // Cas spéciaux: si l'un des opérandes est zéro, le résultat est zéro
    if a == Word::zero() || b == Word::zero() {
        return result;
    }

    // Multiplication par addition répétée (algorithme simple)
    // Pour chaque bit de b, si le bit est 1, ajouter a décalé à la position appropriée
    let mut temp_a = a;

    for i in 0..8 {
        // Pour chaque tryte de b
        if let Some(tryte_b) = b.tryte(i) {
            if let Tryte::Digit(val_b) = tryte_b {
                // Convertir la valeur du tryte en valeur signée (-13 à +13)
                let signed_val_b = (*val_b as i8) - 13;

                // Si la valeur est non nulle, ajouter a décalé
                if signed_val_b != 0 {
                    // Créer une copie de a
                    let temp = temp_a;

                    // Multiplier par la valeur absolue
                    let abs_val_b = signed_val_b.abs() as u8;
                    for _ in 0..abs_val_b {
                        let (new_result, _, _) = add_24_trits(result, temp, Trit::Z);
                        result = new_result;
                    }

                    // Si la valeur est négative, inverser le résultat
                    if signed_val_b < 0 {
                        result = trit_inv_word(result);
                        let (new_result, _, _) = add_24_trits(result, Word::one(), Trit::Z);
                        result = new_result;
                    }
                }
            }
        }

        // Décaler temp_a de 3 positions (1 tryte) vers la gauche pour la prochaine itération
        if i < 7 {
            // Pas besoin de décaler pour la dernière itération
            temp_a = shl_24_trits(temp_a, Word::from_int(3));
        }
    }

    result
}

/// Implémente la division de deux mots de 24 trits (8 trytes)
/// Retourne le quotient de la division
pub fn div_24_trits(a: Word, b: Word) -> Word {
    // Cas spéciaux
    if b == Word::zero() {
        // Division par zéro - retourner un mot avec tous les trits à Z
        return Word::zero();
    }

    if a == Word::zero() {
        // 0 divisé par n'importe quoi donne 0
        return Word::zero();
    }

    // Algorithme de division par soustraction répétée
    let mut quotient = Word::zero();
    let mut remainder = a;

    // Déterminer le signe du résultat
    let a_negative = a.is_negative();
    let b_negative = b.is_negative();
    let result_negative = a_negative != b_negative;

    // Travailler avec des valeurs absolues
    let abs_b = if b_negative { trit_inv_word(b) } else { b };

    // Division par soustraction répétée
    while compare_24_trits(remainder, abs_b).sf == false {
        // Tant que remainder >= abs_b
        let (new_remainder, _, _) = sub_24_trits(remainder, abs_b, Trit::Z);
        remainder = new_remainder;

        // Incrémenter le quotient
        let (new_quotient, _, _) = add_24_trits(quotient, Word::one(), Trit::Z);
        quotient = new_quotient;
    }

    // Appliquer le signe au résultat si nécessaire
    if result_negative {
        quotient = trit_inv_word(quotient);
        let (new_quotient, _, _) = add_24_trits(quotient, Word::one(), Trit::Z);
        quotient = new_quotient;
    }

    quotient
}

/// Implémente le modulo de deux mots de 24 trits (8 trytes)
/// Retourne le reste de la division
pub fn mod_24_trits(a: Word, b: Word) -> Word {
    // Cas spéciaux
    if b == Word::zero() {
        // Modulo par zéro - retourner un mot avec tous les trits à Z
        return Word::zero();
    }

    if a == Word::zero() {
        // 0 modulo n'importe quoi donne 0
        return Word::zero();
    }

    // Algorithme de modulo par soustraction répétée
    // Déterminer le signe du résultat (le signe du reste est le même que celui du dividende)
    let a_negative = a.is_negative();

    // Travailler avec des valeurs absolues
    let abs_a = if a_negative { trit_inv_word(a) } else { a };
    let abs_b = if b.is_negative() { trit_inv_word(b) } else { b };

    let mut remainder = abs_a;

    // Modulo par soustraction répétée
    while compare_24_trits(remainder, abs_b).sf == false {
        // Tant que remainder >= abs_b
        let (new_remainder, _, _) = sub_24_trits(remainder, abs_b, Trit::Z);
        remainder = new_remainder;
    }

    // Appliquer le signe au résultat si nécessaire
    if a_negative && remainder != Word::zero() {
        remainder = trit_inv_word(remainder);
        let (new_remainder, _, _) = add_24_trits(remainder, Word::one(), Trit::Z);
        remainder = new_remainder;
    }

    remainder
}

/// Implémente le décalage à gauche d'un mot de 24 trits
/// Décale les trits de a vers la gauche de la valeur spécifiée par b
pub fn shl_24_trits(a: Word, b: Word) -> Word {
    let mut result = Word::zero();

    // Convertir b en un entier non signé pour le nombre de positions à décaler
    let mut shift_amount: i32 = 0;
    if let Some(tryte) = b.tryte(0) {
        if let Tryte::Digit(val) = tryte {
            // Convertir la valeur du tryte en nombre de positions (0-26)
            shift_amount = (*val as i32) % 24; // Limiter à 24 positions max
        }
    }

    // Si le décalage est nul, retourner a inchangé
    if shift_amount == 0 {
        return a;
    }

    // Décaler les trits vers la gauche
    for i in 0..8 {
        let i_i32 = i as i32;
        for j in 0..3 {
            let j_i32 = j as i32;
            let trit_pos: i32 = i_i32 * 3 + j_i32;
            let src_pos = trit_pos.checked_sub(shift_amount);

            if let Some(src_idx) = src_pos {
                // Calculer les indices de tryte et de trit pour la source
                let src_tryte_idx = src_idx / 3;
                let src_trit_idx = src_idx % 3;

                // Récupérer le trit source
                if let Some(src_tryte) = a.tryte(src_tryte_idx as usize) {
                    let src_trits = src_tryte.to_trits();
                    let src_trit = src_trits[src_trit_idx as usize];

                    // Mettre à jour le trit dans le résultat
                    if let Some(dst_tryte) = result.tryte_mut(i) {
                        let mut dst_trits = dst_tryte.to_trits();
                        dst_trits[j] = src_trit;
                        *dst_tryte = Tryte::from_trits(dst_trits);
                    }
                }
            }
        }
    }

    result
}

/// Implémente le décalage à droite d'un mot de 24 trits
/// Décale les trits de a vers la droite de la valeur spécifiée par b
pub fn shr_24_trits(a: Word, b: Word) -> Word {
    let mut result = Word::zero();

    // Convertir b en un entier non signé pour le nombre de positions à décaler
    let mut shift_amount: i32 = 0;
    if let Some(tryte) = b.tryte(0) {
        if let Tryte::Digit(val) = tryte {
            // Convertir la valeur du tryte en nombre de positions (0-26)
            shift_amount = (*val as i32) % 24; // Limiter à 24 positions max
        }
    }

    // Si le décalage est nul, retourner a inchangé
    if shift_amount == 0 {
        return a;
    }

    // Décaler les trits vers la droite
    for i in 0..8 {
        let i_i32 = i as i32;
        for j in 0..3 {
            let j_i32 = j as i32;
            let trit_pos: i32 = i_i32 * 3 + j_i32;
            let src_pos = trit_pos + shift_amount;

            if src_pos < 24 {
                // 24 trits au total
                // Calculer les indices de tryte et de trit pour la source
                let src_tryte_idx = src_pos / 3;
                let src_trit_idx = src_pos % 3;

                // Récupérer le trit source
                if let Some(src_tryte) = a.tryte(src_tryte_idx as usize) {
                    let src_trits = src_tryte.to_trits();
                    let src_trit = src_trits[src_trit_idx as usize];

                    // Mettre à jour le trit dans le résultat
                    if let Some(dst_tryte) = result.tryte_mut(i) {
                        let mut dst_trits = dst_tryte.to_trits();
                        dst_trits[j] = src_trit;
                        *dst_tryte = Tryte::from_trits(dst_trits);
                    }
                }
            }
        }
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::{Trit, Tryte, Word};

    // Fonction utilitaire pour créer un Word à partir d'un tableau de Trytes
    fn create_word(trytes: [Tryte; 8]) -> Word {
        Word(trytes)
    }

    #[test]
    fn test_trit_inv_word() {
        // Créer un mot avec des valeurs connues
        let trytes = [
            Tryte::Digit(0),  // Contient des trits N
            Tryte::Digit(13), // Contient des trits Z
            Tryte::Digit(23), // Contient des trits P
            Tryte::Undefined, // État spécial
            Tryte::Null,      // État spécial
            Tryte::NaN,       // État spécial
            Tryte::Digit(5),  // Mélange de trits
            Tryte::Digit(18), // Mélange de trits
        ];

        let word = create_word(trytes);
        let inverted = trit_inv_word(word);

        // Vérifier que l'inversion est correcte pour quelques trytes
        if let Some(tryte) = word.tryte(0) {
            let trits = tryte.to_trits();
            let inv_trits = inverted.tryte(0).unwrap().to_trits();
            for i in 0..3 {
                assert_eq!(inv_trits[i], trits[i].inv());
            }
        }

        // Vérifier que l'inversion de l'inversion donne le mot original
        let double_inverted = trit_inv_word(inverted);
        for i in 0..8 {
            if let (Some(original), Some(result)) = (word.tryte(i), double_inverted.tryte(i)) {
                // Pour les états spéciaux, la double inversion peut ne pas être identique
                // On ne vérifie donc que pour les Digits
                if let Tryte::Digit(_) = original {
                    assert_eq!(original, result);
                }
            }
        }
    }

    #[test]
    fn test_trit_min_word() {
        // Créer deux mots avec des valeurs connues
        let trytes_a = [
            Tryte::Digit(0),  // N,N,N
            Tryte::Digit(13), // Z,Z,Z
            Tryte::Digit(23), // P,P,P
            Tryte::Digit(1),  // N,N,Z
            Tryte::Digit(4),  // N,P,N
            Tryte::Digit(10), // Z,N,P
            Tryte::Digit(5),  // N,P,Z
            Tryte::Digit(18), // P,Z,P
        ];

        let trytes_b = [
            Tryte::Digit(23), // P,P,P
            Tryte::Digit(0),  // N,N,N
            Tryte::Digit(13), // Z,Z,Z
            Tryte::Digit(22), // P,P,N
            Tryte::Digit(19), // P,P,Z
            Tryte::Digit(14), // Z,Z,P
            Tryte::Digit(9),  // Z,N,Z
            Tryte::Digit(3),  // N,Z,Z
        ];

        let word_a = create_word(trytes_a);
        let word_b = create_word(trytes_b);

        let min_result = trit_min_word(word_a, word_b);

        // Vérifier quelques résultats attendus
        // min(N,N,N, P,P,P) = N,N,N
        assert_eq!(min_result.tryte(0), word_a.tryte(0));
        // min(Z,Z,Z, N,N,N) = N,N,N
        assert_eq!(min_result.tryte(1), word_b.tryte(1));
        // min(P,P,P, Z,Z,Z) = Z,Z,Z
        assert_eq!(min_result.tryte(2), word_b.tryte(2));
    }

    #[test]
    fn test_trit_max_word() {
        // Créer deux mots avec des valeurs connues
        let trytes_a = [
            Tryte::Digit(0),  // N,N,N
            Tryte::Digit(13), // Z,Z,Z
            Tryte::Digit(23), // P,P,P
            Tryte::Digit(1),  // N,N,Z
            Tryte::Digit(4),  // N,P,N
            Tryte::Digit(10), // Z,N,P
            Tryte::Digit(5),  // N,P,Z
            Tryte::Digit(18), // P,Z,P
        ];

        let trytes_b = [
            Tryte::Digit(23), // P,P,P
            Tryte::Digit(0),  // N,N,N
            Tryte::Digit(13), // Z,Z,Z
            Tryte::Digit(22), // P,P,N
            Tryte::Digit(19), // P,P,Z
            Tryte::Digit(14), // Z,Z,P
            Tryte::Digit(9),  // Z,N,Z
            Tryte::Digit(3),  // N,Z,Z
        ];

        let word_a = create_word(trytes_a);
        let word_b = create_word(trytes_b);

        let max_result = trit_max_word(word_a, word_b);

        // Vérifier quelques résultats attendus
        // max(N,N,N, P,P,P) = P,P,P
        assert_eq!(max_result.tryte(0), word_b.tryte(0));
        // max(Z,Z,Z, N,N,N) = Z,Z,Z
        assert_eq!(max_result.tryte(1), word_a.tryte(1));
        // max(P,P,P, Z,Z,Z) = P,P,P
        assert_eq!(max_result.tryte(2), word_a.tryte(2));
    }

    #[test]
    fn test_ternary_full_adder() {
        // Test de toutes les combinaisons possibles (3^3 = 27 cas)
        let trits = [Trit::N, Trit::Z, Trit::P];

        // Cas particuliers à vérifier
        assert_eq!(
            ternary_full_adder(Trit::N, Trit::N, Trit::N),
            (Trit::Z, Trit::N)
        ); // -3 = 0 + (-1 * 3)
        assert_eq!(
            ternary_full_adder(Trit::P, Trit::P, Trit::P),
            (Trit::Z, Trit::P)
        ); // +3 = 0 + (1 * 3)
        assert_eq!(
            ternary_full_adder(Trit::Z, Trit::Z, Trit::Z),
            (Trit::Z, Trit::Z)
        ); // 0 = 0 + (0 * 3)

        // Test exhaustif de toutes les combinaisons
        for &a in &trits {
            for &b in &trits {
                for &cin in &trits {
                    let (sum, cout) = ternary_full_adder(a, b, cin);

                    // Vérifier que la somme est correcte
                    let total = a.value() + b.value() + cin.value();
                    let expected_sum = match total % 3 {
                        -2 => Trit::N,
                        -1 => Trit::N,
                        0 => Trit::Z,
                        1 => Trit::P,
                        2 => Trit::N,
                        _ => panic!("Unexpected remainder"),
                    };

                    let expected_cout = match total {
                        -3 | -2 => Trit::N,
                        -1 | 0 | 1 => Trit::Z,
                        2 | 3 => Trit::P,
                        _ => panic!("Unexpected total"),
                    };

                    assert_eq!(
                        sum, expected_sum,
                        "Failed for a={:?}, b={:?}, cin={:?}",
                        a, b, cin
                    );
                    assert_eq!(
                        cout, expected_cout,
                        "Failed for a={:?}, b={:?}, cin={:?}",
                        a, b, cin
                    );
                }
            }
        }
    }

    #[test]
    fn test_add_24_trits_basic() {
        // Test d'addition simple
        let a = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1 (Z,Z,P)
        let b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1 (Z,Z,P)

        let (result, cout, flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est 2 dans chaque tryte (Z,P,N)
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(15))); // 15 = (Z,P,N) = 2
        }

        // Pas de retenue de sortie
        assert_eq!(cout, Trit::Z);

        // Vérifier les flags
        assert_eq!(flags.zf, false); // Résultat non nul
        assert_eq!(flags.sf, false); // Résultat positif
        assert_eq!(flags.xf, false); // Pas d'état spécial
    }

    #[test]
    fn test_add_24_trits_with_carry() {
        // Test d'addition avec propagation de retenue
        let a = create_word([Tryte::Digit(23); 8]); // Tous les trytes sont 10 (P,P,P)
        let b = create_word([Tryte::Digit(23); 8]); // Tous les trytes sont 10 (P,P,P)

        let (result, cout, flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est 20 dans chaque tryte (P,P,N) avec retenue
        for i in 0..7 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(22))); // 22 = (P,P,N) = 20
        }
        // Le dernier tryte doit être différent à cause de la retenue
        assert_eq!(result.tryte(7), Some(&Tryte::Digit(6))); // 6 = (N,P,P) = 7

        // Retenue de sortie
        assert_eq!(cout, Trit::P);
    }

    #[test]
    fn test_add_24_trits_zero_result() {
        // Test d'addition donnant un résultat nul
        let a = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)
        let b = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)

        let (result, cout, flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est 0 dans chaque tryte
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(13))); // 13 = (Z,Z,Z) = 0
        }

        // Pas de retenue de sortie
        assert_eq!(cout, Trit::Z);

        // Vérifier les flags
        assert_eq!(flags.zf, true); // Résultat nul
        assert_eq!(flags.sf, false); // Résultat non négatif
        assert_eq!(flags.xf, false); // Pas d'état spécial
    }

    #[test]
    fn test_add_24_trits_negative_result() {
        // Test d'addition donnant un résultat négatif
        let a = create_word([Tryte::Digit(0); 8]); // Tous les trytes sont -13 (N,N,N)
        let b = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)

        let (result, cout, flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est -13 dans chaque tryte
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(0))); // 0 = (N,N,N) = -13
        }

        // Vérifier les flags
        assert_eq!(flags.sf, true); // Résultat négatif
    }

    #[test]
    fn test_add_24_trits_special_states() {
        // Test avec des états spéciaux
        let mut a = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0
        let mut b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1

        // Modifier quelques trytes pour inclure des états spéciaux
        if let Some(tryte) = a.tryte_mut(2) {
            *tryte = Tryte::NaN;
        }
        if let Some(tryte) = b.tryte_mut(4) {
            *tryte = Tryte::Null;
        }
        if let Some(tryte) = a.tryte_mut(6) {
            *tryte = Tryte::Undefined;
        }

        let (result, _, flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier que les états spéciaux sont correctement propagés
        assert_eq!(result.tryte(2), Some(&Tryte::NaN)); // NaN a priorité
        assert_eq!(result.tryte(4), Some(&Tryte::Null)); // Null a priorité sur Digit
        assert_eq!(result.tryte(6), Some(&Tryte::Undefined)); // Undefined a priorité sur Digit

        // Vérifier le flag XF
        assert_eq!(flags.xf, true); // États spéciaux présents

        // Test de priorité des états spéciaux: NaN > Null > Undefined > Digit
        let mut c = create_word([Tryte::Digit(13); 8]);
        let mut d = create_word([Tryte::Digit(14); 8]);

        // Mettre différents états spéciaux au même index
        if let Some(tryte) = c.tryte_mut(3) {
            *tryte = Tryte::NaN;
        }
        if let Some(tryte) = d.tryte_mut(3) {
            *tryte = Tryte::Null;
        }

        let (result2, _, _) = add_24_trits(c, d, Trit::Z);
        assert_eq!(result2.tryte(3), Some(&Tryte::NaN)); // NaN a priorité sur Null

        // Test Null vs Undefined
        let mut e = create_word([Tryte::Digit(13); 8]);
        let mut f = create_word([Tryte::Digit(14); 8]);

        if let Some(tryte) = e.tryte_mut(5) {
            *tryte = Tryte::Null;
        }
        if let Some(tryte) = f.tryte_mut(5) {
            *tryte = Tryte::Undefined;
        }

        let (result3, _, _) = add_24_trits(e, f, Trit::Z);
        assert_eq!(result3.tryte(5), Some(&Tryte::Null)); // Null a priorité sur Undefined
    }

    #[test]
    fn test_sub_24_trits_basic() {
        // Test de soustraction simple
        let a = create_word([Tryte::Digit(15); 8]); // Tous les trytes sont 2 (Z,P,N)
        let b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1 (Z,Z,P)

        let (result, bout, flags) = sub_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est 1 dans chaque tryte
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(14))); // 14 = (Z,Z,P) = 1
        }

        // Pas d'emprunt de sortie
        assert_eq!(bout, Trit::Z);

        // Vérifier les flags
        assert_eq!(flags.zf, false); // Résultat non nul
        assert_eq!(flags.sf, false); // Résultat positif
    }

    #[test]
    fn test_sub_24_trits_zero_result() {
        // Test de soustraction donnant un résultat nul
        let a = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1
        let b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1

        let (result, bout, flags) = sub_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est 0 dans chaque tryte
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(13))); // 13 = (Z,Z,Z) = 0
        }

        // Pas de retenue de sortie
        assert_eq!(bout, Trit::Z);

        // Vérifier les flags
        assert_eq!(flags.zf, true); // Résultat nul
    }

    #[test]
    fn test_sub_24_trits_negative_result() {
        // Test de soustraction donnant un résultat négatif
        let a = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0
        let b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1

        let (result, bout, flags) = sub_24_trits(a, b, Trit::Z);

        // Vérifier que le résultat est -1 dans chaque tryte
        for i in 0..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(12))); // 12 = (Z,Z,N) = -1
        }

        // Vérifier les flags
        assert_eq!(flags.sf, true); // Résultat négatif
    }

    #[test]
    fn test_compare_24_trits() {
        // Test de comparaison: a > b
        let a = create_word([Tryte::Digit(15); 8]); // Tous les trytes sont 2
        let b = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1

        let flags = compare_24_trits(a, b);
        assert_eq!(flags.zf, false); // a != b
        assert_eq!(flags.sf, false); // a > b

        // Test de comparaison: a < b
        let flags = compare_24_trits(b, a);
        assert_eq!(flags.zf, false); // b != a
        assert_eq!(flags.sf, true); // b < a

        // Test de comparaison: a == b
        let flags = compare_24_trits(a, a);
        assert_eq!(flags.zf, true); // a == a
        assert_eq!(flags.sf, false); // a >= a

        // Test avec des valeurs plus complexes
        let c = create_word([
            Tryte::Digit(0),
            Tryte::Digit(5),
            Tryte::Digit(10),
            Tryte::Digit(15),
            Tryte::Digit(20),
            Tryte::Digit(23),
            Tryte::Digit(13),
            Tryte::Digit(13),
        ]);
        let d = create_word([
            Tryte::Digit(0),
            Tryte::Digit(5),
            Tryte::Digit(10),
            Tryte::Digit(15),
            Tryte::Digit(20),
            Tryte::Digit(23),
            Tryte::Digit(13),
            Tryte::Digit(14),
        ]);

        // d > c (différence seulement dans le dernier tryte)
        let flags = compare_24_trits(c, d);
        assert_eq!(flags.zf, false); // c != d
        assert_eq!(flags.sf, true); // c < d

        // Test avec des états spéciaux
        let mut e = create_word([Tryte::Digit(13); 8]);
        let f = create_word([Tryte::Digit(13); 8]);

        if let Some(tryte) = e.tryte_mut(3) {
            *tryte = Tryte::NaN;
        }

        let flags = compare_24_trits(e, f);
        assert_eq!(flags.xf, true); // Présence d'états spéciaux
    }

    #[test]
    fn test_add_sub_inverse() {
        // Test que a + b - b = a
        let a = create_word([
            Tryte::Digit(16),
            Tryte::Digit(17),
            Tryte::Digit(18),
            Tryte::Digit(19),
            Tryte::Digit(20),
            Tryte::Digit(21),
            Tryte::Digit(22),
            Tryte::Digit(23),
        ]);
        let b = create_word([
            Tryte::Digit(5),
            Tryte::Digit(6),
            Tryte::Digit(7),
            Tryte::Digit(8),
            Tryte::Digit(9),
            Tryte::Digit(10),
            Tryte::Digit(11),
            Tryte::Digit(12),
        ]);

        // a + b
        let (sum, _, _) = add_24_trits(a, b, Trit::Z);

        // (a + b) - b
        let (result, _, _) = sub_24_trits(sum, b, Trit::Z);

        // Vérifier que result == a
        for i in 0..8 {
            assert_eq!(result.tryte(i), a.tryte(i));
        }
    }

    #[test]
    fn test_add_24_trits_overflow() {
        // Test d'overflow positif
        // Créer un mot avec tous les trytes à la valeur maximale (P,P,P)
        let a = create_word([Tryte::Digit(23); 8]);
        let b = create_word([Tryte::Digit(23); 8]);

        let (result, cout, _flags) = add_24_trits(a, b, Trit::Z);

        // Vérifier la retenue de sortie
        assert_eq!(cout, Trit::P);

        // Vérifier que le résultat a bien débordé
        // L'addition de deux valeurs maximales (P,P,P) + (P,P,P) donne (N,P,P) ou (P,N,N) avec une retenue
        // Vérifions simplement que le résultat n'est pas égal aux opérandes
        for i in 0..7 {
            assert_ne!(result.tryte(i), Some(&Tryte::Digit(23))); // Le résultat ne doit pas être (P,P,P)
        }

        // Test d'overflow négatif
        // Créer un mot avec tous les trytes à la valeur minimale (N,N,N)
        let c = create_word([Tryte::Digit(0); 8]);
        let d = create_word([Tryte::Digit(0); 8]);

        let (result2, cout2, _flags2) = add_24_trits(c, d, Trit::Z);

        // Vérifier la retenue de sortie
        assert_eq!(cout2, Trit::N);

        // Vérifier que le résultat a bien débordé
        // L'addition de deux valeurs minimales (N,N,N) + (N,N,N) donne un résultat avec une retenue négative
        // Vérifions simplement que le résultat n'est pas égal aux opérandes
        for i in 0..7 {
            assert_ne!(result2.tryte(i), Some(&Tryte::Digit(0))); // Le résultat ne doit pas être (N,N,N)
        }
    }

    #[test]
    fn test_sub_24_trits_overflow() {
        // Test d'overflow lors de la soustraction
        // Soustraire la valeur minimale de la valeur maximale
        let max_val = create_word([Tryte::Digit(23); 8]); // Tous P,P,P
        let min_val = create_word([Tryte::Digit(0); 8]); // Tous N,N,N

        let (_result, _bout, flags) = sub_24_trits(max_val, min_val, Trit::Z);

        // La différence devrait être très grande et positive
        assert_eq!(flags.sf, false); // Résultat positif

        // Soustraire la valeur maximale de la valeur minimale
        let (_result2, bout2, flags2) = sub_24_trits(min_val, max_val, Trit::Z);

        // La différence devrait être très grande et négative
        assert_eq!(flags2.sf, true); // Résultat négatif
        assert_eq!(bout2, Trit::P); // Emprunt de sortie
    }

    #[test]
    fn test_add_24_trits_edge_cases() {
        // Test avec des valeurs limites et des retenues

        // Test 1: Addition avec retenue d'entrée
        let a = create_word([Tryte::Digit(13); 8]); // Tous 0
        let b = create_word([Tryte::Digit(13); 8]); // Tous 0

        let (result, _cout, _) = add_24_trits(a, b, Trit::P); // Retenue d'entrée = 1

        // Le résultat devrait être 1 dans le premier tryte, 0 ailleurs
        assert_eq!(result.tryte(0), Some(&Tryte::Digit(14))); // 14 = (Z,Z,P) = 1
        for i in 1..8 {
            assert_eq!(result.tryte(i), Some(&Tryte::Digit(13))); // 13 = (Z,Z,Z) = 0
        }

        // Test 2: Addition avec propagation de retenue sur plusieurs trytes
        let mut c = create_word([Tryte::Digit(13); 8]); // Tous 0

        // Mettre le premier tryte à la valeur maximale
        if let Some(tryte) = c.tryte_mut(0) {
            *tryte = Tryte::Digit(23); // 23 = (P,P,P) = 13
        }

        let d = create_word([Tryte::Digit(14); 8]); // Tous 1

        let (result2, _, _) = add_24_trits(c, d, Trit::Z);

        // Le premier tryte devrait être 14 (13+1), avec une retenue vers le deuxième tryte
        assert_eq!(result2.tryte(0), Some(&Tryte::Digit(0))); // 0 = (N,N,N) = -13 (overflow)
        assert_eq!(result2.tryte(1), Some(&Tryte::Digit(15))); // 15 = (Z,P,N) = 2 (1 + retenue)
    }
}
