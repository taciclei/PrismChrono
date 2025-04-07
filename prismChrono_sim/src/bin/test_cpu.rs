// src/bin/test_cpu.rs
// Programme de test pour le CPU - Sprint 6
// Ce programme charge manuellement un code machine minimal avec NOP et HALT
// et exécute le cycle fetch-decode-execute

use prismchrono_sim::core::{Trit, Tryte, Word};
use prismchrono_sim::cpu::execute::Cpu;

fn main() {
    println!("🏳️‍🌈 Architecture PrismChrono - Test du CPU (Sprint 6)");
    println!("---------------------------------------------");

    // Créer un CPU avec une petite mémoire pour les tests
    let mut cpu = Cpu::with_memory_size(1024);
    println!("CPU créé avec {} trytes de mémoire", cpu.memory.size());

    // Adresse de début du programme
    let start_addr = 0;

    // Programme machine minimal : NOP, NOP, HALT
    // Chaque instruction fait 4 trytes (12 trits)

    // Instruction 1: NOP (opcode System, func=1)
    // Format: [opcode(3t) | func(9t)]
    // Opcode System = [P, P, P] (selon l'encodage défini dans isa.rs)
    // Func NOP = 1 = [P, Z, Z] (les 3 premiers trits, le reste à Z)
    let nop_trytes = [
        Tryte::from_trits([Trit::P, Trit::P, Trit::P]), // Opcode System
        Tryte::from_trits([Trit::P, Trit::Z, Trit::Z]), // Func NOP (1)
        Tryte::from_trits([Trit::Z, Trit::Z, Trit::Z]), // Padding
        Tryte::from_trits([Trit::Z, Trit::Z, Trit::Z]), // Padding
    ];

    // Instruction 2: NOP (répétition)

    // Instruction 3: HALT (opcode System, func=0)
    // Format: [opcode(3t) | func(9t)]
    // Opcode System = [P, P, P]
    // Func HALT = 0 = [Z, Z, Z] (les 3 premiers trits, le reste à Z)
    let halt_trytes = [
        Tryte::from_trits([Trit::P, Trit::P, Trit::P]), // Opcode System
        Tryte::from_trits([Trit::Z, Trit::Z, Trit::Z]), // Func HALT (0)
        Tryte::from_trits([Trit::Z, Trit::Z, Trit::Z]), // Padding
        Tryte::from_trits([Trit::Z, Trit::Z, Trit::Z]), // Padding
    ];

    // Charger le programme en mémoire
    println!(
        "Chargement du programme en mémoire à l'adresse {}",
        start_addr
    );

    // Charger NOP 1
    for i in 0..4 {
        cpu.memory
            .write_tryte(start_addr + i, nop_trytes[i])
            .expect("Erreur d'écriture en mémoire");
    }

    // Charger NOP 2
    for i in 0..4 {
        cpu.memory
            .write_tryte(start_addr + 4 + i, nop_trytes[i])
            .expect("Erreur d'écriture en mémoire");
    }

    // Charger HALT
    for i in 0..4 {
        cpu.memory
            .write_tryte(start_addr + 8 + i, halt_trytes[i])
            .expect("Erreur d'écriture en mémoire");
    }

    println!("Programme chargé: 2 x NOP, 1 x HALT");

    // Initialiser le PC à l'adresse de début du programme
    let mut pc_word = Word::zero();
    if let Some(tryte) = pc_word.tryte_mut(0) {
        *tryte = Tryte::Digit(13); // 0 en ternaire équilibré
    }
    cpu.state.write_pc(pc_word);

    println!("PC initialisé à l'adresse {}", start_addr);
    println!("---------------------------------------------");
    println!("Exécution du programme:");

    // Exécuter le programme instruction par instruction pour voir le déroulement
    let mut step_count = 0;

    while !cpu.halted {
        let pc_before = cpu.state.read_pc();
        println!("Étape {}: PC = {}", step_count, pc_before);

        match cpu.step() {
            Ok(_) => {
                let pc_after = cpu.state.read_pc();
                println!(
                    "  Instruction exécutée avec succès. Nouveau PC = {}",
                    pc_after
                );
            }
            Err(e) => {
                println!("  Erreur lors de l'exécution: {:?}", e);
                break;
            }
        }

        step_count += 1;

        // Sécurité pour éviter une boucle infinie
        if step_count > 10 {
            println!("Nombre maximum d'étapes atteint. Arrêt forcé.");
            break;
        }
    }

    println!("---------------------------------------------");
    if cpu.halted {
        println!("Programme terminé normalement (HALT atteint).");
    } else {
        println!("Programme terminé avec erreur ou interruption.");
    }
    println!("Nombre total d'instructions exécutées: {}", step_count);
}
