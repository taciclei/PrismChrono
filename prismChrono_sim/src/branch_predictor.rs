// src/branch_predictor.rs
// Implémentation du prédicteur de branchement ternaire avancé hybride à trois niveaux

use crate::core::{Trit, Tryte, Word};
use std::collections::HashMap;

/// États possibles du prédicteur de branchement ternaire
/// Utilise un compteur à saturation ternaire (TSC) avec 9 états
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BranchPredictionState {
    /// Fortement négatif (prédiction: branche négative)
    StronglyNegative,
    /// Moyennement négatif (prédiction: branche négative)
    ModeratelyNegative,
    /// Faiblement négatif (prédiction: branche négative, mais incertain)
    WeaklyNegative,
    /// Neutre avec tendance négative
    NeutralNegative,
    /// Neutre (prédiction: branche neutre)
    Neutral,
    /// Neutre avec tendance positive
    NeutralPositive,
    /// Faiblement positif (prédiction: branche positive, mais incertain)
    WeaklyPositive,
    /// Moyennement positif (prédiction: branche positive)
    ModeratelyPositive,
    /// Fortement positif (prédiction: branche positive)
    StronglyPositive,
    /// Peut-être (état incertain, exploration de chemins multiples)
    Maybe,
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
    /// Compteur d'utilisation (pour la politique de remplacement)
    pub usage_counter: u32,
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
    pub fn update(&mut self, branch_address: u32, actual_result: Trit) {
        // Sauvegarder les prédictions avant la mise à jour pour évaluer leur précision
        let per_instr_prediction = self.predict_per_instruction(branch_address);
        let global_prediction = self.predict_global(branch_address);
        let local_prediction = self.predict_local(branch_address);
        
        // Vérifier si les prédictions étaient correctes
        let per_instr_correct = self.is_prediction_correct(per_instr_prediction, actual_result);
        let global_correct = self.is_prediction_correct(global_prediction, actual_result);
        let local_correct = self.is_prediction_correct(local_prediction, actual_result);
        
        // Mettre à jour les compteurs de succès
        if per_instr_correct { self.per_instr_success_counter += 1; }
        if global_correct { self.global_success_counter += 1; }
        if local_correct { self.local_success_counter += 1; }
        
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
    fn update_choice_table(&mut self, branch_address: u32, per_instr_correct: bool, global_correct: bool, local_correct: bool) {
        let choice = self.choice_table.entry(branch_address).or_insert(Trit::Z);
        
        // Ajuster la table de choix en fonction des performances relatives
        if per_instr_correct && !global_correct && !local_correct {
            // Le prédicteur par instruction était le seul correct
            *choice = match *choice {
                Trit::N => Trit::N,
                Trit::Z => Trit::N,
                Trit::P => Trit::Z,
            };
        } else if global_correct && !per_instr_correct && !local_correct {
            // Le prédicteur global était le seul correct
            *choice = match *choice {
                Trit::N => Trit::Z,
                Trit::Z => Trit::Z,
                Trit::P => Trit::Z,
            };
        } else if local_correct && !per_instr_correct && !global_correct {
            // Le prédicteur local était le seul correct
            *choice = match *choice {
                Trit::N => Trit::Z,
                Trit::Z => Trit::P,
                Trit::P => Trit::P,
            };
        }
        // Si plusieurs prédicteurs sont corrects ou tous incorrects, ne pas changer la table de choix
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

        // Ajouter la nouvelle entrée
        self.table.push(BranchPredictorEntry {
            address: branch_address,
            state: initial_state,
            usage_counter: 1,
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