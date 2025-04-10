// src/tvpu_hardware.rs
// Implémentation matérielle de l'unité de traitement vectoriel ternaire (TVPU)

use crate::core::{Trit, Tryte, Word};
use crate::tvpu::{TernaryVector, tvadd, tvsub, tvmul, tvdot, tvmac, tvsum, tvmin, tvmax, tvavg};

/// Structure représentant l'unité matérielle de traitement vectoriel ternaire
pub struct TVPUHardware {
    /// Registres vectoriels
    pub registers: [TernaryVector; 16],
    /// Registre d'état
    pub status: TVPUStatus,
    /// Compteur d'opérations
    pub operation_count: u64,
    /// Compteur de cycles
    pub cycle_count: u64,
}

/// Structure représentant l'état de l'unité TVPU
pub struct TVPUStatus {
    /// Indicateur d'opération en cours
    pub busy: bool,
    /// Code d'erreur (si présent)
    pub error_code: Option<u8>,
    /// Indicateur de débordement
    pub overflow: bool,
    /// Indicateur de résultat spécial (NaN, NULL, etc.)
    pub special_result: bool,
    /// Latence de la dernière opération (en cycles)
    pub last_op_latency: u8,
}

impl TVPUHardware {
    /// Crée une nouvelle instance de l'unité TVPU
    pub fn new() -> Self {
        let mut registers = [TernaryVector::default_undefined(); 16];
        for reg in &mut registers {
            *reg = TernaryVector::new();
        }
        
        TVPUHardware {
            registers,
            status: TVPUStatus::new(),
            operation_count: 0,
            cycle_count: 0,
        }
    }
    
    /// Exécute une opération vectorielle
    pub fn execute_operation(&mut self, op: TVPUOperation) -> Result<(), TVPUError> {
        // Réinitialiser l'état
        self.status.busy = true;
        self.status.error_code = None;
        self.status.overflow = false;
        self.status.special_result = false;
        
        // Vérifier les indices de registres
        if !self.validate_registers(&op) {
            self.status.error_code = Some(1); // Code d'erreur: registre invalide
            self.status.busy = false;
            return Err(TVPUError::InvalidRegister);
        }
        
        // Exécuter l'opération
        let start_cycle = self.cycle_count;
        
        match op {
            TVPUOperation::Add { vd, vs1, vs2 } => {
                self.registers[vd] = tvadd(&self.registers[vs1], &self.registers[vs2]);
                self.cycle_count += 2; // Latence: 2 cycles
            },
            TVPUOperation::Sub { vd, vs1, vs2 } => {
                self.registers[vd] = tvsub(&self.registers[vs1], &self.registers[vs2]);
                self.cycle_count += 2; // Latence: 2 cycles
            },
            TVPUOperation::Mul { vd, vs1, vs2 } => {
                self.registers[vd] = tvmul(&self.registers[vs1], &self.registers[vs2]);
                self.cycle_count += 4; // Latence: 4 cycles
            },
            TVPUOperation::Dot { rd, vs1, vs2 } => {
                let result = tvdot(&self.registers[vs1], &self.registers[vs2]);
                // Stocker le résultat dans un registre scalaire (simulé ici par le premier mot du registre vectoriel)
                if let Some(word) = self.registers[rd].word_mut(0) {
                    *word = result;
                }
                self.cycle_count += 8; // Latence: 8 cycles (réduction)
            },
            TVPUOperation::Mac { vd, vs1, vs2, vs3 } => {
                self.registers[vd] = tvmac(&self.registers[vs1], &self.registers[vs2], &self.registers[vs3]);
                self.cycle_count += 5; // Latence: 5 cycles
            },
            TVPUOperation::Sum { rd, vs } => {
                let result = tvsum(&self.registers[vs]);
                // Stocker le résultat dans un registre scalaire
                if let Some(word) = self.registers[rd].word_mut(0) {
                    *word = result;
                }
                self.cycle_count += 6; // Latence: 6 cycles (réduction)
            },
            TVPUOperation::Min { rd, vs } => {
                let result = tvmin(&self.registers[vs]);
                // Stocker le résultat dans un registre scalaire
                if let Some(word) = self.registers[rd].word_mut(0) {
                    *word = result;
                }
                self.cycle_count += 6; // Latence: 6 cycles (réduction)
            },
            TVPUOperation::Max { rd, vs } => {
                let result = tvmax(&self.registers[vs]);
                // Stocker le résultat dans un registre scalaire
                if let Some(word) = self.registers[rd].word_mut(0) {
                    *word = result;
                }
                self.cycle_count += 6; // Latence: 6 cycles (réduction)
            },
            TVPUOperation::Avg { rd, vs } => {
                let result = tvavg(&self.registers[vs]);
                // Stocker le résultat dans un registre scalaire
                if let Some(word) = self.registers[rd].word_mut(0) {
                    *word = result;
                }
                self.cycle_count += 7; // Latence: 7 cycles (réduction + division)
            },
            TVPUOperation::Load { vd, addr, stride } => {
                // Simulation d'un chargement mémoire (non implémenté réellement)
                // Dans une implémentation réelle, on chargerait depuis la mémoire
                self.cycle_count += 10; // Latence: 10 cycles (accès mémoire)
            },
            TVPUOperation::Store { vs, addr, stride } => {
                // Simulation d'un stockage mémoire (non implémenté réellement)
                // Dans une implémentation réelle, on stockerait en mémoire
                self.cycle_count += 10; // Latence: 10 cycles (accès mémoire)
            },
        }
        
        // Mettre à jour les compteurs et l'état
        self.operation_count += 1;
        self.status.last_op_latency = (self.cycle_count - start_cycle) as u8;
        self.status.busy = false;
        
        Ok(())
    }
    
    /// Valide les indices de registres pour une opération
    fn validate_registers(&self, op: &TVPUOperation) -> bool {
        match op {
            TVPUOperation::Add { vd, vs1, vs2 } |
            TVPUOperation::Sub { vd, vs1, vs2 } |
            TVPUOperation::Mul { vd, vs1, vs2 } => {
                *vd < 16 && *vs1 < 16 && *vs2 < 16
            },
            TVPUOperation::Dot { rd, vs1, vs2 } => {
                *rd < 16 && *vs1 < 16 && *vs2 < 16
            },
            TVPUOperation::Mac { vd, vs1, vs2, vs3 } => {
                *vd < 16 && *vs1 < 16 && *vs2 < 16 && *vs3 < 16
            },
            TVPUOperation::Sum { rd, vs } |
            TVPUOperation::Min { rd, vs } |
            TVPUOperation::Max { rd, vs } |
            TVPUOperation::Avg { rd, vs } => {
                *rd < 16 && *vs < 16
            },
            TVPUOperation::Load { vd, .. } => {
                *vd < 16
            },
            TVPUOperation::Store { vs, .. } => {
                *vs < 16
            },
        }
    }
    
    /// Réinitialise l'unité TVPU
    pub fn reset(&mut self) {
        for reg in &mut self.registers {
            *reg = TernaryVector::new();
        }
        self.status = TVPUStatus::new();
        self.operation_count = 0;
        self.cycle_count = 0;
    }
    
    /// Retourne les performances de l'unité TVPU
    pub fn get_performance(&self) -> TVPUPerformance {
        TVPUPerformance {
            operations: self.operation_count,
            cycles: self.cycle_count,
            ops_per_cycle: if self.cycle_count > 0 {
                self.operation_count as f64 / self.cycle_count as f64
            } else {
                0.0
            },
        }
    }
}

impl TVPUStatus {
    /// Crée un nouvel état TVPU
    pub fn new() -> Self {
        TVPUStatus {
            busy: false,
            error_code: None,
            overflow: false,
            special_result: false,
            last_op_latency: 0,
        }
    }
}

/// Structure représentant les performances de l'unité TVPU
pub struct TVPUPerformance {
    /// Nombre total d'opérations exécutées
    pub operations: u64,
    /// Nombre total de cycles
    pub cycles: u64,
    /// Opérations par cycle
    pub ops_per_cycle: f64,
}

/// Énumération des opérations TVPU
pub enum TVPUOperation {
    /// Addition vectorielle: vd = vs1 + vs2
    Add { vd: usize, vs1: usize, vs2: usize },
    /// Soustraction vectorielle: vd = vs1 - vs2
    Sub { vd: usize, vs1: usize, vs2: usize },
    /// Multiplication vectorielle: vd = vs1 * vs2
    Mul { vd: usize, vs1: usize, vs2: usize },
    /// Produit scalaire: rd = vs1 · vs2
    Dot { rd: usize, vs1: usize, vs2: usize },
    /// Multiplication-accumulation: vd = vs1 * vs2 + vs3
    Mac { vd: usize, vs1: usize, vs2: usize, vs3: usize },
    /// Somme des éléments: rd = sum(vs)
    Sum { rd: usize, vs: usize },
    /// Minimum des éléments: rd = min(vs)
    Min { rd: usize, vs: usize },
    /// Maximum des éléments: rd = max(vs)
    Max { rd: usize, vs: usize },
    /// Moyenne des éléments: rd = avg(vs)
    Avg { rd: usize, vs: usize },
    /// Chargement vectoriel: vd = mem[addr:addr+stride*8]
    Load { vd: usize, addr: u32, stride: u8 },
    /// Stockage vectoriel: mem[addr:addr+stride*8] = vs
    Store { vs: usize, addr: u32, stride: u8 },
}

/// Énumération des erreurs TVPU
pub enum TVPUError {
    /// Indice de registre invalide
    InvalidRegister,
    /// Adresse mémoire invalide
    InvalidAddress,
    /// Opération non supportée
    UnsupportedOperation,
    /// Erreur d'alignement
    AlignmentError,
    /// Débordement
    Overflow,
}

/// Implémentation de l'interface de débogage pour TVPUHardware
impl std::fmt::Debug for TVPUHardware {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "TVPU Hardware State:")?;
        writeln!(f, "  Operations: {}", self.operation_count)?;
        writeln!(f, "  Cycles: {}", self.cycle_count)?;
        writeln!(f, "  Status: {:?}", self.status)?;
        writeln!(f, "  Registers:")?;
        for (i, reg) in self.registers.iter().enumerate() {
            if let Some(word) = reg.word(0) {
                writeln!(f, "    V{}: {:?}", i, word)?;
            }
        }
        Ok(())
    }
}

/// Implémentation de l'interface de débogage pour TVPUStatus
impl std::fmt::Debug for TVPUStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "Status {{ busy: {}, ", self