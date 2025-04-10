// src/bin/test_branch_predictor.rs
// Programme de test pour le prédicteur de branchement ternaire avancé

use prismchrono_sim::branch_predictor::{TernaryBranchPredictor, BranchPrediction, Branch3Hint};
use prismchrono_sim::core::{Trit, Tryte, Word};
use std::time::Instant;

fn main() {
    println!("Test du prédicteur de branchement ternaire avancé hybride à trois niveaux");
    println!("====================================================================\n");

    // Créer une instance du prédicteur avec une table de 64 entrées
    let mut predictor = TernaryBranchPredictor::new(64);

    // Test 1: Prédiction de base et apprentissage
    test_basic_prediction(&mut predictor);

    // Test 2: Détection de motifs de boucle
    test_loop_pattern_detection(&mut predictor);

    // Test 3: Fusion de branchements
    test_branch_fusion(&mut predictor);

    // Test 4: Performance sur des séquences aléatoires
    test_random_sequences(&mut predictor);

    // Test 5: Benchmark de performance
    benchmark_performance();
}

/// Test de base pour la prédiction et l'apprentissage
fn test_basic_prediction(predictor: &mut TernaryBranchPredictor) {
    println!("Test 1: Prédiction de base et apprentissage");
    println!("------------------------------------------");

    // Adresse de test pour le branchement
    let branch_addr = 0x1000;

    // Séquence de résultats: N, N, Z, P, N, N, Z, P, ...
    let sequence = [Trit::N, Trit::N, Trit::Z, Trit::P];
    let iterations = 5;

    println!("Séquence de test: N, N, Z, P (répétée {} fois)", iterations);
    println!("Prédictions et résultats:");

    let mut correct_predictions = 0;
    let total_predictions = sequence.len() * iterations;

    for i in 0..iterations {
        for (j, &result) in sequence.iter().enumerate() {
            // Prédire le résultat
            let prediction = predictor.predict(branch_addr);
            
            // Convertir la prédiction en Trit pour comparaison
            let predicted_trit = match prediction {
                BranchPrediction::Negative => Trit::N,
                BranchPrediction::Neutral => Trit::Z,
                BranchPrediction::Positive => Trit::P,
                BranchPrediction::Speculative => Trit::Z, // Par défaut
            };

            // Vérifier si la prédiction est correcte
            let is_correct = predicted_trit == result;
            if is_correct {
                correct_predictions += 1;
            }

            // Afficher les résultats
            println!("Itération {}, Étape {}: Prédit {:?}, Réel {:?}, {}", 
                     i+1, j+1, predicted_trit, result, 
                     if is_correct { "Correct" } else { "Incorrect" });

            // Mettre à jour le prédicteur avec le résultat réel
            predictor.update(branch_addr, result);
        }
    }

    // Calculer et afficher la précision
    let accuracy = (correct_predictions as f64 / total_predictions as f64) * 100.0;
    println!("\nPrécision: {:.2}% ({} correctes sur {})", accuracy, correct_predictions, total_predictions);
    println!("\nStatistiques du prédicteur:");
    let (total, correct, per_instr, global, local, acc) = predictor.get_stats();
    println!("Total des prédictions: {}", total);
    println!("Prédictions correctes: {}", correct);
    println!("Taux de succès par instruction: {}", per_instr);
    println!("Taux de succès global: {}", global);
    println!("Taux de succès local: {}", local);
    println!("Précision globale: {:.2}%", acc * 100.0);
    println!("");
}

/// Test de détection de motifs de boucle
fn test_loop_pattern_detection(predictor: &mut TernaryBranchPredictor) {
    println!("Test 2: Détection de motifs de boucle");
    println!("----------------------------------");

    // Réinitialiser les statistiques
    predictor.reset_stats();

    // Adresse de test pour le branchement
    let branch_addr = 0x2000;

    // Motif de boucle: N, Z, P, N, Z, P, ...
    let loop_pattern = [Trit::N, Trit::Z, Trit::P];
    let iterations = 10;

    println!("Motif de boucle: N, Z, P (répété {} fois)", iterations);
    println!("Prédictions et résultats:");

    // Phase d'apprentissage: entraîner le prédicteur avec le motif
    println!("\nPhase d'apprentissage:");
    for _ in 0..3 {
        for (i, &result) in loop_pattern.iter().enumerate() {
            predictor.update(branch_addr, result);
            println!("Étape {}: Mise à jour avec {:?}", i+1, result);
        }
    }

    // Phase de test: vérifier si le prédicteur a appris le motif
    println!("\nPhase de test:");
    let mut correct_predictions = 0;
    let total_predictions = loop_pattern.len() * iterations;

    for i in 0..iterations {
        for (j, &result) in loop_pattern.iter().enumerate() {
            // Prédire le résultat
            let prediction = predictor.predict(branch_addr);
            
            // Convertir la prédiction en Trit pour comparaison
            let predicted_trit = match prediction {
                BranchPrediction::Negative => Trit::N,
                BranchPrediction::Neutral => Trit::Z,
                BranchPrediction::Positive => Trit::P,
                BranchPrediction::Speculative => Trit::Z, // Par défaut
            };

            // Vérifier si la prédiction est correcte
            let is_correct = predicted_trit == result;
            if is_correct {
                correct_predictions += 1;
            }

            // Afficher les résultats
            println!("Itération {}, Étape {}: Prédit {:?}, Réel {:?}, {}", 
                     i+1, j+1, predicted_trit, result, 
                     if is_correct { "Correct" } else { "Incorrect" });

            // Mettre à jour le prédicteur avec le résultat réel
            predictor.update(branch_addr, result);
        }
    }

    // Calculer et afficher la précision
    let accuracy = (correct_predictions as f64 / total_predictions as f64) * 100.0;
    println!("\nPrécision après apprentissage: {:.2}% ({} correctes sur {})", 
             accuracy, correct_predictions, total_predictions);
    println!("");
}

/// Test de fusion de branchements
fn test_branch_fusion(predictor: &mut TernaryBranchPredictor) {
    println!("Test 3: Fusion de branchements");
    println!("----------------------------");

    // Réinitialiser les statistiques
    predictor.reset_stats();

    // Adresses de test pour les branchements à fusionner
    let branch_addr1 = 0x3000;
    let branch_addr2 = 0x3020; // Proche du premier
    let branch_addr3 = 0x3040; // Proche des deux premiers

    // Séquences de résultats pour chaque branchement
    let sequence1 = [Trit::N, Trit::Z, Trit::N, Trit::Z];
    let sequence2 = [Trit::Z, Trit::P, Trit::Z, Trit::P];
    let sequence3 = [Trit::P, Trit::N, Trit::P, Trit::N];

    println!("Branchements à fusionner: 0x{:X}, 0x{:X}, 0x{:X}", branch_addr1, branch_addr2, branch_addr3);

    // Phase d'apprentissage: entraîner le prédicteur avec les séquences individuelles
    println!("\nPhase d'apprentissage individuelle:");
    for _ in 0..5 {
        for &result in &sequence1 {
            predictor.update(branch_addr1, result);
        }
        for &result in &sequence2 {
            predictor.update(branch_addr2, result);
        }
        for &result in &sequence3 {
            predictor.update(branch_addr3, result);
        }
    }

    // Fusionner les branchements
    println!("\nFusion des branchements...");
    predictor.merge_branches(&[branch_addr1, branch_addr2, branch_addr3]);

    // Phase de test après fusion
    println!("\nPhase de test après fusion:");
    
    // Tester avec les séquences originales
    let mut correct_predictions = 0;
    let total_predictions = sequence1.len() + sequence2.len() + sequence3.len();

    println!("\nTest sur le branchement 1 (0x{:X}):", branch_addr1);
    for (i, &result) in sequence1.iter().enumerate() {
        let prediction = predictor.predict(branch_addr1);
        let predicted_trit = match prediction {
            BranchPrediction::Negative => Trit::N,
            BranchPrediction::Neutral => Trit::Z,
            BranchPrediction::Positive => Trit::P,
            BranchPrediction::Speculative => Trit::Z,
        };
        let is_correct = predicted_trit == result;
        if is_correct {
            correct_predictions += 1;
        }
        println!("Étape {}: Prédit {:?}, Réel {:?}, {}", 
                 i+1, predicted_trit, result, 
                 if is_correct { "Correct" } else { "Incorrect" });
        predictor.update(branch_addr1, result);
    }

    println!("\nTest sur le branchement 2 (0x{:X}):", branch_addr2);
    for (i, &result) in sequence2.iter().enumerate() {
        let prediction = predictor.predict(branch_addr2);
        let predicted_trit = match prediction {
            BranchPrediction::Negative => Trit::N,
            BranchPrediction::Neutral => Trit::Z,
            BranchPrediction::Positive => Trit::P,
            BranchPrediction::Speculative => Trit::Z,
        };
        let is_correct = predicted_trit == result;
        if is_correct {
            correct_predictions += 1;
        }
        println!("Étape {}: Prédit {:?}, Réel {:?}, {}", 
                 i+1, predicted_trit, result, 
                 if is_correct { "Correct" } else { "Incorrect" });
        predictor.update(branch_addr2, result);
    }

    println!("\nTest sur le branchement 3 (0x{:X}):", branch_addr3);
    for (i, &result) in sequence3.iter().enumerate() {
        let prediction = predictor.predict(branch_addr3);
        let predicted_trit = match prediction {
            BranchPrediction::Negative => Trit::N,
            BranchPrediction::Neutral => Trit::Z,
            BranchPrediction::Positive => Trit::P,
            BranchPrediction::Speculative => Trit::Z,
        };
        let is_correct = predicted_trit == result;
        if is_correct {
            correct_predictions += 1;
        }
        println!("Étape {}: Prédit {:?}, Réel {:?}, {}", 
                 i+1, predicted_trit, result, 
                 if is_correct { "Correct" } else { "Incorrect" });
        predictor.update(branch_addr3, result);
    }

    // Calculer et afficher la précision
    let accuracy = (correct_predictions as f64 / total_predictions as f64) * 100.0;
    println!("\nPrécision après fusion: {:.2}% ({} correctes sur {})", 
             accuracy, correct_predictions, total_predictions);
    println!("");
}

/// Test avec des séquences aléatoires
fn test_random_sequences(predictor: &mut TernaryBranchPredictor) {
    println!("Test 4: Performance sur des séquences aléatoires");
    println!("---------------------------------------------");

    // Réinitialiser les statistiques
    predictor.reset_stats();

    // Adresse de test pour le branchement
    let branch_addr = 0x4000;

    // Générer une séquence aléatoire de résultats
    let mut sequence = Vec::with_capacity(100);
    for _ in 0..100 {
        let random_value = rand::random::<u8>() % 3;
        let trit = match random_value {
            0 => Trit::N,
            1 => Trit::Z,
            _ => Trit::P,
        };
        sequence.push(trit);
    }

    println!("Séquence aléatoire de 100 résultats générée");

    // Phase d'apprentissage
    println!("\nPhase d'apprentissage (50 premiers résultats):");
    for (i, &result) in sequence.iter().take(50).enumerate() {
        predictor.update(branch_addr, result);
        if i % 10 == 0 {
            println!("Mise à jour avec les résultats {} à {}", i+1, i+10);
        }
    }

    // Phase de test
    println!("\nPhase de test (50 résultats suivants):");
    let mut correct_predictions = 0;
    let total_predictions = 50;

    for (i, &result) in sequence.iter().skip(50).take(50).enumerate() {
        // Prédire le résultat
        let prediction = predictor.predict(branch_addr);
        
        // Convertir la prédiction en Trit pour comparaison
        let predicted_trit = match prediction {
            BranchPrediction::Negative => Trit::N,
            BranchPrediction::Neutral => Trit::Z,
            BranchPrediction::Positive => Trit::P,
            BranchPrediction::Speculative => Trit::Z, // Par défaut
        };

        // Vérifier si la prédiction est correcte
        let is_correct = predicted_trit == result;
        if is_correct {
            correct_predictions += 1;
        }

        // Afficher les résultats tous les 10 tests
        if i % 10 == 0 {
            // Calculer le nombre de prédictions correctes dans ce groupe de 10
            let correct_in_group = if i > 0 {
                correct_predictions - (i / 10) * 10
            } else {
                correct_predictions.min(10)
            };
            println!("Tests {} à {}: {} correctes", i+1, i+10.min(50), correct_in_group);
        }

        // Mettre à jour le prédicteur avec le résultat réel
        predictor.update(branch_addr, result);
    }

    // Calculer et afficher la précision
    let accuracy = (correct_predictions as f64 / total_predictions as f64) * 100.0;
    println!("\nPrécision sur séquence aléatoire: {:.2}% ({} correctes sur {})", 
             accuracy, correct_predictions, total_predictions);
    
    // Afficher les statistiques du prédicteur
    println!("\nStatistiques du prédicteur:");
    let (total, correct, per_instr, global, local, acc) = predictor.get_stats();
    println!("Total des prédictions: {}", total);
    println!("Prédictions correctes: {}", correct);
    println!("Taux de succès par instruction: {}", per_instr);
    println!("Taux de succès global: {}", global);
    println!("Taux de succès local: {}", local);
    println!("Précision globale: {:.2}%", acc * 100.0);
    println!("");
}

/// Benchmark de performance
fn benchmark_performance() {
    println!("Test 5: Benchmark de performance");
    println!("------------------------------");

    // Créer des prédicteurs de différentes tailles
    let sizes = [16, 64, 256, 1024];
    
    for &size in &sizes {
        println!("\nTest avec un prédicteur de taille {}", size);
        let mut predictor = TernaryBranchPredictor::new(size);
        
        // Générer des adresses de branchement aléatoires
        let mut branch_addresses = Vec::with_capacity(1000);
        for _ in 0..1000 {
            branch_addresses.push(rand::random::<u32>() % 10000);
        }
        
        // Générer des résultats aléatoires
        let mut results = Vec::with_capacity(10000);
        for _ in 0..10000 {
            let random_value = rand::random::<u8>() % 3;
            let trit = match random_value {
                0 => Trit::N,
                1 => Trit::Z,
                _ => Trit::P,
            };
            results.push(trit);
        }
        
        // Mesurer le temps pour 10000 prédictions et mises à jour
        let start_time = Instant::now();
        
        let mut correct_predictions = 0;
        for i in 0..10000 {
            let addr = branch_addresses[i % 1000];
            let result = results[i];
            
            // Prédire
            let prediction = predictor.predict(addr);
            let predicted_trit = match prediction {
                BranchPrediction::Negative => Trit::N,
                BranchPrediction::Neutral => Trit::Z,
                BranchPrediction::Positive => Trit::P,
                BranchPrediction::Speculative => Trit::Z,
            };
            
            if predicted_trit == result {
                correct_predictions += 1;
            }
            
            // Mettre à jour
            predictor.update(addr, result);
        }
        
        let elapsed = start_time.elapsed();
        let accuracy = (correct_predictions as f64 / 10000.0) * 100.0;
        
        println!("Temps pour 10000 prédictions et mises à jour: {:?}", elapsed);
        println!("Précision: {:.2}% ({} correctes sur 10000)", accuracy, correct_predictions);
        println!("Prédictions par seconde: {:.2}", 10000.0 / elapsed.as_secs_f64());
    }
}