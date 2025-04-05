// src/cpu/execute_core.rs
// Implémentation du cœur d'exécution pour l'architecture PrismChrono

use crate::alu::add_24_trits;
use crate::core::{Address, Trit, Tryte, Word, is_valid_address};
use crate::cpu::isa::Instruction;
use crate::cpu::registers::{Flags, ProcessorState, Register, RegisterError};
use crate::memory::{Memory, MemoryError};

// Importer les traits des modules d'exécution spécialisés
use crate::cpu::execute_alu::AluOperations;
use crate::cpu::execute_branch::BranchOperations;
use crate::cpu::execute_mem::MemoryOperations;
use crate::cpu::execute_system::SystemOperations;
use crate::cpu::state::CpuState;

/// Erreurs possibles lors de l'exécution d'une instruction
#[derive(Debug, PartialEq, Eq)]
pub enum ExecuteError {
    MemoryError(MemoryError),     // Erreur d'accès mémoire
    RegisterError(RegisterError), // Erreur d'accès registre
    InvalidInstruction,           // Instruction invalide
    Unimplemented,                // Instruction non implémentée
    DivisionByZero,               // Division par zéro
    InvalidAddress,               // Adresse invalide
    UnalignedAddress,             // Adresse non alignée
    InvalidOperation,             // Opération invalide
    Halted,                       // Processeur arrêté (HALT)
}

// Conversion des erreurs mémoire en erreurs d'exécution
impl From<MemoryError> for ExecuteError {
    fn from(error: MemoryError) -> Self {
        ExecuteError::MemoryError(error)
    }
}

// Conversion des erreurs de registre en erreurs d'exécution
impl From<RegisterError> for ExecuteError {
    fn from(error: RegisterError) -> Self {
        ExecuteError::RegisterError(error)
    }
}

/// Structure principale du CPU qui contient l'état du processeur et la mémoire
pub struct Cpu {
    pub state: ProcessorState, // État du processeur (registres, flags)
    pub memory: Memory,        // Mémoire principale
    pub halted: bool,          // Indique si le processeur est arrêté
    
    // Compteurs pour les métriques d'exécution
    pub instructions_executed: u64, // Nombre total d'instructions exécutées
    pub memory_reads: u64,          // Nombre d'opérations de lecture mémoire
    pub memory_writes: u64,         // Nombre d'opérations d'écriture mémoire
    pub branches_total: u64,        // Nombre total d'instructions de branchement
    pub branches_taken: u64,        // Nombre de branchements effectivement pris
}

impl Cpu {
    /// Crée un nouveau CPU avec une mémoire de taille par défaut
    pub fn new() -> Self {
        Cpu {
            state: ProcessorState::new(),
            memory: Memory::new(),
            halted: false,
            instructions_executed: 0,
            memory_reads: 0,
            memory_writes: 0,
            branches_total: 0,
            branches_taken: 0,
        }
    }

    /// Crée un nouveau CPU avec une mémoire de taille spécifiée
    pub fn with_memory_size(size: usize) -> Self {
        Cpu {
            state: ProcessorState::new(),
            memory: Memory::with_size(size),
            halted: false,
            instructions_executed: 0,
            memory_reads: 0,
            memory_writes: 0,
            branches_total: 0,
            branches_taken: 0,
        }
    }

    /// Récupère l'instruction à l'adresse pointée par le PC
    pub fn fetch(&self) -> Result<[Trit; 12], ExecuteError> {
        // Récupérer la valeur du PC
        let pc_value = self.state.read_pc();

        // Extraire l'adresse à partir du PC (les 16 trits de poids faible)
        let mut pc_addr: Address = 0;

        // Extraire les 5 premiers trytes (15 trits)
        for i in 0..5 {
            if let Some(tryte) = pc_value.tryte(i) {
                match tryte {
                    Tryte::Digit(val) => {
                        // Convertir la valeur du tryte en adresse
                        // et la décaler à la position appropriée
                        pc_addr += (*val as Address) * (3_i32.pow((i * 3) as u32) as Address);
                    }
                    _ => return Err(ExecuteError::InvalidAddress),
                }
            }
        }

        // Vérifier que l'adresse est valide et alignée sur 4 trytes
        if !is_valid_address(pc_addr) {
            return Err(ExecuteError::InvalidAddress);
        }
        if pc_addr % 4 != 0 {
            return Err(ExecuteError::InvalidAddress); // Adresse non alignée sur 4 trytes
        }

        // Lire 4 trytes consécutifs (12 trits) à partir de l'adresse PC
        let mut instr_trits = [Trit::Z; 12];
        let mut trit_index = 0;

        for i in 0..4 {
            let tryte = self
                .memory
                .read_tryte(pc_addr + i)
                .map_err(ExecuteError::from)?;

            // Extraire les 3 trits du tryte et les ajouter à l'instruction
            let tryte_trits = tryte.to_trits();
            for j in 0..3 {
                instr_trits[trit_index] = tryte_trits[j];
                trit_index += 1;
            }
        }

        Ok(instr_trits)
    }

    /// Exécute une étape du cycle d'instruction (fetch-decode-execute)
    pub fn step(&mut self) -> Result<(), ExecuteError> {
        // Si le processeur est arrêté, ne rien faire
        if self.halted {
            return Err(ExecuteError::Halted);
        }

        // 1. Récupérer l'instruction (fetch)
        let instr_trits = self.fetch()?;

        // 2. Décoder l'instruction
        let instruction = crate::cpu::decode::decode(instr_trits)
            .map_err(|_| ExecuteError::InvalidInstruction)?;

        // Incrémenter le compteur d'instructions exécutées
        self.instructions_executed += 1;

        // Sauvegarder le PC actuel avant exécution
        let old_pc = self.state.read_pc();

        // 3. Exécuter l'instruction
        self.execute(instruction)?;

        // 4. Incrémenter le PC (sauf si modifié par l'instruction)
        // Les instructions de saut (JAL, JALR) et de branchement modifient déjà le PC
        // On vérifie donc si le PC a été modifié par l'instruction
        if !self.halted {
            let current_pc = self.state.read_pc();

            // Si le PC n'a pas été modifié par l'instruction, l'incrémenter de 4
            if current_pc == old_pc {
                // Créer un Word pour l'incrément de PC (4 trytes)
                let mut inc_word = Word::zero();
                if let Some(tryte) = inc_word.tryte_mut(0) {
                    *tryte = Tryte::Digit(17); // 4 en ternaire équilibré (13+4=17)
                }

                // Calculer PC+4
                let (new_pc, _, _) = add_24_trits(current_pc, inc_word, Trit::Z);

                // Mettre à jour le PC
                self.state.write_pc(new_pc);
            }
        }

        Ok(())
    }

    /// Exécute une instruction décodée
    pub fn execute(&mut self, instruction: Instruction) -> Result<(), ExecuteError> {
        match instruction {
            Instruction::AluReg { op, rs1, rs2, rd } => self.execute_alu_reg(op, rs1, rs2, rd),
            Instruction::AluImm { op, rs1, rd, imm } => self.execute_alu_imm(op, rs1, rd, imm),
            Instruction::Load { rd, rs1, offset } => self.execute_load(rd, rs1, offset),
            Instruction::Store { rs1, rs2, offset } => self.execute_store(rs1, rs2, offset),
            Instruction::Branch { rs1, cond, offset } => self.execute_branch(rs1, cond, offset),
            Instruction::Jump { rd, offset } => self.execute_jump(rd, offset),
            Instruction::Call { rd, offset } => self.execute_call(rd, offset),
            Instruction::System { func } => self.execute_system(func),
            Instruction::Lui { rd, imm } => self.execute_lui(rd, imm),
            Instruction::Auipc { rd, imm } => self.execute_auipc(rd, imm),
            Instruction::Jalr { rd, rs1, offset } => self.execute_jalr(rd, rs1, offset),
            Instruction::Nop => Ok(()), // Ne rien faire
            Instruction::Halt => {
                self.halted = true;
                Ok(())
            }
        }
    }
}

// Implémentation du trait CpuState unifié
impl CpuState for Cpu {
    fn as_cpu_mut(&mut self) -> Option<&mut Cpu> {
        Some(self)
    }
    
    fn read_gpr(&self, reg: Register) -> Word {
        self.state.read_gpr(reg)
    }

    fn write_gpr(&mut self, reg: Register, value: Word) {
        self.state.write_gpr(reg, value);
    }

    fn read_pc(&self) -> Word {
        self.state.read_pc()
    }

    fn write_pc(&mut self, value: Word) {
        self.state.write_pc(value);
    }

    fn read_flags(&self) -> Flags {
        self.state.read_flags()
    }

    fn write_flags(&mut self, flags: Flags) {
        self.state.write_flags(flags);
    }

    fn set_halted(&mut self, halted: bool) {
        self.halted = halted;
    }

    fn read_tryte(&self, addr: Address) -> Result<Tryte, ExecuteError> {
        self.memory.read_tryte(addr).map_err(ExecuteError::from)
    }

    fn write_tryte(&mut self, addr: Address, value: Tryte) -> Result<(), ExecuteError> {
        self.memory
            .write_tryte(addr, value)
            .map_err(ExecuteError::from)
    }

    fn read_word(&self, addr: Address) -> Result<Word, ExecuteError> {
        self.memory.read_word(addr).map_err(ExecuteError::from)
    }

    fn write_word(&mut self, addr: Address, value: Word) -> Result<(), ExecuteError> {
        self.memory
            .write_word(addr, value)
            .map_err(ExecuteError::from)
    }

    fn state_read_csr(&self, csr: i8) -> Result<Word, RegisterError> {
        self.state.read_csr(csr)
    }

    fn state_write_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError> {
        self.state.write_csr(csr, value)
    }

    fn state_set_csr(&mut self, csr: i8, value: Word) -> Result<(), RegisterError> {
        self.state.set_csr(csr, value)
    }

    fn state_get_privilege(&self) -> PrivilegeLevel {
        self.state.current_privilege
    }

    fn state_set_privilege(&mut self, privilege: PrivilegeLevel) {
        self.state.current_privilege = privilege;
    }

    fn state_get_previous_privilege(&self) -> PrivilegeLevel {
        self.state.get_previous_privilege()
    }

    fn state_set_previous_privilege(&mut self, privilege: PrivilegeLevel) {
        self.state.set_previous_privilege(privilege);
    }

    fn state_set_trap_cause(&mut self, cause: TrapCause) {
        self.state.set_trap_cause(cause);
    }
}
