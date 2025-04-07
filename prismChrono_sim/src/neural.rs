// src/neural.rs
// Implémentation des instructions pour réseaux de neurones ternaires

use crate::core::{Trit, Tryte, Word};
use crate::tvpu::TernaryVector;

/// Structure représentant une matrice ternaire
pub struct TernaryMatrix {
    /// Nombre de lignes
    rows: usize,
    /// Nombre de colonnes
    cols: usize,
    /// Données de la matrice (stockées par lignes)
    data: Vec<TernaryVector>,
}

impl TernaryMatrix {
    /// Crée une nouvelle matrice ternaire
    pub fn new(rows: usize, cols: usize) -> Self {
        let mut data = Vec::with_capacity(rows);
        for _ in 0..rows {
            data.push(TernaryVector::new());
        }
        
        TernaryMatrix {
            rows,
            cols,
            data,
        }
    }
    
    /// Retourne le nombre de lignes de la matrice
    pub fn rows(&self) -> usize {
        self.rows
    }
    
    /// Retourne le nombre de colonnes de la matrice
    pub fn cols(&self) -> usize {
        self.cols
    }
    
    /// Accède à une ligne de la matrice
    pub fn row(&self, row: usize) -> Option<&TernaryVector> {
        if row < self.rows {
            Some(&self.data[row])
        } else {
            None
        }
    }
    
    /// Accède à une ligne mutable de la matrice
    pub fn row_mut(&mut self, row: usize) -> Option<&mut TernaryVector> {
        if row < self.rows {
            Some(&mut self.data[row])
        } else {
            None
        }
    }
    
    /// Accède à un élément de la matrice
    pub fn get(&self, row: usize, col: usize) -> Option<Word> {
        if row < self.rows && col < self.cols {
            if let Some(row_vec) = self.row(row) {
                if let Some(word) = row_vec.word(col) {
                    return Some(*word);
                }
            }
        }
        
        None
    }
    
    /// Modifie un élément de la matrice
    pub fn set(&mut self, row: usize, col: usize, value: Word) -> bool {
        if row < self.rows && col < self.cols {
            if let Some(row_vec) = self.row_mut(row) {
                if let Some(word) = row_vec.word_mut(col) {
                    *word = value;
                    return true;
                }
            }
        }
        
        false
    }
}

/// Fonction d'activation ternaire ReLU
/// Remplace les valeurs négatives par zéro
pub fn ternary_relu(input: Word) -> Word {
    let mut result = Word::zero();
    
    for i in 0..8 {
        if let (Some(tryte_in), Some(tryte_out)) = (input.tryte(i), result.tryte_mut(i)) {
            // Convertir le tryte en trits
            let trits_in = tryte_in.to_trits();
            let mut relu_trits = [Trit::Z; 3];
            
            // Appliquer ReLU à chaque trit
            for j in 0..3 {
                relu_trits[j] = match trits_in[j] {
                    Trit::N => Trit::Z, // Remplacer les valeurs négatives par zéro
                    Trit::Z => Trit::Z,
                    Trit::P => Trit::P,
                };
            }
            
            *tryte_out = Tryte::from_trits(relu_trits);
        }
    }
    
    result
}

/// Fonction d'activation ternaire Sigmoid
/// Approximation de la fonction sigmoid pour les valeurs ternaires
pub fn ternary_sigmoid(input: Word) -> Word {
    // Convertir l'entrée en valeur entière en utilisant la méthode to_i32 existante
    let input_value = input.to_i32();
    
    // Appliquer une approximation de sigmoid
    // Sigmoid(x) ≈ 0 pour x << 0, 0.5 pour x ≈ 0, 1 pour x >> 0
    let sigmoid_value = if input_value < -10 {
        -1 // Représente 0 en ternaire normalisé
    } else if input_value > 10 {
        1 // Représente 1 en ternaire normalisé
    } else {
        // Approximation linéaire simple pour les valeurs intermédiaires
        // Mapper [-10, 10] à [-1, 1]
        (input_value as f32 / 10.0).clamp(-1.0, 1.0) as i32
    };
    
    // Convertir en mot ternaire
    Word::from_int(sigmoid_value)
}

/// Fonction d'activation ternaire Tanh
/// Approximation de la fonction tanh pour les valeurs ternaires
pub fn ternary_tanh(input: Word) -> Word {
    // Convertir l'entrée en valeur entière en utilisant la méthode to_i32 existante
    let input_value = input.to_i32();
    
    // Appliquer une approximation de tanh
    // tanh(x) ≈ -1 pour x << 0, 0 pour x ≈ 0, 1 pour x >> 0
    let tanh_value = if input_value < -10 {
        -1
    } else if input_value > 10 {
        1
    } else {
        // Approximation linéaire simple pour les valeurs intermédiaires
        // Mapper [-10, 10] à [-1, 1]
        (input_value as f32 / 10.0).clamp(-1.0, 1.0) as i32
    };
    
    // Convertir en mot ternaire
    Word::from_int(tanh_value)
}

/// Calcul d'un neurone ternaire (TNEURON)
/// Calcule la sortie d'un neurone: activation(somme(entrées * poids) + biais)
pub fn tneuron(inputs: &TernaryVector, weights: &TernaryVector, bias: Word, activation: fn(Word) -> Word) -> Word {
    // Calculer le produit scalaire des entrées et des poids
    let dot_product = crate::tvpu::tvdot(inputs, weights);
    
    // Ajouter le biais
    let sum = crate::alu::add_words(dot_product, bias, false).0;
    
    // Appliquer la fonction d'activation
    activation(sum)
}

/// Opération de convolution 2D ternaire (TCONV2D)
/// Applique un filtre de convolution à une matrice d'entrée
pub fn tconv2d(input: &TernaryMatrix, filter: &TernaryMatrix, stride: usize) -> TernaryMatrix {
    // Dimensions du filtre
    let filter_height = filter.rows;
    let filter_width = filter.cols;
    
    // Dimensions de l'entrée
    let input_height = input.rows;
    let input_width = input.cols;
    
    // Dimensions de la sortie
    let output_height = (input_height - filter_height) / stride + 1;
    let output_width = (input_width - filter_width) / stride + 1;
    
    // Créer la matrice de sortie
    let mut output = TernaryMatrix::new(output_height, output_width);
    
    // Appliquer la convolution
    for y in 0..output_height {
        for x in 0..output_width {
            // Position dans l'entrée
            let input_y = y * stride;
            let input_x = x * stride;
            
            // Calculer la convolution à cette position
            let mut sum = Word::zero();
            
            for fy in 0..filter_height {
                for fx in 0..filter_width {
                    if let (Some(input_val), Some(filter_val)) = (
                        input.get(input_y + fy, input_x + fx),
                        filter.get(fy, fx)
                    ) {
                        // Multiplier et accumuler
                        let product = crate::alu::mul_words(input_val, filter_val).0;
                        sum = crate::alu::add_words(sum, product, false).0;
                    }
                }
            }
            
            // Stocker le résultat
            output.set(y, x, sum);
        }
    }
    
    output
}

/// Opération de pooling max ternaire
/// Réduit la taille d'une matrice en prenant la valeur maximale dans chaque fenêtre
pub fn tmax_pooling(input: &TernaryMatrix, pool_size: usize, stride: usize) -> TernaryMatrix {
    // Dimensions de l'entrée
    let input_height = input.rows;
    let input_width = input.cols;
    
    // Dimensions de la sortie
    let output_height = (input_height - pool_size) / stride + 1;
    let output_width = (input_width - pool_size) / stride + 1;
    
    // Créer la matrice de sortie
    let mut output = TernaryMatrix::new(output_height, output_width);
    
    // Appliquer le pooling
    for y in 0..output_height {
        for x in 0..output_width {
            // Position dans l'entrée
            let input_y = y * stride;
            let input_x = x * stride;
            
            // Trouver le maximum dans la fenêtre
            let mut max_val = Word::zero();
            let mut initialized = false;
            
            for py in 0..pool_size {
                for px in 0..pool_size {
                    if let Some(val) = input.get(input_y + py, input_x + px) {
                        if !initialized {
                            max_val = val;
                            initialized = true;
                        } else {
                            // Comparer avec le maximum actuel
                            max_val = crate::alu::trit_max_word(max_val, val);
                        }
                    }
                }
            }
            
            // Stocker le résultat
            output.set(y, x, max_val);
        }
    }
    
    output
}

/// Mécanisme d'attention ternaire (TATTN)
/// Implémente un mécanisme d'attention simplifié pour les modèles de transformers
pub fn tattn(query: &TernaryMatrix, key: &TernaryMatrix, value: &TernaryMatrix) -> TernaryMatrix {
    // Dimensions
    let seq_len = query.rows;
    let d_k = query.cols;
    
    // Calculer les scores d'attention (Q * K^T)
    let mut attention_scores = TernaryMatrix::new(seq_len, seq_len);
    
    for i in 0..seq_len {
        for j in 0..seq_len {
            if let (Some(query_row), Some(key_row)) = (query.row(i), key.row(j)) {
                // Calculer le produit scalaire
                let score = crate::tvpu::tvdot(query_row, key_row);
                
                // Normaliser par sqrt(d_k)
                let scale_factor = Word::from_int((d_k as f32).sqrt() as i32);
                let scaled_score = crate::alu::div_words(score, scale_factor).0;
                
                // Stocker le score
                attention_scores.set(i, j, scaled_score);
            }
        }
    }
    
    // Appliquer softmax (simplifié pour la logique ternaire)
    let mut attention_weights = TernaryMatrix::new(seq_len, seq_len);
    
    for i in 0..seq_len {
        // Trouver le maximum pour la normalisation
        let mut max_val = Word::zero();
        let mut initialized = false;
        
        for j in 0..seq_len {
            if let Some(val) = attention_scores.get(i, j) {
                if !initialized {
                    max_val = val;
                    initialized = true;
                } else {
                    max_val = crate::alu::trit_max_word(max_val, val);
                }
            }
        }
        
        // Calculer exp(score - max) pour chaque score
        let mut sum = Word::zero();
        let mut exp_scores = Vec::with_capacity(seq_len);
        
        for j in 0..seq_len {
            if let Some(val) = attention_scores.get(i, j) {
                // Soustraire le maximum pour la stabilité numérique
                let shifted = crate::alu::sub_words(val, max_val, false).0;
                
                // Approximation de exp pour les valeurs ternaires
                let exp_val = ternary_exp(shifted);
                exp_scores.push(exp_val);
                
                // Accumuler la somme pour la normalisation
                sum = crate::alu::add_words(sum, exp_val, false).0;
            } else {
                exp_scores.push(Word::zero());
            }
        }
        
        // Normaliser par la somme
        for j in 0..seq_len {
            if sum != Word::zero() {
                let weight = crate::alu::div_words(exp_scores[j], sum).0;
                attention_weights.set(i, j, weight);
            } else {
                // Éviter la division par zéro
                // Utiliser une valeur uniforme pour tous les poids
                // On utilise directement une valeur de 1 pour chaque poids
                // Cette approche est plus stable que de calculer 1/seq_len qui pourrait donner 0
                let uniform_weight = Word::from_int(1);
                attention_weights.set(i, j, uniform_weight);
            }
        }
    }
    
    // Calculer la sortie (attention_weights * V)
    let mut output = TernaryMatrix::new(seq_len, value.cols);
    
    for i in 0..seq_len {
        for j in 0..value.cols {
            let mut sum = Word::zero();
            
            for k in 0..seq_len {
                if let (Some(weight), Some(val)) = (attention_weights.get(i, k), value.get(k, j)) {
                    let product = crate::alu::mul_words(weight, val).0;
                    sum = crate::alu::add_words(sum, product, false).0;
                }
            }
            
            output.set(i, j, sum);
        }
    }
    
    output
}

/// Approximation de la fonction exponentielle pour les valeurs ternaires
fn ternary_exp(input: Word) -> Word {
    // Convertir l'entrée en valeur entière en utilisant la méthode to_i32 existante
    let input_value = input.to_i32();
    
    // Approximation simple de exp(x)
    // exp(x) ≈ 1 pour x ≈ 0, grandit rapidement pour x > 0, tend vers 0 pour x < 0
    let exp_value = if input_value < -10 {
        0 // Très proche de zéro
    } else if input_value > 10 {
        1000 // Très grand
    } else if input_value >= 0 {
        // Approximation pour x ≥ 0: 1 + x + x²/2
        let x = input_value as f32;
        (1.0 + x + x*x/2.0) as i32
    } else {
        // Approximation pour x < 0: 1/(1 - x + x²/2)
        let x = -input_value as f32;
        (1.0 / (1.0 + x + x*x/2.0) * 100.0) as i32 // Mise à l'échelle pour éviter les valeurs trop petites
    };
    
    // Convertir en mot ternaire
    Word::from_int(exp_value)
}

/// Quantification ternaire d'une valeur
/// Convertit une valeur en représentation ternaire quantifiée
pub fn ternary_quantize(value: f32) -> Trit {
    if value < -0.3 {
        Trit::N
    } else if value > 0.3 {
        Trit::P
    } else {
        Trit::Z
    }
}

/// Déquantification ternaire
/// Convertit une valeur ternaire quantifiée en valeur flottante
pub fn ternary_dequantize(trit: Trit) -> f32 {
    match trit {
        Trit::N => -1.0,
        Trit::Z => 0.0,
        Trit::P => 1.0,
    }
}

/// Quantification d'un vecteur en représentation ternaire
pub fn quantize_vector(values: &[f32]) -> TernaryVector {
    let mut result = TernaryVector::new();
    
    // Traiter les valeurs par groupes de 24 (taille d'un mot)
    for chunk_idx in 0..(values.len() + 23) / 24 {
        let mut word = Word::zero();
        
        for i in 0..24 {
            let idx = chunk_idx * 24 + i;
            if idx < values.len() {
                let trit = ternary_quantize(values[idx]);
                
                // Calculer la position dans le mot
                let tryte_idx = i / 3;
                let trit_idx = i % 3;
                
                if let Some(tryte) = word.tryte_mut(tryte_idx) {
                    let mut trits = tryte.to_trits();
                    trits[trit_idx] = trit;
                    *tryte = Tryte::from_trits(trits);
                }
            }
        }
        
        // Ajouter le mot au vecteur
        if let Some(vec_word) = result.word_mut(chunk_idx) {
            *vec_word = word;
        }
    }
    
    result
}

/// Déquantification d'un vecteur ternaire en valeurs flottantes
pub fn dequantize_vector(vector: &TernaryVector) -> Vec<f32> {
    let mut result = Vec::new();
    
    // Parcourir chaque mot du vecteur
    for word_idx in 0..8 {
        if let Some(word) = vector.word(word_idx) {
            // Parcourir chaque tryte du mot
            for tryte_idx in 0..8 {
                if let Some(tryte) = word.tryte(tryte_idx) {
                    let trits = tryte.to_trits();
                    
                    // Déquantifier chaque trit
                    for &trit in &trits {
                        result.push(ternary_dequantize(trit));
                    }
                }
            }
        }
    }
    
    result
}