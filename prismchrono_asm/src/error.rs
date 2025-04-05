//! Définitions des erreurs pour l'assembleur PrismChrono
//!
//! Ce module définit les différents types d'erreurs qui peuvent survenir
//! pendant le processus d'assemblage.

use std::fmt;
use std::io;
use thiserror::Error;

/// Erreur principale de l'assembleur
#[derive(Error, Debug)]
pub enum AssemblerError {
    /// Erreur d'entrée/sortie
    #[error("Erreur I/O: {0}")]
    IoError(String),

    /// Erreur de lexer (tokenisation)
    #[error("Erreur de lexer à la ligne {line}: {message}")]
    LexerError { line: usize, message: String },

    /// Erreur de parser (analyse syntaxique)
    #[error("Erreur de parser à la ligne {line}: {message}")]
    ParserError { line: usize, message: String },

    /// Erreur de symbole (label non défini, redéfini, etc.)
    #[error("Erreur de symbole: {0}")]
    SymbolError(String),

    /// Erreur d'encodage (valeur hors limites, format invalide, etc.)
    #[error("Erreur d'encodage à la ligne {line}: {message}")]
    EncodeError { line: usize, message: String },

    /// Erreur de la première passe
    #[error("Erreur de la première passe: {0}")]
    Pass1Error(String),

    /// Erreur de la deuxième passe
    #[error("Erreur de la deuxième passe: {0}")]
    Pass2Error(String),
}

/// Erreur spécifique au lexer
#[derive(Debug)]
pub struct LexerError {
    pub line: usize,
    pub column: usize,
    pub message: String,
}

impl fmt::Display for LexerError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Ligne {}, colonne {}: {}", self.line, self.column, self.message)
    }
}

/// Erreur spécifique au parser
#[derive(Debug)]
pub struct ParserError {
    pub line: usize,
    pub message: String,
}

impl fmt::Display for ParserError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Ligne {}: {}", self.line, self.message)
    }
}

/// Erreur spécifique à l'encodage
#[derive(Debug)]
pub struct EncodeError {
    pub line: usize,
    pub message: String,
}

impl fmt::Display for EncodeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Ligne {}: {}", self.line, self.message)
    }
}