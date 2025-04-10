// src/branch_predictor.rs
// Implémentation du prédicteur de branchement ternaire avancé hybride à trois niveaux

use crate::core::{Trit, Tryte, Word};
use std::collections::HashMap;
use rand; // Pour la fonction random utilisée dans update_choice_table

/// États possibles du prédicteur de branchement ternaire
/// Utilise un système à états multiples optimisé pour la logique ternaire
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BranchPredictionState {
    /// Fortement négatif (très haute confiance en branche négative)
    StronglyNegative,
    /// Modérément négatif (haute confiance en branche négative)
    ModeratelyNegative,
    /// Faiblement négatif (confiance moyenne en branche négative)
    WeaklyNegative,
    /// Légèrement négatif (faible confiance en branche négative)
    NeutralNegative,
    /// État neutre (pas de prédiction forte)
    Neutral,
    /// Légèrement positif (faible confiance en branche positive)
    NeutralPositive,
    /// Faiblement positif (confiance moyenne en branche positive)
    WeaklyPositive,
    /// Modérément positif (haute confiance en branche positive)
    ModeratelyPositive,
    /// Fortement positif (très haute confiance en branche positive)
    StronglyPositive,
    /// État spéculatif (exploration multi-chemins)
    Maybe,
    /// État de fusion de branchements
    Merged
}

/// Résultat d'une prédiction de branchement
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BranchPrediction {
    /// Prédiction: branche négative
    Negative,
    /// Prédiction: branche neutre
    Neutral,
    /// Prédiction: branche positive
    Positive,
    /// Prédiction: incertain, explorer plusieurs chemins
    Speculative,
}

/// Structure d'une entrée dans la table de prédiction de branchement
pub struct BranchPredictorEntry {
    /// Adresse de l'instruction de branchement
    pub address: u32,
    /// État actuel du prédicteur pour cette instruction
    pub state: BranchPredictionState,
    /// Adresses cibles pour chaque condition
    pub target_negative: u32,
    pub target_zero: u32,
    pub target_positive: u32,
    /// Niveau de confiance de la prédiction (0-255)
    pub confidence: u8,
    /// Compteur d'utilisation pour la politique de remplacement
    pub usage_counter: u32,
    /// Détection de motifs de boucle
    pub loop_pattern: Option<LoopPattern>,
    /// Compteur à saturation ternaire (-13 à +13)
    pub saturation_counter: i8,
    /// Poids d'apprentissage (0.0 à 1.0)
    pub learning_weight: f32,
    /// Historique des dernières prédictions
    pub prediction_history: Vec<Trit>,
    /// Indicateur de fusion de branchements
    pub is_merged: bool,
    /// Adresses des branchements fusionnés
    pub merged_branches: Option<Vec<u32>>,
}

#[derive(Debug, Clone)]
pub struct LoopPattern {
    /// Nombre d'itérations du motif
    pub iterations: u32,
    /// Séquence de branches dans le motif
    pub sequence: Vec<Trit>,
    /// Position actuelle dans la séquence
    pub current_position: usize,
    /// Confiance dans la détection du motif (0-255)
    pub pattern_confidence: u8,
}

/// Prédicteur de branchement ternaire avancé hybride à trois niveaux
pub struct TernaryBranchPredictor {
    /// Table de prédiction de branchement (BTB - Branch Target Buffer)
    table: Vec<BranchPredictorEntry>,
    /// Taille maximale de la table
    capacity: usize,
    /// Compteur global pour l'historique des branchements (32 bits pour 16 branchements ternaires)
    global_history: u64,
    /// Table de prédiction basée sur l'historique global
    global_pattern_table: HashMap<u64, BranchPredictionState>,
    /// Tables d'historique local par adresse
    local_history_table: HashMap<u32, u32>,
    /// Tables de prédiction basées sur l'historique local
    local_pattern_table: HashMap<u32, BranchPredictionState>,
    /// Table de choix entre prédicteurs (global vs local)
    choice_table: HashMap<u32, Trit>,
    /// Compteur de succès pour le prédicteur global
    global_success_counter: u32,
    /// Compteur de succès pour le prédicteur local
    local_success_counter: u32,
    /// Compteur de succès pour le prédicteur par instruction
    per_instr_success_counter: u32,
    /// Compteur total de prédictions
    total_predictions: u32,
    /// Compteur de prédictions correctes
    correct_predictions: u32,
}

impl BranchPredictorEntry {
    /// Crée une nouvelle entrée de prédiction
    pub fn new(address: u32, target_negative: u32, target_zero: u32, target_positive: u32) -> Self {
        BranchPredictorEntry {
            address,
            state: BranchPredictionState::Neutral,
            target_negative,
            target_zero,
            target_positive,
            confidence: 128,
            usage_counter: 0,
            loop_pattern: None,
            saturation_counter: 0,
            learning_weight: 0.5,
            prediction_history: Vec::with_capacity(16),
            is_merged: false,
            merged_branches: None,
        }
    }

    /// Met à jour l'état de prédiction en fonction du résultat réel
    pub fn update(&mut self, actual_outcome: Trit) {
        // Mise à jour du compteur à saturation
        self.saturation_counter = match actual_outcome {
            Trit::N => (self.saturation_counter - 1).max(-13),
            Trit::Z => self.saturation_counter,
            Trit::P => (self.saturation_counter + 1).min(13)
        };

        // Mise à jour de l'historique des prédictions
        if self.prediction_history.len() >= 16 {
            self.prediction_history.remove(0);
        }
        self.prediction_history.push(actual_outcome);

        // Ajustement du poids d'apprentissage
        if self.predict() == actual_outcome {
            self.learning_weight = (self.learning_weight + 0.1).min(1.0);
        } else {
            self.learning_weight = (self.learning_weight - 0.1).max(0.0);
        }

        // Mise à jour de l'état principal
        self.state = match (self.state, actual_outcome) {
            // Transitions pour résultat négatif (N)
            (BranchPredictionState::StronglyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::N) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::NeutralNegative, Trit::N) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::Neutral, Trit::N) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralPositive, Trit::N) => BranchPredictionState::Neutral,
            (BranchPredictionState::WeaklyPositive, Trit::N) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::N) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::StronglyPositive, Trit::N) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::Maybe, Trit::N) => BranchPredictionState::NeutralNegative,
            
            // Transitions pour résultat neutre (Z)
            (BranchPredictionState::StronglyNegative, Trit::Z) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::Z) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::Z) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralNegative, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::WeaklyPositive, Trit::Z) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::Z) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::StronglyPositive, Trit::Z) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::Maybe, Trit::Z) => BranchPredictionState::Neutral,
            
            // Transitions pour résultat positif (P)
            (BranchPredictionState::StronglyNegative, Trit::P) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::P) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::P) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralNegative, Trit::P) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::P) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::NeutralPositive, Trit::P) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::WeaklyPositive, Trit::P) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            (BranchPredictionState::StronglyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            (BranchPredictionState::Maybe, Trit::P) => BranchPredictionState::NeutralPositive,
        };

        // Mise à jour du niveau de confiance
        self.confidence = match actual_outcome {
            _ if self.predict() == actual_outcome => self.confidence.saturating_add(1),
            _ => self.confidence.saturating_sub(1),
        };
    }

    /// Fusionne plusieurs branchements en un seul
    pub fn merge_branches(&mut self, branch_addresses: Vec<u32>) {
        self.is_merged = true;
        self.merged_branches = Some(branch_addresses);
        // Réinitialiser l'état pour la nouvelle fusion
        self.state = BranchPredictionState::Merged;
        self.confidence = 128;
        self.prediction_history.clear();
    }

    /// Optimise la détection des motifs de boucle avec analyse avancée des séquences
    fn optimize_loop_pattern(&mut self) {
        // Ne rien faire si l'historique est trop petit
        if self.prediction_history.len() < 6 {
            return;
        }

        // Recherche de motifs de différentes longueurs (2 à 6 trits)
        for pattern_length in 2..=6 {
            if self.prediction_history.len() < pattern_length * 2 {
                continue; // Pas assez d'historique pour ce motif
            }

            // Extraire le motif potentiel des premiers éléments
            let mut potential_pattern = Vec::with_capacity(pattern_length);
            for i in 0..pattern_length {
                potential_pattern.push(self.prediction_history[i]);
            }
            
            // Vérifier si le motif se répète au moins une fois
            let mut repetition_count = 1;
            let mut is_repeating = true;
            
            // Vérifier les répétitions complètes du motif
            for r in 1..=(self.prediction_history.len() / pattern_length) - 1 {
                for i in 0..pattern_length {
                    let idx = r * pattern_length + i;
                    if idx >= self.prediction_history.len() {
                        break;
                    }
                    
                    if self.prediction_history[idx] != potential_pattern[i] {
                        is_repeating = false;
                        break;
                    }
                }
                
                if !is_repeating {
                    break;
                }
                
                repetition_count += 1;
            }
            
            // Si le motif se répète suffisamment et est meilleur que l'actuel
            if is_repeating && repetition_count >= 2 {
                let confidence_boost = (repetition_count as u8) * 25;
                
                // Mettre à jour ou créer un nouveau motif de boucle
                if let Some(pattern) = &mut self.loop_pattern {
                    // Ne mettre à jour que si ce motif est meilleur ou si la confiance est faible
                    if repetition_count > (pattern.sequence.len() as u32) || pattern.pattern_confidence < 100 {
                        pattern.sequence = potential_pattern;
                        pattern.current_position = 0;
                        pattern.iterations = repetition_count;
                        pattern.pattern_confidence = pattern.pattern_confidence.saturating_add(confidence_boost);
                    }
                } else {
                    // Créer un nouveau motif de boucle
                    self.loop_pattern = Some(LoopPattern {
                        iterations: repetition_count,
                        sequence: potential_pattern,
                        current_position: 0,
                        pattern_confidence: 50 + confidence_boost,
                    });
                }
                
                // Si on a trouvé un bon motif, on peut s'arrêter
                if repetition_count >= 3 {
                    break;
                }
            }
        }
        
        // Détecter les motifs alternants spéciaux (N-P-N-P ou similaires)
        if self.prediction_history.len() >= 6 {
            let mut is_alternating = true;
            for i in 0..3 {
                if self.prediction_history[i] != self.prediction_history[i+2] {
                    is_alternating = false;
                    break;
                }
            }
            
            if is_alternating {
                let alternating_pattern = vec![self.prediction_history[0], self.prediction_history[1]];
                
                // Créer ou mettre à jour le motif alternant
                if let Some(pattern) = &mut self.loop_pattern {
                    if pattern.sequence.len() > 2 || pattern.pattern_confidence < 150 {
                        pattern.sequence = alternating_pattern;
                        pattern.current_position = 0;
                        pattern.iterations = 3;
                        pattern.pattern_confidence = 200; // Haute confiance pour les motifs alternants
                    }
                } else {
                    self.loop_pattern = Some(LoopPattern {
                        iterations: 3,
                        sequence: alternating_pattern,
                        current_position: 0,
                        pattern_confidence: 200,
                    });
                }
            }
        }
    }

    /// Prédit la prochaine branche en fonction de l'état actuel
    pub fn predict(&self) -> Trit {
        // Optimisation pour les branchements fusionnés
        if self.is_merged {
            return match self.saturation_counter {
                i8::MIN..=-5 => Trit::N,
                -4..=4 => Trit::Z,
                5..=i8::MAX => Trit::P
            };
        }

        // Utiliser le motif de boucle si disponible et confiant
        if let Some(pattern) = &self.loop_pattern {
            if pattern.pattern_confidence > 200 {
                return pattern.sequence[pattern.current_position];
            }
        }

        match self.state {
            BranchPredictionState::StronglyNegative | 
            BranchPredictionState::ModeratelyNegative | 
            BranchPredictionState::WeaklyNegative | 
            BranchPredictionState::NeutralNegative => Trit::N,
            BranchPredictionState::Neutral => Trit::Z,
            BranchPredictionState::NeutralPositive | 
            BranchPredictionState::WeaklyPositive | 
            BranchPredictionState::ModeratelyPositive | 
            BranchPredictionState::StronglyPositive => Trit::P,
            BranchPredictionState::Maybe => {
                // Pour l'état spéculatif, utiliser le niveau de confiance
                if self.confidence > 200 {
                    match self.state {
                        BranchPredictionState::StronglyNegative => Trit::N,
                        BranchPredictionState::StronglyPositive => Trit::P,
                        _ => Trit::Z
                    }
                } else {
                    Trit::Z // Par défaut, rester neutre si pas assez confiant
                }
            }
        }
    }

    /// Retourne l'adresse cible en fonction de la prédiction
    pub fn get_target(&self) -> u32 {
        match self.predict() {
            Trit::N => self.target_negative,
            Trit::Z => self.target_zero,
            Trit::P => self.target_positive,
        }
    }
}

impl TernaryBranchPredictor {
    /// Crée un nouveau prédicteur de branchement ternaire hybride
    pub fn new(capacity: usize) -> Self {
        TernaryBranchPredictor {
            table: Vec::with_capacity(capacity),
            capacity,
            global_history: 0,
            global_pattern_table: HashMap::new(),
            local_history_table: HashMap::new(),
            local_pattern_table: HashMap::new(),
            choice_table: HashMap::new(),
            global_success_counter: 0,
            local_success_counter: 0,
            per_instr_success_counter: 0,
            total_predictions: 0,
            correct_predictions: 0,
        }
    }
    
    /// Fusionne plusieurs branchements binaires en un seul branchement ternaire
    /// Cette optimisation réduit les erreurs de prédiction en cascade
    pub fn merge_branches(&mut self, branch_addresses: &[u32]) {
        if branch_addresses.len() < 2 {
            return; // Besoin d'au moins 2 branchements pour la fusion
        }
        
        // Vérifier si les branchements sont proches (dans une fenêtre de 64 octets)
        let mut is_close = true;
        let base_addr = branch_addresses[0];
        for &addr in branch_addresses.iter().skip(1) {
            if addr.abs_diff(base_addr) > 64 {
                is_close = false;
                break;
            }
        }
        
        if !is_close {
            return; // Les branchements sont trop éloignés pour être fusionnés
        }
        
        // Créer une nouvelle entrée fusionnée ou mettre à jour une entrée existante
        let merged_addr = branch_addresses[0]; // Utiliser la première adresse comme référence
        
        // Vérifier si l'un des branchements est déjà dans la table
        let mut existing_entry_idx = None;
        for (idx, entry) in self.table.iter().enumerate() {
            if branch_addresses.contains(&entry.address) {
                existing_entry_idx = Some(idx);
                break;
            }
        }
        
        if let Some(idx) = existing_entry_idx {
            // Mettre à jour l'entrée existante
            let entry = &mut self.table[idx];
            entry.merge_branches(branch_addresses.to_vec());
            entry.address = merged_addr; // Utiliser l'adresse du premier branchement
        } else {
            // Créer une nouvelle entrée fusionnée si la table n'est pas pleine
            if self.table.len() < self.capacity {
                // Calculer des adresses cibles par défaut
                let pc_next = merged_addr.wrapping_add(4);
                let target_negative = merged_addr.wrapping_sub(8);
                let target_zero = pc_next;
                let target_positive = merged_addr.wrapping_add(16);
                
                let mut entry = BranchPredictorEntry::new(merged_addr, target_negative, target_zero, target_positive);
                entry.merge_branches(branch_addresses.to_vec());
                self.table.push(entry);
            } else {
                // Si la table est pleine, remplacer l'entrée la moins utilisée
                let mut min_usage = u32::MAX;
                let mut min_idx = 0;
                
                for (idx, entry) in self.table.iter().enumerate() {
                    if entry.usage_counter < min_usage {
                        min_usage = entry.usage_counter;
                        min_idx = idx;
                    }
                }
                
                // Calculer des adresses cibles par défaut
                let pc_next = merged_addr.wrapping_add(4);
                let target_negative = merged_addr.wrapping_sub(8);
                let target_zero = pc_next;
                let target_positive = merged_addr.wrapping_add(16);
                
                let mut entry = BranchPredictorEntry::new(merged_addr, target_negative, target_zero, target_positive);
                entry.merge_branches(branch_addresses.to_vec());
                self.table[min_idx] = entry;
            }
        }
        
        // Mettre à jour les tables d'historique pour le branchement fusionné
        self.local_history_table.insert(merged_addr, 0);
        self.choice_table.insert(merged_addr, Trit::Z);
    }

    /// Détecte et met à jour les motifs de boucle pour une instruction
    fn update_loop_pattern(&mut self, entry: &mut BranchPredictorEntry, actual_result: Trit) {
        if let Some(pattern) = &mut entry.loop_pattern {
            // Vérifier si le résultat actuel correspond au motif attendu
            if pattern.sequence[pattern.current_position] == actual_result {
                pattern.pattern_confidence = pattern.pattern_confidence.saturating_add(1);
                pattern.current_position = (pattern.current_position + 1) % pattern.sequence.len();
                
                if pattern.current_position == 0 {
                    pattern.iterations = pattern.iterations.saturating_add(1);
                }
            } else {
                pattern.pattern_confidence = pattern.pattern_confidence.saturating_sub(1);
                if pattern.pattern_confidence < 10 {
                    entry.loop_pattern = None; // Réinitialiser si le motif n'est plus fiable
                }
            }
        } else {
            // Tenter de détecter un nouveau motif de boucle
            let mut sequence = Vec::new();
            sequence.push(actual_result);
            entry.loop_pattern = Some(LoopPattern {
                iterations: 1,
                sequence,
                current_position: 0,
                pattern_confidence: 1,
            });
        }
    }
    
    /// Retourne le taux de précision du prédicteur
    pub fn accuracy(&self) -> f64 {
        if self.total_predictions == 0 {
            return 0.0;
        }
        self.correct_predictions as f64 / self.total_predictions as f64
    }

    /// Prédit le résultat d'un branchement en utilisant le prédicteur hybride à trois niveaux
    pub fn predict(&mut self, branch_address: u32) -> BranchPrediction {
        self.total_predictions += 1;
        
        // 1. Prédiction par instruction (basée sur l'historique spécifique à cette instruction)
        let per_instr_prediction = self.predict_per_instruction(branch_address);
        
        // 2. Prédiction globale (basée sur l'historique global des branchements)
        let global_prediction = self.predict_global(branch_address);
        
        // 3. Prédiction locale (basée sur l'historique local de cette instruction)
        let local_prediction = self.predict_local(branch_address);
        
        // 4. Utiliser la table de choix pour sélectionner entre les prédicteurs
        let choice = self.choice_table.get(&branch_address).cloned().unwrap_or(Trit::Z);
        
        // 5. Sélectionner la prédiction finale en fonction de la table de choix
        let final_prediction = match choice {
            Trit::N => {
                // Favoriser la prédiction par instruction
                if per_instr_prediction == BranchPrediction::Speculative {
                    // Si incertain, utiliser la prédiction globale
                    global_prediction
                } else {
                    per_instr_prediction
                }
            },
            Trit::Z => {
                // Favoriser la prédiction globale
                if global_prediction == BranchPrediction::Speculative {
                    // Si incertain, utiliser la prédiction locale
                    local_prediction
                } else {
                    global_prediction
                }
            },
            Trit::P => {
                // Favoriser la prédiction locale
                if local_prediction == BranchPrediction::Speculative {
                    // Si incertain, utiliser la prédiction par instruction
                    per_instr_prediction
                } else {
                    local_prediction
                }
            },
        };
        
        final_prediction
    }
    
    /// Prédit le résultat d'un branchement en utilisant l'historique spécifique à cette instruction
    fn predict_per_instruction(&self, branch_address: u32) -> BranchPrediction {
        // Rechercher l'entrée correspondante dans la table
        for entry in &self.table {
            if entry.address == branch_address {
                // Retourner la prédiction basée sur l'état actuel
                return match entry.state {
                    BranchPredictionState::StronglyNegative | 
                    BranchPredictionState::ModeratelyNegative | 
                    BranchPredictionState::WeaklyNegative | 
                    BranchPredictionState::NeutralNegative => BranchPrediction::Negative,
                    
                    BranchPredictionState::Neutral => BranchPrediction::Neutral,
                    
                    BranchPredictionState::NeutralPositive | 
                    BranchPredictionState::WeaklyPositive | 
                    BranchPredictionState::ModeratelyPositive | 
                    BranchPredictionState::StronglyPositive => BranchPrediction::Positive,
                    
                    BranchPredictionState::Maybe => BranchPrediction::Speculative,
                    BranchPredictionState::Merged => {
                        // Pour les branchements fusionnés, utiliser le compteur à saturation
                        match entry.saturation_counter {
                            i8::MIN..=-5 => BranchPrediction::Negative,
                            -4..=4 => BranchPrediction::Neutral,
                            5..=i8::MAX => BranchPrediction::Positive
                        }
                    }
                };
            }
        }

        // Si l'instruction n'est pas dans la table, retourner une prédiction par défaut
        BranchPrediction::Neutral
    }
    
    /// Prédit le résultat d'un branchement en utilisant l'historique global
    fn predict_global(&self, _branch_address: u32) -> BranchPrediction {
        // Utiliser l'historique global comme index dans la table de motifs globaux
        let index = self.global_history & 0xFFFF; // Utiliser les 16 derniers branchements
        
        if let Some(state) = self.global_pattern_table.get(&index) {
            match state {
                BranchPredictionState::StronglyNegative | 
                BranchPredictionState::ModeratelyNegative | 
                BranchPredictionState::WeaklyNegative | 
                BranchPredictionState::NeutralNegative => BranchPrediction::Negative,
                
                BranchPredictionState::Neutral => BranchPrediction::Neutral,
                
                BranchPredictionState::NeutralPositive | 
                BranchPredictionState::WeaklyPositive | 
                BranchPredictionState::ModeratelyPositive | 
                BranchPredictionState::StronglyPositive => BranchPrediction::Positive,
                
                BranchPredictionState::Maybe => BranchPrediction::Speculative,
                BranchPredictionState::Merged => BranchPrediction::Speculative,
            }
        } else {
            // Si pas d'entrée dans la table, utiliser une prédiction par défaut
            BranchPrediction::Neutral
        }
    }
    
    /// Prédit le résultat d'un branchement en utilisant l'historique local
    fn predict_local(&self, branch_address: u32) -> BranchPrediction {
        // Récupérer l'historique local pour cette adresse
        if let Some(local_history) = self.local_history_table.get(&branch_address) {
            // Utiliser l'historique local comme index dans la table de motifs locaux
            if let Some(state) = self.local_pattern_table.get(local_history) {
                match state {
                    BranchPredictionState::StronglyNegative => BranchPrediction::Negative,
                    BranchPredictionState::ModeratelyNegative => BranchPrediction::Negative,
                    BranchPredictionState::WeaklyNegative => BranchPrediction::Negative,
                    BranchPredictionState::NeutralNegative => BranchPrediction::Negative,
                    BranchPredictionState::Neutral => BranchPrediction::Neutral,
                    BranchPredictionState::NeutralPositive => BranchPrediction::Positive,
                    BranchPredictionState::WeaklyPositive => BranchPrediction::Positive,
                    BranchPredictionState::ModeratelyPositive => BranchPrediction::Positive,
                    BranchPredictionState::StronglyPositive => BranchPrediction::Positive,
                    BranchPredictionState::Maybe => BranchPrediction::Speculative,
                }
            } else {
                // Si pas d'entrée dans la table, utiliser une prédiction par défaut
                BranchPrediction::Neutral
            }
        } else {
            // Si pas d'historique local, utiliser une prédiction par défaut
            BranchPrediction::Neutral
        }
    }

    /// Met à jour le prédicteur après l'exécution d'un branchement
    /// Intègre des mécanismes avancés d'apprentissage et d'optimisation
    pub fn update(&mut self, branch_address: u32, actual_result: Trit) {
        // Sauvegarder les prédictions avant la mise à jour pour évaluer leur précision
        let per_instr_prediction = self.predict_per_instruction(branch_address);
        let global_prediction = self.predict_global(branch_address);
        let local_prediction = self.predict_local(branch_address);
        
        // Vérifier si les prédictions étaient correctes
        let per_instr_correct = self.is_prediction_correct(per_instr_prediction, actual_result);
        let global_correct = self.is_prediction_correct(global_prediction, actual_result);
        let local_correct = self.is_prediction_correct(local_prediction, actual_result);
        
        // Mettre à jour le compteur de prédictions correctes si au moins un prédicteur était correct
        if per_instr_correct || global_correct || local_correct {
            self.correct_predictions += 1;
        }
        
        // 1. Mettre à jour le prédicteur par instruction
        self.update_per_instruction(branch_address, actual_result);
        
        // 2. Mettre à jour le prédicteur global
        self.update_global(actual_result);
        
        // 3. Mettre à jour le prédicteur local
        self.update_local(branch_address, actual_result);
        
        // 4. Mettre à jour la table de choix
        self.update_choice_table(branch_address, per_instr_correct, global_correct, local_correct);
        
        // 5. Optimiser la détection des motifs de boucle
        if let Some(entry_idx) = self.table.iter().position(|e| e.address == branch_address) {
            // Mettre à jour les motifs de boucle pour cette entrée
            let entry = &mut self.table[entry_idx];
            self.update_loop_pattern(entry, actual_result);
            
            // Optimiser les motifs de boucle périodiquement
            if entry.usage_counter % 10 == 0 {
                entry.optimize_loop_pattern();
            }
            
            // Vérifier si ce branchement fait partie d'un groupe fusionnable
            if !entry.is_merged && entry.usage_counter > 50 {
                // Rechercher des branchements proches qui pourraient être fusionnés
                let mut fusion_candidates = Vec::new();
                fusion_candidates.push(branch_address);
                
                for other_entry in &self.table {
                    if other_entry.address != branch_address && 
                       other_entry.address.abs_diff(branch_address) <= 64 && 
                       other_entry.usage_counter > 20 {
                        fusion_candidates.push(other_entry.address);
                    }
                }
                
                // Si on a trouvé des candidats pour la fusion, les fusionner
                if fusion_candidates.len() >= 2 {
                    self.merge_branches(&fusion_candidates);
                }
            }
        }
        
        // 6. Analyse statistique périodique pour optimiser le prédicteur
        if self.total_predictions % 1000 == 0 {
            // Calculer les taux de succès relatifs
            let per_instr_rate = self.per_instr_success_counter as f64 / self.total_predictions as f64;
            let global_rate = self.global_success_counter as f64 / self.total_predictions as f64;
            let local_rate = self.local_success_counter as f64 / self.total_predictions as f64;
            
            // Ajuster dynamiquement la stratégie de prédiction
            if per_instr_rate > global_rate && per_instr_rate > local_rate {
                // Favoriser le prédicteur par instruction pour les nouveaux branchements
                self.choice_table.entry(branch_address).or_insert(Trit::N);
            } else if global_rate > per_instr_rate && global_rate > local_rate {
                // Favoriser le prédicteur global pour les nouveaux branchements
                self.choice_table.entry(branch_address).or_insert(Trit::Z);
            } else if local_rate > per_instr_rate && local_rate > global_rate {
                // Favoriser le prédicteur local pour les nouveaux branchements
                self.choice_table.entry(branch_address).or_insert(Trit::P);
            }
        }
    }
    
    /// Vérifie si une prédiction était correcte par rapport au résultat réel
    fn is_prediction_correct(&self, prediction: BranchPrediction, actual_result: Trit) -> bool {
        match (prediction, actual_result) {
            (BranchPrediction::Negative, Trit::N) => true,
            (BranchPrediction::Neutral, Trit::Z) => true,
            (BranchPrediction::Positive, Trit::P) => true,
            (BranchPrediction::Speculative, _) => false, // Une prédiction spéculative n'est jamais considérée comme correcte
            _ => false,
        }
    }
    
    /// Met à jour le prédicteur par instruction
    fn update_per_instruction(&mut self, branch_address: u32, actual_result: Trit) {
        // Rechercher l'entrée correspondante dans la table
        for entry in &mut self.table {
            if entry.address == branch_address {
                // Mettre à jour l'état du prédicteur en fonction du résultat réel
                entry.state = match (entry.state, actual_result) {
                    // Transitions pour résultat négatif (N)
                    (BranchPredictionState::StronglyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
                    (BranchPredictionState::ModeratelyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
                    (BranchPredictionState::WeaklyNegative, Trit::N) => BranchPredictionState::ModeratelyNegative,
                    (BranchPredictionState::NeutralNegative, Trit::N) => BranchPredictionState::WeaklyNegative,
                    (BranchPredictionState::Neutral, Trit::N) => BranchPredictionState::NeutralNegative,
                    (BranchPredictionState::NeutralPositive, Trit::N) => BranchPredictionState::Neutral,
                    (BranchPredictionState::WeaklyPositive, Trit::N) => BranchPredictionState::NeutralPositive,
                    (BranchPredictionState::ModeratelyPositive, Trit::N) => BranchPredictionState::WeaklyPositive,
                    (BranchPredictionState::StronglyPositive, Trit::N) => BranchPredictionState::ModeratelyPositive,
                    (BranchPredictionState::Maybe, Trit::N) => BranchPredictionState::NeutralNegative,
                    
                    // Transitions pour résultat neutre (Z)
                    (BranchPredictionState::StronglyNegative, Trit::Z) => BranchPredictionState::ModeratelyNegative,
                    (BranchPredictionState::ModeratelyNegative, Trit::Z) => BranchPredictionState::WeaklyNegative,
                    (BranchPredictionState::WeaklyNegative, Trit::Z) => BranchPredictionState::NeutralNegative,
                    (BranchPredictionState::NeutralNegative, Trit::Z) => BranchPredictionState::Neutral,
                    (BranchPredictionState::Neutral, Trit::Z) => BranchPredictionState::Neutral,
                    (BranchPredictionState::NeutralPositive, Trit::Z) => BranchPredictionState::Neutral,
                    (BranchPredictionState::WeaklyPositive, Trit::Z) => BranchPredictionState::NeutralPositive,
                    (BranchPredictionState::ModeratelyPositive, Trit::Z) => BranchPredictionState::WeaklyPositive,
                    (BranchPredictionState::StronglyPositive, Trit::Z) => BranchPredictionState::ModeratelyPositive,
                    (BranchPredictionState::Maybe, Trit::Z) => BranchPredictionState::Neutral,
                    
                    // Transitions pour résultat positif (P)
                    (BranchPredictionState::StronglyNegative, Trit::P) => BranchPredictionState::ModeratelyNegative,
                    (BranchPredictionState::ModeratelyNegative, Trit::P) => BranchPredictionState::WeaklyNegative,
                    (BranchPredictionState::WeaklyNegative, Trit::P) => BranchPredictionState::NeutralNegative,
                    (BranchPredictionState::NeutralNegative, Trit::P) => BranchPredictionState::Neutral,
                    (BranchPredictionState::Neutral, Trit::P) => BranchPredictionState::NeutralPositive,
                    (BranchPredictionState::NeutralPositive, Trit::P) => BranchPredictionState::WeaklyPositive,
                    (BranchPredictionState::WeaklyPositive, Trit::P) => BranchPredictionState::ModeratelyPositive,
                    (BranchPredictionState::ModeratelyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
                    (BranchPredictionState::StronglyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
                    (BranchPredictionState::Maybe, Trit::P) => BranchPredictionState::NeutralPositive,
                };
                
                // Incrémenter le compteur d'utilisation
                entry.usage_counter += 1;
                return;
            }
        }

        // Si l'instruction n'est pas dans la table, ajouter une nouvelle entrée
        self.add_entry(branch_address, actual_result);
    }
    
    /// Met à jour le prédicteur global
    fn update_global(&mut self, actual_result: Trit) {
        let index = self.global_history & 0xFFFF;
        
        // Mettre à jour la table de motifs globaux
        let state = self.global_pattern_table.entry(index).or_insert(BranchPredictionState::Neutral);
        let current_state = *state; // Stocker la valeur actuelle dans une variable temporaire
        
        // Calculer le nouvel état sans référencer self directement
        let new_state = match (current_state, actual_result) {
            (BranchPredictionState::StronglyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::StronglyNegative, _) => BranchPredictionState::ModeratelyNegative,
            
            (BranchPredictionState::ModeratelyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::Z) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::P) => BranchPredictionState::WeaklyNegative,
            
            (BranchPredictionState::WeaklyNegative, Trit::N) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::Z) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::WeaklyNegative, Trit::P) => BranchPredictionState::NeutralNegative,
            
            (BranchPredictionState::NeutralNegative, Trit::N) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::NeutralNegative, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralNegative, Trit::P) => BranchPredictionState::Neutral,
            
            (BranchPredictionState::Neutral, Trit::N) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::Neutral, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::P) => BranchPredictionState::NeutralPositive,
            
            (BranchPredictionState::NeutralPositive, Trit::N) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::P) => BranchPredictionState::WeaklyPositive,
            
            (BranchPredictionState::WeaklyPositive, Trit::N) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::WeaklyPositive, Trit::Z) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::WeaklyPositive, Trit::P) => BranchPredictionState::ModeratelyPositive,
            
            (BranchPredictionState::ModeratelyPositive, Trit::N) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::Z) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            
            (BranchPredictionState::StronglyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            (BranchPredictionState::StronglyPositive, _) => BranchPredictionState::ModeratelyPositive,
            
            (BranchPredictionState::Maybe, Trit::N) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::Maybe, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Maybe, Trit::P) => BranchPredictionState::WeaklyPositive,
        };
        
        *state = new_state;
        
        // Mettre à jour l'historique global
        self.update_global_history(actual_result);
    }
    
    /// Met à jour le prédicteur local
    fn update_local(&mut self, branch_address: u32, actual_result: Trit) {
        // Récupérer ou créer l'historique local pour cette adresse
        let history_value = *self.local_history_table.entry(branch_address).or_insert(0);
        
        // Récupérer l'état actuel
        let current_state = *self.local_pattern_table.entry(history_value).or_insert(BranchPredictionState::Neutral);
        
        // Calculer le nouvel état
        let new_state = match (current_state, actual_result) {
            (BranchPredictionState::StronglyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::StronglyNegative, Trit::Z) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::StronglyNegative, Trit::P) => BranchPredictionState::WeaklyNegative,
            
            (BranchPredictionState::ModeratelyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::Z) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::P) => BranchPredictionState::NeutralNegative,
            
            (BranchPredictionState::WeaklyNegative, Trit::N) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::Z) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::WeaklyNegative, Trit::P) => BranchPredictionState::Neutral,
            
            (BranchPredictionState::NeutralNegative, Trit::N) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::NeutralNegative, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralNegative, Trit::P) => BranchPredictionState::NeutralPositive,
            
            (BranchPredictionState::Neutral, Trit::N) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::Neutral, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::P) => BranchPredictionState::NeutralPositive,
            
            (BranchPredictionState::NeutralPositive, Trit::N) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::P) => BranchPredictionState::WeaklyPositive,
            
            (BranchPredictionState::WeaklyPositive, Trit::N) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::WeaklyPositive, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::WeaklyPositive, Trit::P) => BranchPredictionState::ModeratelyPositive,
            
            (BranchPredictionState::ModeratelyPositive, Trit::N) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::Z) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            
            (BranchPredictionState::StronglyPositive, Trit::N) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::StronglyPositive, Trit::Z) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::StronglyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            
            (BranchPredictionState::Maybe, Trit::N) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::Maybe, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Maybe, Trit::P) => BranchPredictionState::NeutralPositive,
        };

        // Mettre à jour l'état
        *self.local_pattern_table.entry(history_value).or_insert(BranchPredictionState::Neutral) = new_state;
        
        // Calculer la nouvelle valeur d'historique local
        let new_history = (history_value << 2) & 0xFFFFFFFF;
        let history_bits = match actual_result {
            Trit::N => 0b00,
            Trit::Z => 0b01,
            Trit::P => 0b10,
        };
        
        let updated_history = new_history | history_bits;
        
        // Mettre à jour l'historique local
        *self.local_history_table.entry(branch_address).or_insert(0) = updated_history;
    }
    
    /// Met à jour la table de choix entre les prédicteurs
    /// Utilise un algorithme d'apprentissage par renforcement adaptatif pour sélectionner
    /// le meilleur prédicteur en fonction des performances historiques
    fn update_choice_table(&mut self, branch_address: u32, per_instr_correct: bool, global_correct: bool, local_correct: bool) {
        let choice = self.choice_table.entry(branch_address).or_insert(Trit::Z);
        
        // Calculer un score pour chaque prédicteur
        let per_instr_score = if per_instr_correct { 2 } else { -1 };
        let global_score = if global_correct { 2 } else { -1 };
        let local_score = if local_correct { 2 } else { -1 };
        
        // Facteur d'apprentissage: plus élevé pour les branchements fréquents
        let learning_rate = if let Some(entry) = self.table.iter().find(|e| e.address == branch_address) {
            // Ajuster le taux d'apprentissage en fonction de la fréquence d'utilisation
            // et de la confiance dans les prédictions
            let usage_factor = (entry.usage_counter as f32).min(1000.0) / 1000.0;
            let confidence_factor = entry.confidence as f32 / 255.0;
            0.1 + (0.4 * usage_factor * confidence_factor)
        } else {
            0.2 // Taux d'apprentissage par défaut
        };
        
        // Mettre à jour la table de choix en utilisant une approche ternaire sophistiquée
        *choice = match (*choice, per_instr_score, global_score, local_score) {
            // Si le choix actuel est N (favoriser prédicteur par instruction)
            (Trit::N, s1, s2, s3) if s1 > s2 && s1 > s3 => {
                // Renforcer le choix si le prédicteur par instruction est le meilleur
                Trit::N
            },
            (Trit::N, _, s2, s3) if s2 > s3 => {
                // Passer au prédicteur global s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::Z } else { Trit::N }
            },
            (Trit::N, _, _, _) => {
                // Passer au prédicteur local s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::Z } else { Trit::N }
            },
            
            // Si le choix actuel est Z (favoriser prédicteur global)
            (Trit::Z, s1, s2, s3) if s2 > s1 && s2 > s3 => {
                // Renforcer le choix si le prédicteur global est le meilleur
                Trit::Z
            },
            (Trit::Z, s1, _, s3) if s1 > s3 => {
                // Passer au prédicteur par instruction s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::N } else { Trit::Z }
            },
            (Trit::Z, _, _, _) => {
                // Passer au prédicteur local s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::P } else { Trit::Z }
            },
            
            // Si le choix actuel est P (favoriser prédicteur local)
            (Trit::P, s1, s2, s3) if s3 > s1 && s3 > s2 => {
                // Renforcer le choix si le prédicteur local est le meilleur
                Trit::P
            },
            (Trit::P, s1, s2, _) if s1 > s2 => {
                // Passer au prédicteur par instruction s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::N } else { Trit::P }
            },
            (Trit::P, _, _, _) => {
                // Passer au prédicteur global s'il est meilleur
                if rand::random::<f32>() < learning_rate { Trit::Z } else { Trit::P }
            },
        };
        
        // Mettre à jour les compteurs de succès pour les statistiques à long terme
        if per_instr_correct { self.per_instr_success_counter += 1; }
        if global_correct { self.global_success_counter += 1; }
        if local_correct { self.local_success_counter += 1; }
    }
    
    /// Fonction de transition d'état générique pour les compteurs à saturation ternaires
    fn transition_state(&self, current_state: BranchPredictionState, result: Trit) -> BranchPredictionState {
        match (current_state, result) {
            // Transitions pour résultat négatif (N)
            (BranchPredictionState::StronglyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::N) => BranchPredictionState::StronglyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::N) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::NeutralNegative, Trit::N) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::Neutral, Trit::N) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralPositive, Trit::N) => BranchPredictionState::Neutral,
            (BranchPredictionState::WeaklyPositive, Trit::N) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::N) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::StronglyPositive, Trit::N) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::Maybe, Trit::N) => BranchPredictionState::NeutralNegative,
            
            // Transitions pour résultat neutre (Z)
            (BranchPredictionState::StronglyNegative, Trit::Z) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::Z) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::Z) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralNegative, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::NeutralPositive, Trit::Z) => BranchPredictionState::Neutral,
            (BranchPredictionState::WeaklyPositive, Trit::Z) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::Z) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::StronglyPositive, Trit::Z) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::Maybe, Trit::Z) => BranchPredictionState::Neutral,
            
            // Transitions pour résultat positif (P)
            (BranchPredictionState::StronglyNegative, Trit::P) => BranchPredictionState::ModeratelyNegative,
            (BranchPredictionState::ModeratelyNegative, Trit::P) => BranchPredictionState::WeaklyNegative,
            (BranchPredictionState::WeaklyNegative, Trit::P) => BranchPredictionState::NeutralNegative,
            (BranchPredictionState::NeutralNegative, Trit::P) => BranchPredictionState::Neutral,
            (BranchPredictionState::Neutral, Trit::P) => BranchPredictionState::NeutralPositive,
            (BranchPredictionState::NeutralPositive, Trit::P) => BranchPredictionState::WeaklyPositive,
            (BranchPredictionState::WeaklyPositive, Trit::P) => BranchPredictionState::ModeratelyPositive,
            (BranchPredictionState::ModeratelyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            (BranchPredictionState::StronglyPositive, Trit::P) => BranchPredictionState::StronglyPositive,
            (BranchPredictionState::Maybe, Trit::P) => BranchPredictionState::NeutralPositive,
        }
    }

    /// Ajoute une nouvelle entrée dans la table de prédiction
    fn add_entry(&mut self, branch_address: u32, actual_result: Trit) {
        // Si la table est pleine, supprimer l'entrée la moins utilisée
        if self.table.len() >= self.capacity {
            let mut min_usage = u32::MAX;
            let mut min_index = 0;
            
            for (i, entry) in self.table.iter().enumerate() {
                if entry.usage_counter < min_usage {
                    min_usage = entry.usage_counter;
                    min_index = i;
                }
            }
            
            self.table.remove(min_index);
        }

        // Déterminer l'état initial en fonction du résultat actuel
        let initial_state = match actual_result {
            Trit::N => BranchPredictionState::NeutralNegative,
            Trit::Z => BranchPredictionState::Neutral,
            Trit::P => BranchPredictionState::NeutralPositive,
        };

        // Calculer des adresses cibles par défaut basées sur l'adresse actuelle
        // Ces valeurs seront mises à jour lors des exécutions futures
        let pc_next = branch_address.wrapping_add(4); // Instruction suivante (par défaut)
        let target_negative = branch_address.wrapping_sub(8); // Branche négative (par défaut)
        let target_zero = pc_next; // Branche neutre (par défaut)
        let target_positive = branch_address.wrapping_add(16); // Branche positive (par défaut)

        // Ajouter la nouvelle entrée avec tous les champs nécessaires
        self.table.push(BranchPredictorEntry {
            address: branch_address,
            state: initial_state,
            target_negative,
            target_zero,
            target_positive,
            confidence: 128, // Confiance moyenne au départ
            usage_counter: 1,
            loop_pattern: None,
            saturation_counter: match actual_result {
                Trit::N => -1,
                Trit::Z => 0,
                Trit::P => 1,
            },
            learning_weight: 0.5, // Poids d'apprentissage initial
            prediction_history: vec![actual_result], // Commencer l'historique avec le résultat actuel
            is_merged: false,
            merged_branches: None,
        });

        // Initialiser l'historique local pour cette adresse
        self.local_history_table.insert(branch_address, 0);
        
        // Mettre à jour les prédicteurs global et local
        self.update_global(actual_result);
        self.update_local(branch_address, actual_result);
        
        // Initialiser la table de choix avec une valeur neutre
        self.choice_table.insert(branch_address, Trit::Z);
    }

    /// Met à jour l'historique global des branchements
    fn update_global_history(&mut self, result: Trit) {
        // Décaler l'historique de 2 bits (pour encoder les 3 états possibles)
        self.global_history <<= 2;
        
        // Encoder le résultat ternaire en 2 bits
        let encoded = match result {
            Trit::N => 0b00,
            Trit::Z => 0b01,
            Trit::P => 0b10,
        };
        
        // Ajouter le nouveau résultat à l'historique
        self.global_history |= encoded;
        
        // Garder seulement les 32 derniers résultats (64 bits)
        self.global_history &= 0xFFFFFFFFFFFFFFFF;
    }
    
    /// Retourne des statistiques sur les performances du prédicteur
    pub fn get_stats(&self) -> (u32, u32, u32, u32, u32, f64) {
        (
            self.total_predictions,
            self.correct_predictions,
            self.per_instr_success_counter,
            self.global_success_counter,
            self.local_success_counter,
            self.accuracy()
        )
    }
    
    /// Réinitialise les compteurs de statistiques
    pub fn reset_stats(&mut self) {
        self.total_predictions = 0;
        self.correct_predictions = 0;
        self.per_instr_success_counter = 0;
        self.global_success_counter = 0;
        self.local_success_counter = 0;
    }
}

/// Instruction de branchement ternaire avec indice de prédiction
pub struct Branch3Hint {
    /// Registre source contenant la condition
    pub rs1: usize,
    /// Indice de prédiction (N, Z, P ou Maybe)
    pub hint: Trit,
    /// Décalage pour la branche négative
    pub offset_neg: i32,
    /// Décalage pour la branche neutre
    pub offset_zero: i32,
    /// Décalage pour la branche positive
    pub offset_pos: i32,
}

/// Exécute une instruction de branchement ternaire avec prédiction avancée
pub fn execute_branch3_hint(
    branch: &Branch3Hint,
    predictor: &mut TernaryBranchPredictor,
    pc: u32,
    rs1_value: Word,
) -> u32 {
    // Convertir la valeur du registre en trit (en prenant le trit de poids fort)
    let condition = if let Some(tryte) = rs1_value.tryte(7) {
        match tryte {
            Tryte::Digit(_) => {
                // Utiliser la méthode get_trit pour accéder au trit de poids fort
                tryte.get_trit(2) // Trit de poids fort
            },
            _ => Trit::Z, // Valeur par défaut pour les états spéciaux
        }
    } else {
        Trit::Z // Valeur par défaut
    };

    // Obtenir la prédiction du prédicteur hybride
    let prediction = predictor.predict(pc);
    
    // Utiliser l'indice de prédiction fourni par l'instruction si disponible
    let final_prediction = if branch.hint != Trit::Z {
        // Si l'instruction fournit un indice de prédiction, l'utiliser
        match branch.hint {
            Trit::N => BranchPrediction::Negative,
            Trit::Z => BranchPrediction::Neutral,
            Trit::P => BranchPrediction::Positive,
        }
    } else {
        // Sinon, utiliser la prédiction du prédicteur hybride
        prediction
    };
    
    // Calculer la nouvelle valeur du PC en fonction de la prédiction
    let _predicted_pc = match final_prediction {
        BranchPrediction::Negative => pc.wrapping_add((branch.offset_neg * 4) as u32),
        BranchPrediction::Neutral => pc.wrapping_add((branch.offset_zero * 4) as u32),
        BranchPrediction::Positive => pc.wrapping_add((branch.offset_pos * 4) as u32),
        BranchPrediction::Speculative => {
            // Pour une prédiction spéculative, nous pourrions implémenter une logique
            // plus avancée comme l'exploration de plusieurs chemins, mais pour l'instant
            // nous utilisons simplement la condition réelle
            match condition {
                Trit::N => pc.wrapping_add((branch.offset_neg * 4) as u32),
                Trit::Z => pc.wrapping_add((branch.offset_zero * 4) as u32),
                Trit::P => pc.wrapping_add((branch.offset_pos * 4) as u32),
            }
        }
    };
    
    // Calculer la nouvelle valeur du PC en fonction de la condition réelle
    let actual_pc = match condition {
        Trit::N => pc.wrapping_add((branch.offset_neg * 4) as u32),
        Trit::Z => pc.wrapping_add((branch.offset_zero * 4) as u32),
        Trit::P => pc.wrapping_add((branch.offset_pos * 4) as u32),
    };

    // Mettre à jour le prédicteur avec le résultat réel
    predictor.update(pc, condition);

    // Retourner le PC réel (dans un pipeline réel, nous aurions besoin de gérer
    // les mauvaises prédictions et les vidages de pipeline ici)
    actual_pc
}