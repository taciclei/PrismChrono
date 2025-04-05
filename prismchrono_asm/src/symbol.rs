//! Module de gestion des symboles pour l'assembleur PrismChrono
//!
//! Ce module implémente la table des symboles qui associe les labels à leurs adresses.
//! Il est utilisé pendant les deux passes de l'assemblage pour résoudre les références aux labels.

use std::collections::HashMap;
use crate::core_types::Address;
use crate::error::AssemblerError;

/// Structure représentant la table des symboles
pub struct SymbolTable {
    /// Map associant les noms de labels à leurs adresses
    symbols: HashMap<String, Address>,
}

impl SymbolTable {
    /// Crée une nouvelle table des symboles vide
    pub fn new() -> Self {
        SymbolTable {
            symbols: HashMap::new(),
        }
    }

    /// Définit un symbole dans la table
    pub fn define(&mut self, name: &str, address: Address) -> Result<(), AssemblerError> {
        // Vérifier si le symbole existe déjà
        if self.symbols.contains_key(name) {
            return Err(AssemblerError::SymbolError(
                format!("Le label '{}' est déjà défini", name)
            ));
        }

        // Ajouter le symbole à la table
        self.symbols.insert(name.to_string(), address);
        Ok(())
    }

    /// Résout un symbole (retourne son adresse)
    pub fn resolve(&self, name: &str) -> Result<Address, AssemblerError> {
        self.symbols.get(name).copied().ok_or_else(|| {
            AssemblerError::SymbolError(format!("Label non défini: {}", name))
        })
    }

    /// Vérifie si un symbole est défini
    pub fn is_defined(&self, name: &str) -> bool {
        self.symbols.contains_key(name)
    }

    /// Retourne le nombre de symboles dans la table
    pub fn len(&self) -> usize {
        self.symbols.len()
    }

    /// Vérifie si la table est vide
    pub fn is_empty(&self) -> bool {
        self.symbols.is_empty()
    }

    /// Retourne une référence à la map interne
    pub fn symbols(&self) -> &HashMap<String, Address> {
        &self.symbols
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_define_and_resolve() {
        let mut symbol_table = SymbolTable::new();
        
        // Définir quelques symboles
        symbol_table.define("start", 0x100).unwrap();
        symbol_table.define("loop", 0x120).unwrap();
        
        // Résoudre les symboles
        assert_eq!(symbol_table.resolve("start").unwrap(), 0x100);
        assert_eq!(symbol_table.resolve("loop").unwrap(), 0x120);
        
        // Vérifier qu'un symbole non défini génère une erreur
        assert!(symbol_table.resolve("end").is_err());
    }

    #[test]
    fn test_redefine_symbol() {
        let mut symbol_table = SymbolTable::new();
        
        // Définir un symbole
        symbol_table.define("start", 0x100).unwrap();
        
        // Essayer de redéfinir le même symbole
        let result = symbol_table.define("start", 0x200);
        assert!(result.is_err());
    }

    #[test]
    fn test_is_defined() {
        let mut symbol_table = SymbolTable::new();
        
        // Définir un symbole
        symbol_table.define("start", 0x100).unwrap();
        
        // Vérifier si les symboles sont définis
        assert!(symbol_table.is_defined("start"));
        assert!(!symbol_table.is_defined("end"));
    }
}