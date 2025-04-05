// src/bin/test_load_store.rs
// Programme de test pour les instructions Load/Store - Sprint 7
// Ce programme teste les opérations de chargement et stockage en mémoire

use prismchrono_sim::core::{Trit, Tryte, Word};
use prismchrono_sim::cpu::execute::Cpu;
use prismchrono_sim::cpu::execute_mem::MemoryOperations;
use prismchrono_sim::cpu::isa::{Instruction, Opcode};
use prismchrono_sim::cpu::registers::Register;
use prismchrono_sim::memory::Memory;

fn main() {
    println!("🏳️‍🌈 Architecture PrismChrono - Test des instructions Load/Store (Sprint 7)");
    println!("---------------------------------------------");

    // Créer un CPU avec une petite mémoire pour les tests
    let mut cpu = Cpu::with_memory_size(1024);
    println!("CPU créé avec {} trytes de mémoire", cpu.memory.size());

    // Initialiser quelques valeurs en mémoire pour les tests
    println!("\nInitialisation de la mémoire avec des valeurs de test...");

    // Adresse alignée pour un mot (multiple de 8)
    let word_addr = 64;
    let test_word = Word([
        Tryte::Digit(14), // 1 en ternaire équilibré
        Tryte::Digit(15), // 2 en ternaire équilibré
        Tryte::Digit(16), // 3 en ternaire équilibré
        Tryte::Digit(17), // 4 en ternaire équilibré
        Tryte::Digit(18), // 5 en ternaire équilibré
        Tryte::Digit(19), // 6 en ternaire équilibré
        Tryte::Digit(20), // 7 en ternaire équilibré
        Tryte::Digit(21), // 8 en ternaire équilibré
    ]);

    // Écrire le mot en mémoire
    cpu.memory
        .write_word(word_addr, test_word)
        .expect("Erreur d'écriture en mémoire");
    println!(
        "Mot de test écrit à l'adresse {}: {:?}",
        word_addr, test_word
    );

    // Adresse pour un tryte individuel
    let tryte_addr = 128;
    let test_tryte = Tryte::Digit(22); // 9 en ternaire équilibré

    // Écrire le tryte en mémoire
    cpu.memory
        .write_tryte(tryte_addr, test_tryte)
        .expect("Erreur d'écriture en mémoire");
    println!(
        "Tryte de test écrit à l'adresse {}: {:?}",
        tryte_addr, test_tryte
    );

    // Initialiser les registres avec des adresses
    println!("\nInitialisation des registres...");

    // R1 contiendra l'adresse du mot
    let mut r1_word = Word::zero();
    if let Some(tryte) = r1_word.tryte_mut(0) {
        *tryte = Tryte::Digit((13 + word_addr).try_into().unwrap()); // Adresse en ternaire équilibré
    }
    cpu.state.write_gpr(Register::R1, r1_word);
    println!("R1 initialisé avec l'adresse {}", word_addr);

    // R2 contiendra l'adresse du tryte
    let mut r2_word = Word::zero();
    if let Some(tryte) = r2_word.tryte_mut(0) {
        *tryte = Tryte::Digit((13 + tryte_addr).try_into().unwrap()); // Adresse en ternaire équilibré
    }
    cpu.state.write_gpr(Register::R2, r2_word);
    println!("R2 initialisé avec l'adresse {}", tryte_addr);

    // Test 1: LOADW - Chargement d'un mot
    println!("\nTest 1: LOADW R3, 0(R1) - Chargement d'un mot");
    match cpu.execute(Instruction::Load {
        rd: Register::R3,
        rs1: Register::R1,
        offset: 0,
    }) {
        Ok(_) => {
            let result = cpu.state.read_gpr(Register::R3);
            println!("  Instruction exécutée avec succès.");
            println!("  R3 = {:?}", result);

            // Vérifier que le résultat est correct
            if result == test_word {
                println!("  ✅ Test réussi: Le mot chargé correspond à la valeur attendue.");
            } else {
                println!("  ❌ Test échoué: Le mot chargé ne correspond pas à la valeur attendue.");
            }
        }
        Err(e) => {
            println!("  ❌ Erreur lors de l'exécution: {:?}", e);
        }
    }

    // Test 2: STOREW - Stockage d'un mot
    println!("\nTest 2: STOREW R1, R3, 8 - Stockage d'un mot avec offset");
    match cpu.execute(Instruction::Store {
        rs1: Register::R1,
        rs2: Register::R3,
        offset: 8,
    }) {
        Ok(_) => {
            println!("  Instruction exécutée avec succès.");

            // Vérifier que le mot a bien été stocké
            match cpu.memory.read_word(word_addr + 8) {
                Ok(stored_word) => {
                    println!(
                        "  Mot stocké à l'adresse {}: {:?}",
                        word_addr + 8,
                        stored_word
                    );

                    if stored_word == test_word {
                        println!(
                            "  ✅ Test réussi: Le mot stocké correspond à la valeur attendue."
                        );
                    } else {
                        println!(
                            "  ❌ Test échoué: Le mot stocké ne correspond pas à la valeur attendue."
                        );
                    }
                }
                Err(e) => {
                    println!("  ❌ Erreur lors de la lecture: {:?}", e);
                }
            }
        }
        Err(e) => {
            println!("  ❌ Erreur lors de l'exécution: {:?}", e);
        }
    }

    // Test 3: LOADT - Chargement d'un tryte avec extension de signe
    println!("\nTest 3: LOADT R4, 0(R2) - Chargement d'un tryte avec extension de signe");
    // Note: Cette instruction n'est pas directement disponible dans l'enum Instruction,
    // nous utilisons donc une fonction spécifique pour la tester
    match cpu.execute_load_tryte(Register::R4, Register::R2, 0) {
        Ok(_) => {
            let result = cpu.state.read_gpr(Register::R4);
            println!("  Instruction exécutée avec succès.");
            println!("  R4 = {:?}", result);

            // Vérifier que le premier tryte est correct
            if let Some(tryte) = result.tryte(0) {
                if *tryte == test_tryte {
                    println!("  ✅ Test réussi: Le premier tryte correspond à la valeur attendue.");
                } else {
                    println!(
                        "  ❌ Test échoué: Le premier tryte ne correspond pas à la valeur attendue."
                    );
                }
            }

            // Vérifier l'extension de signe
            if let Some(tryte) = result.tryte(7) {
                println!("  Tryte de poids fort (extension de signe): {:?}", tryte);
            }
        }
        Err(e) => {
            println!("  ❌ Erreur lors de l'exécution: {:?}", e);
        }
    }

    // Test 4: LOADTU - Chargement d'un tryte sans extension de signe
    println!("\nTest 4: LOADTU R5, 0(R2) - Chargement d'un tryte sans extension de signe");
    match cpu.execute_load_tryte_unsigned(Register::R5, Register::R2, 0) {
        Ok(_) => {
            let result = cpu.state.read_gpr(Register::R5);
            println!("  Instruction exécutée avec succès.");
            println!("  R5 = {:?}", result);

            // Vérifier que le premier tryte est correct
            if let Some(tryte) = result.tryte(0) {
                if *tryte == test_tryte {
                    println!("  ✅ Test réussi: Le premier tryte correspond à la valeur attendue.");
                } else {
                    println!(
                        "  ❌ Test échoué: Le premier tryte ne correspond pas à la valeur attendue."
                    );
                }
            }

            // Vérifier l'extension avec des zéros
            if let Some(tryte) = result.tryte(7) {
                if *tryte == Tryte::Digit(13) {
                    // 0 en ternaire équilibré
                    println!("  ✅ Test réussi: Extension avec des zéros correcte.");
                } else {
                    println!("  ❌ Test échoué: Extension avec des zéros incorrecte.");
                }
            }
        }
        Err(e) => {
            println!("  ❌ Erreur lors de l'exécution: {:?}", e);
        }
    }

    // Test 5: STORET - Stockage d'un tryte
    println!("\nTest 5: STORET R2, R5, 1 - Stockage d'un tryte avec offset");
    match cpu.execute_store_tryte(Register::R2, Register::R5, 1) {
        Ok(_) => {
            println!("  Instruction exécutée avec succès.");

            // Vérifier que le tryte a bien été stocké
            match cpu.memory.read_tryte(tryte_addr + 1) {
                Ok(stored_tryte) => {
                    println!(
                        "  Tryte stocké à l'adresse {}: {:?}",
                        tryte_addr + 1,
                        stored_tryte
                    );

                    if stored_tryte == test_tryte {
                        println!(
                            "  ✅ Test réussi: Le tryte stocké correspond à la valeur attendue."
                        );
                    } else {
                        println!(
                            "  ❌ Test échoué: Le tryte stocké ne correspond pas à la valeur attendue."
                        );
                    }
                }
                Err(e) => {
                    println!("  ❌ Erreur lors de la lecture: {:?}", e);
                }
            }
        }
        Err(e) => {
            println!("  ❌ Erreur lors de l'exécution: {:?}", e);
        }
    }

    // Test 6: Erreur d'alignement
    println!("\nTest 6: LOADW R3, 1(R1) - Test d'erreur d'alignement");
    match cpu.execute(Instruction::Load {
        rd: Register::R3,
        rs1: Register::R1,
        offset: 1,
    }) {
        Ok(_) => {
            println!("  ❌ Test échoué: L'instruction aurait dû générer une erreur d'alignement.");
        }
        Err(e) => {
            println!("  Erreur lors de l'exécution: {:?}", e);
            println!("  ✅ Test réussi: L'erreur d'alignement a bien été détectée.");
        }
    }

    println!("\n---------------------------------------------");
    println!("Tests des instructions Load/Store terminés.");
}
