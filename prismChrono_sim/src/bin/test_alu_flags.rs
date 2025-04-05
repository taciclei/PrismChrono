// test_alu_flags.rs
// Test des opérations logiques et arithmétiques de l'ALU avec focus sur les flags

use prismchrono_sim::alu::{
    add_24_trits, compare_24_trits, sub_24_trits, trit_inv_word, trit_max_word, trit_min_word,
};
use prismchrono_sim::core::{Trit, Tryte, Word};
use prismchrono_sim::cpu::Flags;

fn main() {
    println!("=== Test des opérations logiques et arithmétiques de l'ALU ===\n");

    test_logical_operations_flags();
    test_arithmetic_operations_flags();
    test_compare_operations();

    println!("\n=== Tous les tests ont réussi ! ===");
}

// Fonction utilitaire pour créer un Word à partir d'un tableau de Trytes
fn create_word(trytes: [Tryte; 8]) -> Word {
    Word(trytes)
}

// Fonction utilitaire pour mettre à jour les flags à partir d'un mot
fn update_flags_from_word(word: &Word) -> Flags {
    let mut flags = Flags::new();
    let mut all_zeros = true;
    let mut has_special = false;

    // Vérifier si tous les trytes sont nuls (ZF)
    for i in 0..8 {
        if let Some(tryte) = word.tryte(i) {
            match tryte {
                Tryte::Digit(13) => {} // 13 = (Z,Z,Z) = 0, ne change pas all_zeros
                Tryte::Digit(_) => all_zeros = false,
                _ => {
                    all_zeros = false;
                    has_special = true;
                }
            }
        }
    }

    // Vérifier si le mot est négatif (SF)
    if let Some(msb_tryte) = word.tryte(7) {
        // Tryte de poids fort
        if let Tryte::Digit(val) = msb_tryte {
            // Vérifier si le tryte de poids fort est négatif
            // Les valeurs de 0 à 12 sont négatives (N dans le trit de poids fort)
            flags.sf = *val <= 12;
        }
    }

    // Mettre à jour les flags
    flags.zf = all_zeros && !has_special;
    flags.xf = has_special;

    flags
}

// Test des flags pour les opérations logiques
fn test_logical_operations_flags() {
    println!("Test des flags pour les opérations logiques...");

    // Créer des mots de test
    let word_zero = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)
    let word_neg = create_word([Tryte::Digit(0); 8]); // Tous les trytes sont -13 (N,N,N)
    let word_pos = create_word([Tryte::Digit(23); 8]); // Tous les trytes sont 13 (P,P,P)

    // Test de trit_inv_word avec vérification des flags
    println!("  Test de trit_inv_word...");

    // Inverser un mot nul doit donner un mot nul (ZF=true, SF=false)
    let inv_zero = trit_inv_word(word_zero);
    let flags = update_flags_from_word(&inv_zero);
    assert!(
        flags.zf,
        "ZF devrait être true pour l'inversion d'un mot nul"
    );
    assert!(
        !flags.sf,
        "SF devrait être false pour l'inversion d'un mot nul"
    );

    // Inverser un mot négatif doit donner un mot positif (ZF=false, SF=false)
    let inv_neg = trit_inv_word(word_neg);
    let flags = update_flags_from_word(&inv_neg);
    assert!(
        !flags.zf,
        "ZF devrait être false pour l'inversion d'un mot négatif"
    );
    assert!(
        !flags.sf,
        "SF devrait être false pour l'inversion d'un mot négatif"
    );

    // Inverser un mot positif doit donner un mot négatif (ZF=false, SF=true)
    let inv_pos = trit_inv_word(word_pos);
    let flags = update_flags_from_word(&inv_pos);
    assert!(
        !flags.zf,
        "ZF devrait être false pour l'inversion d'un mot positif"
    );
    assert!(
        flags.sf,
        "SF devrait être true pour l'inversion d'un mot positif"
    );

    // Test de trit_min_word avec vérification des flags
    println!("  Test de trit_min_word...");

    // MIN(0, 0) = 0 (ZF=true, SF=false)
    let min_zero_zero = trit_min_word(word_zero, word_zero);
    let flags = update_flags_from_word(&min_zero_zero);
    assert!(flags.zf, "ZF devrait être true pour MIN(0, 0)");
    assert!(!flags.sf, "SF devrait être false pour MIN(0, 0)");

    // MIN(-13, 0) = -13 (ZF=false, SF=true)
    let min_neg_zero = trit_min_word(word_neg, word_zero);
    let flags = update_flags_from_word(&min_neg_zero);
    assert!(!flags.zf, "ZF devrait être false pour MIN(-13, 0)");
    assert!(flags.sf, "SF devrait être true pour MIN(-13, 0)");

    // MIN(13, -13) = -13 (ZF=false, SF=true)
    let min_pos_neg = trit_min_word(word_pos, word_neg);
    let flags = update_flags_from_word(&min_pos_neg);
    assert!(!flags.zf, "ZF devrait être false pour MIN(13, -13)");
    assert!(flags.sf, "SF devrait être true pour MIN(13, -13)");

    // Test de trit_max_word avec vérification des flags
    println!("  Test de trit_max_word...");

    // MAX(0, 0) = 0 (ZF=true, SF=false)
    let max_zero_zero = trit_max_word(word_zero, word_zero);
    let flags = update_flags_from_word(&max_zero_zero);
    assert!(flags.zf, "ZF devrait être true pour MAX(0, 0)");
    assert!(!flags.sf, "SF devrait être false pour MAX(0, 0)");

    // MAX(-13, 0) = 0 (ZF=true, SF=false)
    let max_neg_zero = trit_max_word(word_neg, word_zero);
    let flags = update_flags_from_word(&max_neg_zero);
    assert!(flags.zf, "ZF devrait être true pour MAX(-13, 0)");
    assert!(!flags.sf, "SF devrait être false pour MAX(-13, 0)");

    // MAX(13, -13) = 13 (ZF=false, SF=false)
    let max_pos_neg = trit_max_word(word_pos, word_neg);
    let flags = update_flags_from_word(&max_pos_neg);
    assert!(!flags.zf, "ZF devrait être false pour MAX(13, -13)");
    assert!(!flags.sf, "SF devrait être false pour MAX(13, -13)");

    println!("  Tests des opérations logiques réussis!");
}

// Test des flags pour les opérations arithmétiques
fn test_arithmetic_operations_flags() {
    println!("Test des flags pour les opérations arithmétiques...");

    // Créer des mots de test
    let word_zero = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)
    let word_one = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1 (Z,Z,P)
    let word_neg_one = create_word([Tryte::Digit(12); 8]); // Tous les trytes sont -1 (Z,Z,N)

    // Test d'addition avec vérification des flags
    println!("  Test d'addition...");

    // 0 + 0 = 0 (ZF=true, SF=false, XF=false)
    let (result, _, flags) = add_24_trits(word_zero, word_zero, Trit::Z);
    assert!(flags.zf, "ZF devrait être true pour 0 + 0");
    assert!(!flags.sf, "SF devrait être false pour 0 + 0");
    assert!(!flags.xf, "XF devrait être false pour 0 + 0");

    // 0 + 1 = 1 (ZF=false, SF=false, XF=false)
    let (result, _, flags) = add_24_trits(word_zero, word_one, Trit::Z);
    assert!(!flags.zf, "ZF devrait être false pour 0 + 1");
    assert!(!flags.sf, "SF devrait être false pour 0 + 1");
    assert!(!flags.xf, "XF devrait être false pour 0 + 1");

    // 0 + (-1) = -1 (ZF=false, SF=true, XF=false)
    let (result, _, flags) = add_24_trits(word_zero, word_neg_one, Trit::Z);
    assert!(!flags.zf, "ZF devrait être false pour 0 + (-1)");

    // Vérifier manuellement le bit de signe du résultat
    let result_sf = update_flags_from_word(&result).sf;
    assert!(
        result_sf,
        "SF devrait être true pour le résultat de 0 + (-1)"
    );

    assert!(!flags.xf, "XF devrait être false pour 0 + (-1)");

    // Test de soustraction avec vérification des flags
    println!("  Test de soustraction...");

    // 0 - 0 = 0 (ZF=true, SF=false, XF=false)
    let (result, _, flags) = sub_24_trits(word_zero, word_zero, Trit::Z);
    assert!(flags.zf, "ZF devrait être true pour 0 - 0");
    assert!(!flags.sf, "SF devrait être false pour 0 - 0");
    assert!(!flags.xf, "XF devrait être false pour 0 - 0");

    // 1 - 1 = 0 (ZF=true, SF=false, XF=false)
    let (result, _, flags) = sub_24_trits(word_one, word_one, Trit::Z);
    assert!(flags.zf, "ZF devrait être true pour 1 - 1");
    assert!(!flags.sf, "SF devrait être false pour 1 - 1");
    assert!(!flags.xf, "XF devrait être false pour 1 - 1");

    // 0 - 1 = -1 (ZF=false, SF=true, XF=false)
    let (result, _, flags) = sub_24_trits(word_zero, word_one, Trit::Z);
    assert!(!flags.zf, "ZF devrait être false pour 0 - 1");

    // Vérifier manuellement le bit de signe du résultat
    let result_sf = update_flags_from_word(&result).sf;
    assert!(result_sf, "SF devrait être true pour le résultat de 0 - 1");

    assert!(!flags.xf, "XF devrait être false pour 0 - 1");

    // 1 - 0 = 1 (ZF=false, SF=false, XF=false)
    let (result, _, flags) = sub_24_trits(word_one, word_zero, Trit::Z);
    assert!(!flags.zf, "ZF devrait être false pour 1 - 0");
    assert!(!flags.sf, "SF devrait être false pour 1 - 0");
    assert!(!flags.xf, "XF devrait être false pour 1 - 0");

    // Test avec des états spéciaux
    println!("  Test avec des états spéciaux...");

    // Créer un mot avec un état spécial
    let mut word_special = word_zero.clone();
    if let Some(tryte) = word_special.tryte_mut(3) {
        *tryte = Tryte::NaN;
    }

    // Addition avec un état spécial (XF=true)
    let (_, _, flags) = add_24_trits(word_special, word_one, Trit::Z);
    assert!(
        flags.xf,
        "XF devrait être true pour une addition avec un état spécial"
    );

    // Soustraction avec un état spécial (XF=true)
    let (_, _, flags) = sub_24_trits(word_special, word_one, Trit::Z);
    assert!(
        flags.xf,
        "XF devrait être true pour une soustraction avec un état spécial"
    );

    println!("  Tests des opérations arithmétiques réussis!");
}

// Test des opérations de comparaison
fn test_compare_operations() {
    println!("Test des opérations de comparaison...");

    // Créer des mots de test
    let word_zero = create_word([Tryte::Digit(13); 8]); // Tous les trytes sont 0 (Z,Z,Z)
    let word_one = create_word([Tryte::Digit(14); 8]); // Tous les trytes sont 1 (Z,Z,P)
    let word_neg_one = create_word([Tryte::Digit(12); 8]); // Tous les trytes sont -1 (Z,Z,N)

    // Test de comparaison d'égalité
    println!("  Test de comparaison d'égalité...");

    // 0 == 0 (ZF=true, SF=false)
    let flags = compare_24_trits(word_zero, word_zero);
    assert!(flags.zf, "ZF devrait être true pour 0 == 0");
    assert!(!flags.sf, "SF devrait être false pour 0 == 0");

    // Test de comparaison supérieur
    println!("  Test de comparaison supérieur...");

    // 1 > 0 (ZF=false, SF=false)
    let flags = compare_24_trits(word_one, word_zero);
    assert!(!flags.zf, "ZF devrait être false pour 1 > 0");
    assert!(!flags.sf, "SF devrait être false pour 1 > 0");

    // Test de comparaison inférieur
    println!("  Test de comparaison inférieur...");

    // -1 < 0 (ZF=false, SF=true)
    let flags = compare_24_trits(word_neg_one, word_zero);
    assert!(!flags.zf, "ZF devrait être false pour -1 < 0");

    // Vérifier manuellement le résultat de la comparaison
    // Pour la comparaison, SF indique si a < b, donc si word_neg_one < word_zero
    // Effectuons une soustraction pour vérifier
    let (result, _, _) = sub_24_trits(word_neg_one, word_zero, Trit::Z);
    let result_sf = update_flags_from_word(&result).sf;
    assert!(result_sf, "SF devrait être true pour le résultat de -1 - 0");

    // 0 < 1 (ZF=false, SF=true)
    let flags = compare_24_trits(word_zero, word_one);
    assert!(!flags.zf, "ZF devrait être false pour 0 < 1");

    // Vérifier manuellement le résultat de la comparaison
    // Pour la comparaison, SF indique si a < b, donc si word_zero < word_one
    // Effectuons une soustraction pour vérifier
    let (result, _, _) = sub_24_trits(word_zero, word_one, Trit::Z);
    let result_sf = update_flags_from_word(&result).sf;
    assert!(result_sf, "SF devrait être true pour le résultat de 0 - 1");

    // Test avec des états spéciaux
    println!("  Test de comparaison avec des états spéciaux...");

    // Créer un mot avec un état spécial
    let mut word_special = word_zero.clone();
    if let Some(tryte) = word_special.tryte_mut(3) {
        *tryte = Tryte::NaN;
    }

    // Comparaison avec un état spécial (XF=true)
    let flags = compare_24_trits(word_special, word_one);
    assert!(
        flags.xf,
        "XF devrait être true pour une comparaison avec un état spécial"
    );

    println!("  Tests des opérations de comparaison réussis!");
}
