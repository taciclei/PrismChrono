//! Module de sortie pour l'assembleur PrismChrono
//!
//! Ce module est responsable de la génération du fichier de sortie .tobj
//! qui représente le code machine ternaire dans un format texte lisible.
//! Il gère également la génération du format binaire .tbin.

use std::fs::File;
use std::io::{self, Write};
use std::path::Path;

use crate::core_types::{Trit, Tryte};
use crate::encoder::EncodedData;
use crate::error::AssemblerError;

/// Écrit les données encodées dans un fichier .tobj
pub fn write_tobj<P: AsRef<Path>>(
    path: P,
    encoded_data: &[(u32, EncodedData)],
) -> Result<(), AssemblerError> {
    let mut file = File::create(path).map_err(|e| {
        AssemblerError::IoError(format!("Impossible de créer le fichier de sortie: {}", e))
    })?;

    for (address, data) in encoded_data {
        match data {
            EncodedData::Instruction(trits) => {
                // Formater l'instruction (ex: "0100: ZZZ ZZZ ZZZ ZZZ # NOP")
                write_instruction(&mut file, *address, trits)?;
            }
            EncodedData::Data(trytes) => {
                // Formater les données (ex: "0100: 13 # Tryte(0)")
                write_data(&mut file, *address, trytes)?;
            }
        }
    }

    Ok(())
}

/// Écrit les données encodées dans un fichier binaire .tbin
/// 
/// Format .tbin:
/// - 4 octets: Signature "TBIN"
/// - 4 octets: Version (1)
/// - 4 octets: Nombre d'entrées
/// - Pour chaque entrée:
///   - 4 octets: Adresse
///   - 1 octet: Type (0 = instruction, 1 = données)
///   - 1 octet: Taille en trytes
///   - N octets: Données (trits pour instructions, trytes pour données)
pub fn write_tbin<P: AsRef<Path>>(
    path: P,
    encoded_data: &[(u32, EncodedData)],
) -> Result<(), AssemblerError> {
    let mut file = File::create(path).map_err(|e| {
        AssemblerError::IoError(format!("Impossible de créer le fichier binaire: {}", e))
    })?;
    
    // Écrire l'en-tête
    file.write_all(b"TBIN").map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;
    
    // Version 1
    file.write_all(&1u32.to_le_bytes()).map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;
    
    // Nombre d'entrées
    let num_entries = encoded_data.len() as u32;
    file.write_all(&num_entries.to_le_bytes()).map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;
    
    // Écrire chaque entrée
    for (address, data) in encoded_data {
        // Adresse
        file.write_all(&address.to_le_bytes()).map_err(|e| {
            AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
        })?;
        
        match data {
            EncodedData::Instruction(trits) => {
                // Type: instruction (0)
                file.write_all(&[0]).map_err(|e| {
                    AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                })?;
                
                // Taille: 4 trytes (12 trits)
                file.write_all(&[4]).map_err(|e| {
                    AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                })?;
                
                // Écrire les 12 trits (4 trytes)
                for trit in trits.iter() {
                    // Convertir le trit en octet (0=N, 1=Z, 2=P)
                    let trit_value = match trit {
                        Trit::N => 0u8,
                        Trit::Z => 1u8,
                        Trit::P => 2u8,
                    };
                    file.write_all(&[trit_value]).map_err(|e| {
                        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                    })?;
                }
            },
            EncodedData::Data(trytes) => {
                // Type: données (1)
                file.write_all(&[1]).map_err(|e| {
                    AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                })?;
                
                // Taille en trytes
                file.write_all(&[trytes.len() as u8]).map_err(|e| {
                    AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                })?;
                
                // Écrire chaque tryte
                for tryte in trytes {
                    // Convertir le tryte en valeur bal3 (-13 à +13)
                    let tryte_value = tryte.bal3_value() as i8;
                    file.write_all(&[tryte_value as u8]).map_err(|e| {
                        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
                    })?;
                }
            }
        }
    }
    
    Ok(())
}

/// Écrit une instruction dans le fichier de sortie
fn write_instruction<W: Write>(
    writer: &mut W,
    address: u32,
    trits: &[Trit; 12],
) -> Result<(), AssemblerError> {
    // Formater l'adresse
    write!(writer, "{:04X}: ", address).map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;

    // Formater les trits en groupes de 3
    for i in 0..4 {
        let start = i * 3;
        write!(writer, "{}{}{} ", 
            trits[start], trits[start + 1], trits[start + 2]
        ).map_err(|e| {
            AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
        })?;
    }

    // Ajouter un commentaire avec le mnémonique (si possible)
    // Pour l'instant, on ne fait pas de décodage inverse
    writeln!(writer, "# Instruction").map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;

    Ok(())
}

/// Écrit des données dans le fichier de sortie
fn write_data<W: Write>(
    writer: &mut W,
    address: u32,
    trytes: &[Tryte],
) -> Result<(), AssemblerError> {
    // Formater l'adresse
    write!(writer, "{:04X}: ", address).map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;

    // Formater les trytes
    for tryte in trytes {
        write!(writer, "{} ", tryte).map_err(|e| {
            AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
        })?;
    }

    // Ajouter un commentaire avec le type de données
    let data_type = if trytes.len() == 1 {
        "Tryte"
    } else if trytes.len() == 8 {
        "Word"
    } else {
        "Data"
    };

    writeln!(writer, "# {}", data_type).map_err(|e| {
        AssemblerError::IoError(format!("Erreur d'écriture: {}", e))
    })?;

    Ok(())
}

/// Formate une instruction en chaîne de caractères (pour les tests)
pub fn format_instruction(address: u32, trits: &[Trit; 12]) -> String {
    let mut result = format!("{:04X}: ", address);

    // Formater les trits en groupes de 3
    for i in 0..4 {
        let start = i * 3;
        result.push_str(&format!("{}{}{} ", 
            trits[start], trits[start + 1], trits[start + 2]
        ));
    }

    result.push_str("# Instruction");
    result
}

/// Formate des données en chaîne de caractères (pour les tests)
pub fn format_data(address: u32, trytes: &[Tryte]) -> String {
    let mut result = format!("{:04X}: ", address);

    // Formater les trytes
    for tryte in trytes {
        result.push_str(&format!("{} ", tryte));
    }

    // Ajouter un commentaire avec le type de données
    let data_type = if trytes.len() == 1 {
        "Tryte"
    } else if trytes.len() == 8 {
        "Word"
    } else {
        "Data"
    };

    result.push_str(&format!("# {}", data_type));
    result
}