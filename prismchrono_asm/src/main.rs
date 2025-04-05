//! PrismChrono Assembleur - Point d'entrée principal
//! 
//! Ce fichier contient le point d'entrée de l'assembleur PrismChrono,
//! gérant les arguments de ligne de commande et orchestrant le processus d'assemblage.

use clap::Parser;
use std::fs::File;
use std::io::{self, Read, Write};
use std::path::PathBuf;

// Modules internes
mod core_types;
mod error;
mod lexer;
mod parser;
mod ast;
mod symbol;
mod assembler;
mod encoder;
mod operand;
mod output;
mod isa_defs;

use error::AssemblerError;

/// Structure pour les arguments de ligne de commande
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Fichier source assembleur (.s)
    #[arg(value_name = "INPUT")]
    input: PathBuf,

    /// Fichier de sortie (.tobj ou .tbin)
    #[arg(short, long, value_name = "OUTPUT")]
    output: Option<PathBuf>,

    /// Générer un fichier binaire (.tbin) au lieu d'un fichier texte (.tobj)
    #[arg(short = 'b', long)]
    binary: bool,

    /// Afficher des informations de débogage
    #[arg(short, long)]
    verbose: bool,
}

fn main() -> Result<(), AssemblerError> {
    // Analyser les arguments de ligne de commande
    let args = Args::parse();
    
    // Afficher les informations si verbose est activé
    if args.verbose {
        println!("Assemblage de {} en cours...", args.input.display());
    }
    
    // Déterminer le fichier de sortie et le format
    let (output_path, binary_output) = match args.output {
        Some(path) => {
            // Utiliser l'extension du fichier spécifié ou l'option --binary
            let is_binary = args.binary || path.extension().map_or(false, |ext| ext == "tbin");
            (path, is_binary)
        },
        None => {
            let mut path = args.input.clone();
            // Si l'option --binary est activée, utiliser l'extension .tbin
            if args.binary {
                path.set_extension("tbin");
                (path, true)
            } else {
                path.set_extension("tobj");
                (path, false)
            }
        }
    };
    
    // Lire le fichier source
    let mut source = String::new();
    File::open(&args.input)
        .map_err(|e| AssemblerError::IoError(format!("Impossible d'ouvrir le fichier source: {}", e)))?        
        .read_to_string(&mut source)
        .map_err(|e| AssemblerError::IoError(format!("Impossible de lire le fichier source: {}", e)))?;
    
    // Processus d'assemblage
    if args.verbose {
        println!("1. Tokenisation du code source...");
    }
    
    // 1. Tokeniser le code source (lexer)
    let mut lexer = lexer::Lexer::new(&source);
    let tokens = lexer.tokenize()
        .map_err(|e| {
            eprintln!("Erreur de lexer: {}", e);
            e
        })?;
    
    if args.verbose {
        println!("2. Analyse syntaxique...");
    }
    
    // 2. Parser les tokens en AST (parser)
    let mut parser = parser::Parser::new(tokens);
    let program = parser.parse()
        .map_err(|e| {
            eprintln!("Erreur de parser: {}", e);
            e
        })?;
    
    if args.verbose {
        println!("3. Assemblage (passe 1 et 2)...");
    }
    
    // 3 & 4. Assemblage en deux passes
    let assembler = assembler::Assembler::new(program);
    let assembly_result = assembler.assemble()
        .map_err(|e| {
            eprintln!("Erreur d'assemblage: {}", e);
            e
        })?;
    
    if args.verbose {
        println!("5. Écriture du fichier de sortie...");
        println!("Nombre de symboles: {}", assembly_result.symbol_table.len());
        println!("Nombre d'éléments encodés: {}", assembly_result.encoded_data.len());
    }
    
    // 5. Écrire le fichier de sortie (output)
    if binary_output {
        // Écrire au format binaire (.tbin)
        output::write_tbin(&output_path, &assembly_result.encoded_data)
            .map_err(|e| {
                eprintln!("Erreur d'écriture du fichier binaire: {}", e);
                e
            })?;
        
        if args.verbose {
            println!("Fichier binaire .tbin généré.");
        }
    } else {
        // Écrire au format texte (.tobj)
        output::write_tobj(&output_path, &assembly_result.encoded_data)
            .map_err(|e| {
                eprintln!("Erreur d'écriture du fichier texte: {}", e);
                e
            })?;
            
        if args.verbose {
            println!("Fichier texte .tobj généré.");
        }
    }
    
    if args.verbose {
        println!("Assemblage terminé. Fichier de sortie: {}", output_path.display());
    }
    
    Ok(())
}