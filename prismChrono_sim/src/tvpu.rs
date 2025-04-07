// src/tvpu.rs
// Implémentation de l'unité de traitement vectoriel ternaire (TVPU) optimisée

use crate::core::{Trit, Word};

/// Structure représentant un registre vectoriel ternaire
/// Contient 8 mots de 24 trits (8 trytes) chacun
pub struct TernaryVector {
    /// Les 8 mots du vecteur
    words: [Word; 8],
    /// Cache pour les opérations fréquentes
    cache: Option<VectorCache>,
}

/// Structure de cache pour les opérations vectorielles fréquentes
pub struct VectorCache {
    /// Somme des éléments (pour TVSUM)
    sum: Option<Word>,
    /// Minimum des éléments (pour TVMIN)
    min: Option<Word>,
    /// Maximum des éléments (pour TVMAX)
    max: Option<Word>,
    /// Moyenne des éléments (pour TVAVG)
    avg: Option<Word>,
}

impl TernaryVector {
    /// Crée un nouveau vecteur ternaire initialisé à zéro
    pub fn new() -> Self {
        let mut words = [Word::default(); 8];
        for word in &mut words {
            *word = Word::default_zero();
        }
        TernaryVector { 
            words,
            cache: Some(VectorCache {
                sum: Some(Word::default_zero()),
                min: Some(Word::default_zero()),
                max: Some(Word::default_zero()),
                avg: Some(Word::default_zero()),
            }),
        }
    }

    /// Crée un nouveau vecteur ternaire initialisé à une valeur indéfinie
    pub fn default_undefined() -> Self {
        let mut words = [Word::default(); 8];
        for word in &mut words {
            *word = Word::default_undefined();
        }
        TernaryVector { 
            words,
            cache: None,
        }
    }

    /// Accède à un mot du vecteur
    pub fn word(&self, index: usize) -> Option<&Word> {
        if index < 8 {
            Some(&self.words[index])
        } else {
            None
        }
    }

    /// Accède à un mot mutable du vecteur
    pub fn word_mut(&mut self, index: usize) -> Option<&mut Word> {
        // Invalider le cache si on modifie le vecteur
        self.cache = None;
        
        if index < 8 {
            Some(&mut self.words[index])
        } else {
            None
        }
    }
    
    /// Invalide le cache
    pub fn invalidate_cache(&mut self) {
        self.cache = None;
    }
    
    /// Précharge le cache pour les opérations fréquentes
    pub fn precompute_cache(&mut self) {
        let mut sum = Word::default_zero();
        let mut min = self.words[0];
        let mut max = self.words[0];
        
        for i in 0..8 {
            // Calculer la somme
            sum = crate::alu::add_words(sum, self.words[i], false).0;
            
            // Calculer le minimum
            min = crate::alu::trit_min_word(min, self.words[i]);
            
            // Calculer le maximum
            max = crate::alu::trit_max_word(max, self.words[i]);
        }
        
        // Calculer la moyenne (somme / 8)
        let divisor = Word::from_i32(8);
        let avg = crate::alu::div_words(sum, divisor).0;
        
        // Stocker dans le cache
        self.cache = Some(VectorCache {
            sum: Some(sum),
            min: Some(min),
            max: Some(max),
            avg: Some(avg),
        });
    }
}

/// Addition vectorielle ternaire (TVADD)
/// Additionne deux vecteurs ternaires élément par élément
pub fn tvadd(a: &TernaryVector, b: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_result)) = 
            (a.word(i), b.word(i), result.word_mut(i)) {
            // Utiliser l'addition standard de mots ternaires pour chaque élément
            *word_result = crate::alu::add_words(*word_a, *word_b, false).0;
        }
    }
    
    result
}

/// Soustraction vectorielle ternaire (TVSUB)
/// Soustrait deux vecteurs ternaires élément par élément
pub fn tvsub(a: &TernaryVector, b: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_result)) = 
            (a.word(i), b.word(i), result.word_mut(i)) {
            // Utiliser la soustraction standard de mots ternaires pour chaque élément
            *word_result = crate::alu::sub_words(*word_a, *word_b, false).0;
        }
    }
    
    result
}

/// Multiplication vectorielle ternaire (TVMUL)
/// Multiplie deux vecteurs ternaires élément par élément
pub fn tvmul(a: &TernaryVector, b: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_result)) = 
            (a.word(i), b.word(i), result.word_mut(i)) {
            // Utiliser la multiplication standard de mots ternaires pour chaque élément
            *word_result = crate::alu::mul_words(*word_a, *word_b).0;
        }
    }
    
    result
}

/// Produit scalaire ternaire (TVDOT)
/// Calcule le produit scalaire de deux vecteurs ternaires
pub fn tvdot(a: &TernaryVector, b: &TernaryVector) -> Word {
    let mut result = Word::default_zero();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b)) = (a.word(i), b.word(i)) {
            // Multiplier les éléments correspondants
            let product = crate::alu::mul_words(*word_a, *word_b).0;
            // Ajouter au résultat accumulé
            result = crate::alu::add_words(result, product, false).0;
        }
    }
    
    result
}

/// Multiplication-accumulation vectorielle (TVMAC)
/// Calcule a * b + c élément par élément
pub fn tvmac(a: &TernaryVector, b: &TernaryVector, c: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_c), Some(word_result)) = 
            (a.word(i), b.word(i), c.word(i), result.word_mut(i)) {
            // Multiplier a et b
            let product = crate::alu::mul_words(*word_a, *word_b).0;
            // Ajouter c
            *word_result = crate::alu::add_words(product, *word_c, false).0;
        }
    }
    
    result
}

/// Somme des éléments d'un vecteur (TVSUM)
/// Calcule la somme de tous les éléments d'un vecteur ternaire
/// Utilise le cache si disponible pour une performance optimale
pub fn tvsum(a: &TernaryVector) -> Word {
    // Vérifier si la somme est déjà dans le cache
    if let Some(cache) = &a.cache {
        if let Some(sum) = cache.sum {
            return sum;
        }
    }
    
    // Sinon, calculer la somme
    let mut result = Word::default_zero();
    
    for i in 0..8 {
        if let Some(word) = a.word(i) {
            result = crate::alu::add_words(result, *word, false).0;
        }
    }
    
    result
}

/// Minimum d'un vecteur (TVMIN)
/// Trouve la valeur minimale dans un vecteur ternaire
/// Utilise le cache si disponible pour une performance optimale
pub fn tvmin(a: &TernaryVector) -> Word {
    // Vérifier si le minimum est déjà dans le cache
    if let Some(cache) = &a.cache {
        if let Some(min) = cache.min {
            return min;
        }
    }
    
    // Sinon, calculer le minimum
    let mut result = Word::default_undefined();
    let mut initialized = false;
    
    for i in 0..8 {
        if let Some(word) = a.word(i) {
            if !initialized {
                result = *word;
                initialized = true;
            } else {
                // Utiliser l'opération de minimum trit-à-trit pour chaque mot
                result = crate::alu::trit_min_word(result, *word);
            }
        }
    }
    
    result
}

/// Maximum d'un vecteur (TVMAX)
/// Trouve la valeur maximale dans un vecteur ternaire
/// Utilise le cache si disponible pour une performance optimale
pub fn tvmax(a: &TernaryVector) -> Word {
    // Vérifier si le maximum est déjà dans le cache
    if let Some(cache) = &a.cache {
        if let Some(max) = cache.max {
            return max;
        }
    }
    
    // Sinon, calculer le maximum
    let mut result = Word::default_undefined();
    let mut initialized = false;
    
    for i in 0..8 {
        if let Some(word) = a.word(i) {
            if !initialized {
                result = *word;
                initialized = true;
            } else {
                // Utiliser l'opération de maximum trit-à-trit pour chaque mot
                result = crate::alu::trit_max_word(result, *word);
            }
        }
    }
    
    result
}

/// Moyenne d'un vecteur (TVAVG)
/// Calcule la moyenne des éléments d'un vecteur ternaire
/// Utilise le cache si disponible pour une performance optimale
pub fn tvavg(a: &TernaryVector) -> Word {
    // Vérifier si la moyenne est déjà dans le cache
    if let Some(cache) = &a.cache {
        if let Some(avg) = cache.avg {
            return avg;
        }
    }
    
    // Sinon, calculer la moyenne
    // Calculer la somme
    let sum = tvsum(a);
    
    // Diviser par 8 (nombre d'éléments)
    let divisor = Word::from_i32(8);
    crate::alu::div_words(sum, divisor).0
}

/// Opérations vectorielles optimisées pour les calculs en base 60 (système sexagésimal)
/// Ces fonctions sont particulièrement utiles pour les applications temporelles et angulaires

/// Conversion d'un vecteur de valeurs décimales en base 60
/// Particulièrement efficace pour les calculs temporel (heures, minutes, secondes)
pub fn tvbase60_encode(a: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_result)) = (a.word(i), result.word_mut(i)) {
            // Convertir la valeur décimale en base 60
            let decimal_value = word_a.to_i32();
            
            // Décomposer en unités, minutes, secondes (ou degrés, minutes, secondes)
            let units = decimal_value / 3600;
            let minutes = (decimal_value % 3600) / 60;
            let seconds = decimal_value % 60;
            
            // Encoder efficacement en utilisant les propriétés ternaires
            // Les trits 0-2 pour les secondes
            // Les trits 3-5 pour les minutes
            // Les trits 6-8 pour les unités
            
            // Créer un nouveau mot pour stocker le résultat
            let mut new_word = Word::default_zero();
            
            // Encoder les secondes dans les trits 0-2
            encode_base60_component(&mut new_word, seconds, 0);
            
            // Encoder les minutes dans les trits 3-5
            encode_base60_component(&mut new_word, minutes, 3);
            
            // Encoder les unités dans les trits 6-8
            encode_base60_component(&mut new_word, units, 6);
            
            *word_result = new_word;
        }
    }
    
    result
}

/// Conversion d'un vecteur en base 60 vers des valeurs décimales
/// Particulièrement efficace pour les calculs temporel (heures, minutes, secondes)
pub fn tvbase60_decode(a: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_result)) = (a.word(i), result.word_mut(i)) {
            // Décoder les composantes en base 60
            let seconds = decode_base60_component(word_a, 0);
            let minutes = decode_base60_component(word_a, 3);
            let units = decode_base60_component(word_a, 6);
            
            // Convertir en valeur décimale
            let decimal_value = units * 3600 + minutes * 60 + seconds;
            
            // Stocker le résultat
            *word_result = Word::from_i32(decimal_value);
        }
    }
    
    result
}

/// Addition vectorielle en base 60
/// Optimisée pour les calculs temporel et angulaire
pub fn tvbase60_add(a: &TernaryVector, b: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    let mut carry_seconds = 0;
    let mut carry_minutes = 0;
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_result)) = 
            (a.word(i), b.word(i), result.word_mut(i)) {
            // Décoder les composantes en base 60
            let seconds_a = decode_base60_component(word_a, 0);
            let minutes_a = decode_base60_component(word_a, 3);
            let units_a = decode_base60_component(word_a, 6);
            
            let seconds_b = decode_base60_component(word_b, 0);
            let minutes_b = decode_base60_component(word_b, 3);
            let units_b = decode_base60_component(word_b, 6);
            
            // Additionner avec gestion des retenues
            let mut seconds_sum = seconds_a + seconds_b + carry_seconds;
            carry_seconds = 0;
            if seconds_sum >= 60 {
                seconds_sum -= 60;
                carry_seconds = 1;
            }
            
            let mut minutes_sum = minutes_a + minutes_b + carry_minutes + carry_seconds;
            carry_minutes = 0;
            carry_seconds = 0;
            if minutes_sum >= 60 {
                minutes_sum -= 60;
                carry_minutes = 1;
            }
            
            let units_sum = units_a + units_b + carry_minutes;
            carry_minutes = 0;
            
            // Créer un nouveau mot pour stocker le résultat
            let mut new_word = Word::default_zero();
            
            // Encoder les résultats
            encode_base60_component(&mut new_word, seconds_sum, 0);
            encode_base60_component(&mut new_word, minutes_sum, 3);
            encode_base60_component(&mut new_word, units_sum, 6);
            
            *word_result = new_word;
        }
    }
    
    result
}

/// Soustraction vectorielle en base 60
/// Optimisée pour les calculs temporel et angulaire
pub fn tvbase60_sub(a: &TernaryVector, b: &TernaryVector) -> TernaryVector {
    let mut result = TernaryVector::default_undefined();
    let mut borrow_seconds = 0;
    let mut borrow_minutes = 0;
    
    for i in 0..8 {
        if let (Some(word_a), Some(word_b), Some(word_result)) = 
            (a.word(i), b.word(i), result.word_mut(i)) {
            // Décoder les composantes en base 60
            let seconds_a = decode_base60_component(word_a, 0);
            let minutes_a = decode_base60_component(word_a, 3);
            let units_a = decode_base60_component(word_a, 6);
            
            let seconds_b = decode_base60_component(word_b, 0);
            let minutes_b = decode_base60_component(word_b, 3);
            let units_b = decode_base60_component(word_b, 6);
            
            // Soustraire avec gestion des emprunts
            let mut seconds_diff = seconds_a - seconds_b - borrow_seconds;
            borrow_seconds = 0;
            if seconds_diff < 0 {
                seconds_diff += 60;
                borrow_seconds = 1;
            }
            
            let mut minutes_diff = minutes_a - minutes_b - borrow_minutes - borrow_seconds;
            borrow_minutes = 0;
            borrow_seconds = 0;
            if minutes_diff < 0 {
                minutes_diff += 60;
                borrow_minutes = 1;
            }
            
            let units_diff = units_a - units_b - borrow_minutes;
            borrow_minutes = 0;
            
            // Créer un nouveau mot pour stocker le résultat
            let mut new_word = Word::default_zero();
            
            // Encoder les résultats
            encode_base60_component(&mut new_word, seconds_diff, 0);
            encode_base60_component(&mut new_word, minutes_diff, 3);
            encode_base60_component(&mut new_word, units_diff, 6);
            
            *word_result = new_word;
        }
    }
    
    result
}

/// Fonction utilitaire pour encoder une composante en base 60 dans un mot
fn encode_base60_component(word: &mut Word, value: i32, start_trit: usize) {
    // Utiliser les propriétés ternaires pour encoder efficacement
    // Nous pouvons représenter jusqu'à 3^3 = 27 valeurs avec 3 trits
    // Pour représenter 60 valeurs, nous utilisons une combinaison optimisée
    
    // Première approche: encoder directement en base 3
    let trit0 = value % 3;
    let trit1 = (value / 3) % 3;
    let trit2 = (value / 9) % 3;
    
    // Convertir en Trit (-1, 0, 1)
    let trit0_val = match trit0 {
        0 => Trit::N,
        1 => Trit::Z,
        2 => Trit::P,
        _ => Trit::Z, // Ne devrait jamais arriver
    };
    
    let trit1_val = match trit1 {
        0 => Trit::N,
        1 => Trit::Z,
        2 => Trit::P,
        _ => Trit::Z, // Ne devrait jamais arriver
    };
    
    let trit2_val = match trit2 {
        0 => Trit::N,
        1 => Trit::Z,
        2 => Trit::P,
        _ => Trit::Z, // Ne devrait jamais arriver
    };
    
    // Définir les trits dans le mot en utilisant la méthode set_trit de Word
    // Premier trit
    word.set_trit(start_trit, trit0_val);
    
    // Deuxième trit
    if start_trit + 1 < 24 { // Vérifier que nous sommes dans les limites
        word.set_trit(start_trit + 1, trit1_val);
    }
    
    // Troisième trit
    if start_trit + 2 < 24 { // Vérifier que nous sommes dans les limites
        word.set_trit(start_trit + 2, trit2_val);
    }
}

/// Fonction utilitaire pour décoder une composante en base 60 depuis un mot
fn decode_base60_component(word: &Word, start_trit: usize) -> i32 {
    // Extraire les trits correspondant à la valeur encodée en base 3
    let mut trit0;
    let mut trit1 = 0;
    let mut trit2 = 0;
    
    // Extraire le premier trit en utilisant la méthode get_trit de Word
    let trit0_val = word.get_trit(start_trit);
    trit0 = match trit0_val {
        Trit::N => 0,
        Trit::Z => 1,
        Trit::P => 2,
    };
    
    // Extraire le deuxième trit
    if start_trit + 1 < 24 { // Vérifier que nous sommes dans les limites
        let trit1_val = word.get_trit(start_trit + 1);
        trit1 = match trit1_val {
            Trit::N => 0,
            Trit::Z => 1,
            Trit::P => 2,
        };
    }
    
    // Extraire le troisième trit
    if start_trit + 2 < 24 { // Vérifier que nous sommes dans les limites
        let trit2_val = word.get_trit(start_trit + 2);
        trit2 = match trit2_val {
            Trit::N => 0,
            Trit::Z => 1,
            Trit::P => 2,
        };
    }
    
    // Reconstruire la valeur en base 3
    trit0 + trit1 * 3 + trit2 * 9
}