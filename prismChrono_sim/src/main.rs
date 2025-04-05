// src/main.rs

// Déclare les modules que nous allons utiliser
mod alu;
mod core;
mod cpu;
mod memory;

// Importe les types et fonctions nécessaires depuis nos modules
use crate::alu::{ternary_full_adder, trit_inv_word, trit_max_word, trit_min_word};
use crate::core::{Address, Trit, Tryte, Word, is_valid_address};
use crate::cpu::registers::RegisterError; // Importe RegisterError depuis le module registers
use crate::cpu::{Flags, ProcessorState, Register}; // Importe les types du CPU
use crate::memory::{Memory, MemoryError}; // Importe Memory et son type d'erreur // Importe les fonctions de l'ALU

fn main() {
    // Affiche un message de démarrage sympa avec le nom de l'architecture
    println!("🏳️\u{200d}🌈 Architecture PrismChrono Simulator - Starting!");
    println!("---------------------------------------------");
    println!("Architecture: Logic GPR Base-24 Ternary +");
    println!("Word Size: 24 Trits (8 Trytes)");
    println!(
        "Addressable Memory: 16 MTrytes ({} trytes)",
        core::MAX_ADDRESS
    );
    println!("Endianness: Little-Endian");
    println!("---------------------------------------------");

    // --- Section de Test des Types (Optionnel, mais utile au début) ---
    println!("\n[Type Sanity Checks]");
    let trit_n = Trit::N;
    let trit_p = trit_n.inv();
    println!("  Trit N: {}, Inverted: {}", trit_n, trit_p);
    println!("  Trit P value: {}", trit_p.value());

    let tryte_5 = Tryte::Digit(5);
    let tryte_undef = Tryte::Undefined;
    println!("  Tryte 5: {}, Bal3: {}", tryte_5, tryte_5.bal3_value());
    println!(
        "  Tryte UNDEF: {}, Bal3: {}",
        tryte_undef,
        tryte_undef.bal3_value()
    );

    let trits_for_5 = tryte_5.to_trits();
    // Affichage T2:T1:T0
    println!(
        "  Trits for 5 (T2:T1:T0): {}:{}:{}",
        trits_for_5[2], trits_for_5[1], trits_for_5[0]
    );
    let tryte_from_trits = Tryte::from_trits(trits_for_5);
    println!("  Tryte reconstructed from trits: {}", tryte_from_trits);

    let word_zero = Word::zero();
    let mut word_default = Word::default(); // Devrait être 8x UNDEF
    println!("  Word Zero (8 Trytes 'D'=13): {}", word_zero);
    println!("  Word Default (8 Trytes 'UND'): {}", word_default);

    if let Some(tryte) = word_default.tryte_mut(0) {
        // Accès au Tryte de poids faible (index 0)
        *tryte = Tryte::Digit(23); // 'N'
    }
    if let Some(tryte) = word_default.tryte_mut(7) {
        // Accès au Tryte de poids fort (index 7)
        *tryte = Tryte::Digit(0); // '0'
    }
    println!("  Word Modified (T7='0', T0='N'): {}", word_default);

    let addr1: Address = 100;
    let addr2: Address = 20_000_000; // Adresse hors limites
    println!("  Address {} valid: {}", addr1, is_valid_address(addr1));
    println!("  Address {} valid: {}", addr2, is_valid_address(addr2));
    println!("---------------------------------------------");

    // --- Section de Test de la Mémoire ---
    println!("\n[Memory Subsystem Tests]");
    // Crée une petite mémoire pour les tests (plus rapide qu'utiliser MAX_ADDRESS)
    let mut mem = Memory::with_size(1024); // 1K trytes
    println!("  Created memory with {} trytes", mem.size());

    // Test d'écriture/lecture de trytes
    let test_addr: Address = 42;
    let test_tryte = Tryte::Digit(7);
    match mem.write_tryte(test_addr, test_tryte) {
        Ok(_) => println!("  Write tryte at address {} succeeded", test_addr),
        Err(e) => println!("  Write tryte failed: {:?}", e),
    }

    match mem.read_tryte(test_addr) {
        Ok(tryte) => println!("  Read tryte from address {}: {}", test_addr, tryte),
        Err(e) => println!("  Read tryte failed: {:?}", e),
    }

    // Test d'écriture/lecture de mots
    let word_addr: Address = 64; // Doit être multiple de 8 pour l'alignement
    let test_word = Word([
        Tryte::Digit(1),
        Tryte::Digit(2),
        Tryte::Digit(3),
        Tryte::Digit(4),
        Tryte::Digit(5),
        Tryte::Digit(6),
        Tryte::Digit(7),
        Tryte::Digit(8),
    ]);

    match mem.write_word(word_addr, test_word) {
        Ok(_) => println!("  Write word at address {} succeeded", word_addr),
        Err(e) => println!("  Write word failed: {:?}", e),
    }

    match mem.read_word(word_addr) {
        Ok(word) => println!("  Read word from address {}: {}", word_addr, word),
        Err(e) => println!("  Read word failed: {:?}", e),
    }

    // Test d'erreur d'alignement
    let misaligned_addr: Address = 66; // Non multiple de 8
    match mem.read_word(misaligned_addr) {
        Ok(_) => println!(
            "  Read word from misaligned address {} succeeded (unexpected)",
            misaligned_addr
        ),
        Err(e) => println!(
            "  Read word from misaligned address {} failed as expected: {:?}",
            misaligned_addr, e
        ),
    }

    // Test d'erreur de limite
    let out_of_bounds_addr: Address = 2000; // Au-delà de la taille (1024)
    match mem.read_tryte(out_of_bounds_addr) {
        Ok(_) => println!(
            "  Read tryte from OOB address {} succeeded (unexpected)",
            out_of_bounds_addr
        ),
        Err(e) => println!(
            "  Read tryte from OOB address {} failed as expected: {:?}",
            out_of_bounds_addr, e
        ),
    }

    // --- Section de Test du Processeur ---
    println!("\n[Processor State Tests]");
    // Crée un nouvel état de processeur
    let mut proc_state = ProcessorState::new();
    println!("  Created new processor state");

    // Test des registres généraux
    let r3 = Register::R3;
    let test_reg_value = Word([Tryte::Digit(5); 8]);
    proc_state.write_gpr(r3, test_reg_value.clone());
    println!("  Write to register {}: {}", r3, test_reg_value);

    let read_value = proc_state.read_gpr(r3);
    println!("  Read from register {}: {}", r3, read_value);

    // Test du PC et SP
    let pc_value = Word([Tryte::Digit(10); 8]);
    proc_state.write_pc(pc_value.clone());
    println!("  Set PC to: {}", pc_value);
    println!("  Current PC: {}", proc_state.read_pc());

    let sp_value = Word([Tryte::Digit(20); 8]);
    proc_state.write_sp(sp_value.clone());
    println!("  Set SP to: {}", sp_value);
    println!("  Current SP: {}", proc_state.read_sp());

    // Test des flags
    let mut flags = Flags::new();
    println!("  Initial flags: {}", flags);

    flags.zf = true;
    flags.sf = false;
    flags.xf = true;
    proc_state.write_flags(flags);
    println!("  Updated flags: {}", proc_state.read_flags());

    proc_state.reset_flags();
    println!("  After reset flags: {}", proc_state.read_flags());

    // Test de conversion d'index de registre
    println!("\n  Register index conversions:");
    for i in 0..8 {
        match Register::from_index(i) {
            Ok(reg) => println!("    Index {} -> Register {}", i, reg),
            Err(e) => println!("    Index {} -> Error: {:?}", i, e),
        }
    }
    match Register::from_index(8) {
        Ok(reg) => println!("    Index 8 -> Register {} (unexpected)", reg),
        Err(e) => println!("    Index 8 -> Error: {:?} (expected)", e),
    }

    println!("---------------------------------------------");
    println!("[Simulator Setup Complete - Ready for CPU/ALU implementation]");
}
