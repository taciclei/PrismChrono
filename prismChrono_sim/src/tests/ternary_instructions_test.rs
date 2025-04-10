// src/tests/ternary_instructions_test.rs
// Tests pour les instructions ternaires spécialisées

#[cfg(test)]
mod tests {
    use crate::core::{Trit, Tryte, Word};
    use crate::ternary_instructions;

    #[test]
    fn test_tcmp3() {
        // Créer deux mots pour la comparaison
        let mut a = Word::default_zero();
        let mut b = Word::default_zero();
        
        // Cas a == b
        let result = ternary_instructions::tcmp3(a, b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 0); // Devrait être Z (0)
        
        // Cas a < b
        if let Some(tryte) = a.tryte_mut(0) {
            *tryte = Tryte::from_i8(-1); // Mettre a à -1
        }
        let result = ternary_instructions::tcmp3(a, b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), -1); // Devrait être N (-1)
        
        // Cas a > b
        if let Some(tryte) = a.tryte_mut(0) {
            *tryte = Tryte::from_i8(1); // Mettre a à 1
        }
        let result = ternary_instructions::tcmp3(a, b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 1); // Devrait être P (1)
    }

    #[test]
    fn test_abs_t() {
        // Créer un mot négatif
        let mut a = Word::default_zero();
        if let Some(tryte) = a.tryte_mut(7) {
            *tryte = Tryte::from_i8(-1); // Mettre le MSB à -1 pour rendre le mot négatif
        }
        
        // Calculer la valeur absolue
        let result = ternary_instructions::abs_t(a);
        
        // Vérifier que le résultat est positif
        if let Some(tryte) = result.tryte(7) {
            assert_eq!(tryte.to_i8(), 1); // Devrait être P (1)
        }
        
        // Tester avec un mot positif
        let mut b = Word::default_zero();
        if let Some(tryte) = b.tryte_mut(7) {
            *tryte = Tryte::from_i8(1); // Mettre le MSB à 1 pour rendre le mot positif
        }
        
        // La valeur absolue d'un mot positif est le mot lui-même
        let result = ternary_instructions::abs_t(b);
        assert_eq!(result, b);
    }

    #[test]
    fn test_signum_t() {
        // Créer un mot négatif
        let mut a = Word::default_zero();
        if let Some(tryte) = a.tryte_mut(7) {
            *tryte = Tryte::from_i8(-1); // Mettre le MSB à -1 pour rendre le mot négatif
        }
        
        // Extraire le signe
        let result = ternary_instructions::signum_t(a);
        assert_eq!(result.tryte(0).unwrap().to_i8(), -1); // Devrait être N (-1)
        
        // Tester avec un mot positif
        let mut b = Word::default_zero();
        if let Some(tryte) = b.tryte_mut(7) {
            *tryte = Tryte::from_i8(1); // Mettre le MSB à 1 pour rendre le mot positif
        }
        
        // Extraire le signe
        let result = ternary_instructions::signum_t(b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 1); // Devrait être P (1)
        
        // Tester avec un mot nul
        let c = Word::default_zero();
        let result = ternary_instructions::signum_t(c);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 0); // Devrait être Z (0)
    }

    #[test]
    fn test_extract_tryte() {
        // Créer un mot avec des valeurs différentes dans chaque tryte
        let mut a = Word::default_zero();
        for i in 0..8 {
            if let Some(tryte) = a.tryte_mut(i) {
                *tryte = Tryte::from_i8(i as i8 - 4); // Valeurs de -4 à 3
            }
        }
        
        // Extraire chaque tryte et vérifier
        for i in 0..8 {
            let result = ternary_instructions::extract_tryte(a, i);
            assert_eq!(result.tryte(0).unwrap().to_i8(), i as i8 - 4);
        }
        
        // Tester avec un index invalide
        let result = ternary_instructions::extract_tryte(a, 8);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 0); // Devrait être Z (0)
    }

    #[test]
    fn test_insert_tryte() {
        // Créer un mot initial
        let a = Word::default_zero();
        
        // Créer un tryte à insérer
        let tryte_value = Tryte::from_i8(5);
        
        // Insérer le tryte à différentes positions
        for i in 0..8 {
            let result = ternary_instructions::insert_tryte(a, i, tryte_value);
            
            // Vérifier que le tryte a été inséré à la bonne position
            assert_eq!(result.tryte(i).unwrap().to_i8(), 5);
            
            // Vérifier que les autres trytes sont restés à zéro
            for j in 0..8 {
                if j != i {
                    assert_eq!(result.tryte(j).unwrap().to_i8(), 0);
                }
            }
        }
        
        // Tester avec un index invalide
        let result = ternary_instructions::insert_tryte(a, 8, tryte_value);
        assert_eq!(result, a); // Le mot ne devrait pas être modifié
    }

    #[test]
    fn test_checkw_valid() {
        // Créer un mot valide
        let a = Word::default_zero();
        
        // Vérifier qu'il est valide
        let result = ternary_instructions::checkw_valid(a);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 1); // Devrait être P (1)
        
        // Créer un mot avec un tryte spécial
        let mut b = Word::default_zero();
        if let Some(tryte) = b.tryte_mut(3) {
            *tryte = Tryte::NaN; // Mettre un tryte à NaN
        }
        
        // Vérifier qu'il est invalide
        let result = ternary_instructions::checkw_valid(b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), -1); // Devrait être N (-1)
    }

    #[test]
    fn test_is_special_tryte() {
        // Créer un mot avec un tryte spécial
        let mut a = Word::default_zero();
        if let Some(tryte) = a.tryte_mut(3) {
            *tryte = Tryte::NaN; // Mettre un tryte à NaN
        }
        
        // Vérifier que le tryte 3 est spécial
        let result = ternary_instructions::is_special_tryte(a, 3);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 1); // Devrait être P (1)
        
        // Vérifier qu'un autre tryte n'est pas spécial
        let result = ternary_instructions::is_special_tryte(a, 0);
        assert_eq!(result.tryte(0).unwrap().to_i8(), -1); // Devrait être N (-1)
        
        // Tester avec un index invalide
        let result = ternary_instructions::is_special_tryte(a, 8);
        assert_eq!(result.tryte(0).unwrap().to_i8(), -1); // Devrait être N (-1)
    }

    #[test]
    fn test_base60_operations() {
        // Tester la conversion décimal -> base 60
        let decimal = 12.5; // 12h30m00s
        let base60 = ternary_instructions::decimal_to_base60(decimal);
        
        // Vérifier les composantes
        assert_eq!(base60.tryte(0).unwrap().to_i8(), 0);  // 0 secondes
        assert_eq!(base60.tryte(1).unwrap().to_i8(), 30); // 30 minutes
        assert_eq!(base60.tryte(2).unwrap().to_i8(), 12); // 12 heures
        
        // Tester la conversion base 60 -> décimal
        let decimal_result = ternary_instructions::base60_to_decimal(base60);
        assert!((decimal_result - decimal).abs() < 0.001);
        
        // Tester l'addition en base 60
        let mut a = Word::default_zero();
        let mut b = Word::default_zero();
        
        // a = 1h45m30s
        if let Some(tryte) = a.tryte_mut(0) {
            *tryte = Tryte::from_i8(30); // 30 secondes
        }
        if let Some(tryte) = a.tryte_mut(1) {
            *tryte = Tryte::from_i8(45); // 45 minutes
        }
        if let Some(tryte) = a.tryte_mut(2) {
            *tryte = Tryte::from_i8(1); // 1 heure
        }
        
        // b = 0h30m45s
        if let Some(tryte) = b.tryte_mut(0) {
            *tryte = Tryte::from_i8(45); // 45 secondes
        }
        if let Some(tryte) = b.tryte_mut(1) {
            *tryte = Tryte::from_i8(30); // 30 minutes
        }
        
        // a + b = 2h16m15s
        let result = ternary_instructions::add_base60(a, b);
        assert_eq!(result.tryte(0).unwrap().to_i8(), 15); // 15 secondes
        assert_eq!(result.tryte(1).unwrap().to_i8(), 16); // 16 minutes
        assert_eq!(result.tryte(2).unwrap().to_i8(), 2);  // 2 heures
    }
}