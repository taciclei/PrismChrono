//! Module de gestion des opérandes pour l'assembleur PrismChrono
//!
//! Ce module est responsable du parsing et de la validation des opérandes
//! dans les instructions assembleur.

use crate::ast::Operand;
use crate::error::AssemblerError;
use crate::isa_defs::imm_limits;

/// Valide un numéro de registre
pub fn validate_register(reg: u8) -> Result<u8, AssemblerError> {
    if reg <= 7 {
        Ok(reg)
    } else {
        Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!("Numéro de registre invalide: R{} (doit être entre R0 et R7)", reg),
        })
    }
}

/// Valide une valeur immédiate pour le format I
pub fn validate_i_immediate(imm: i32) -> Result<i32, AssemblerError> {
    if imm >= imm_limits::I_MIN && imm <= imm_limits::I_MAX {
        Ok(imm)
    } else {
        Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!(
                "Valeur immédiate hors limites pour format I: {} (doit être entre {} et {})",
                imm, imm_limits::I_MIN, imm_limits::I_MAX
            ),
        })
    }
}

/// Valide une valeur immédiate pour le format U
pub fn validate_u_immediate(imm: i32) -> Result<i32, AssemblerError> {
    if imm >= imm_limits::U_MIN && imm <= imm_limits::U_MAX {
        Ok(imm)
    } else {
        Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!(
                "Valeur immédiate hors limites pour format U: {} (doit être entre {} et {})",
                imm, imm_limits::U_MIN, imm_limits::U_MAX
            ),
        })
    }
}

/// Valide un offset pour le format J
pub fn validate_j_offset(offset: i32) -> Result<i32, AssemblerError> {
    if offset >= imm_limits::J_MIN && offset <= imm_limits::J_MAX {
        Ok(offset)
    } else {
        Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!(
                "Offset hors limites pour format J: {} (doit être entre {} et {})",
                offset, imm_limits::J_MIN, imm_limits::J_MAX
            ),
        })
    }
}

/// Valide un offset pour le format B
pub fn validate_b_offset(offset: i32) -> Result<i32, AssemblerError> {
    if offset >= imm_limits::B_MIN && offset <= imm_limits::B_MAX {
        Ok(offset)
    } else {
        Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!(
                "Offset hors limites pour format B: {} (doit être entre {} et {})",
                offset, imm_limits::B_MIN, imm_limits::B_MAX
            ),
        })
    }
}

/// Valide une valeur immédiate pour le format S
pub fn validate_s_immediate(imm: i32) -> Result<i32, AssemblerError> {
    // Le format S utilise les mêmes limites que le format I
    validate_i_immediate(imm)
}

/// Calcule l'offset pour l'instruction JAL
pub fn calculate_jal_offset(target_addr: u32, current_addr: u32) -> Result<i32, AssemblerError> {
    // L'offset est relatif à l'adresse après l'instruction JAL
    let pc_after_jal = current_addr + 4;
    
    // Calculer la différence d'adresse
    let diff = target_addr as i64 - pc_after_jal as i64;
    
    // Vérifier si la différence est un multiple de 4 (alignement des instructions)
    if diff % 4 != 0 {
        return Err(AssemblerError::EncodeError {
            line: 0, // Sera mis à jour par l'appelant
            message: format!(
                "L'adresse cible n'est pas alignée sur 4 octets: 0x{:X}",
                target_addr
            ),
        });
    }
    
    // Convertir en nombre d'instructions (diviser par 4)
    let offset = (diff / 4) as i32;
    
    // Valider l'offset
    validate_j_offset(offset)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_register() {
        // Registres valides
        for reg in 0..=7 {
            assert!(validate_register(reg).is_ok());
        }
        
        // Registre invalide
        assert!(validate_register(8).is_err());
    }

    #[test]
    fn test_validate_i_immediate() {
        // Valeurs limites valides
        assert!(validate_i_immediate(imm_limits::I_MIN).is_ok());
        assert!(validate_i_immediate(0).is_ok());
        assert!(validate_i_immediate(imm_limits::I_MAX).is_ok());
        
        // Valeurs hors limites
        assert!(validate_i_immediate(imm_limits::I_MIN - 1).is_err());
        assert!(validate_i_immediate(imm_limits::I_MAX + 1).is_err());
    }

    #[test]
    fn test_calculate_jal_offset() {
        // Offset positif
        assert_eq!(calculate_jal_offset(0x100, 0x0).unwrap(), 64); // (0x100 - (0x0 + 4)) / 4 = 0xFC / 4 = 63
        
        // Offset négatif
        assert_eq!(calculate_jal_offset(0x0, 0x100).unwrap(), -65); // (0x0 - (0x100 + 4)) / 4 = -0x104 / 4 = -65
        
        // Adresse non alignée
        assert!(calculate_jal_offset(0x102, 0x100).is_err());
    }
}