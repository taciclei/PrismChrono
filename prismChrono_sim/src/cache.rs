// src/cache.rs
// Implémentation du cache prédictif ternaire

use crate::core::{Trit, Tryte, Word};

/// Taille d'une ligne de cache en mots
const CACHE_LINE_SIZE: usize = 4;

/// Niveaux de confiance pour la prédiction d'accès
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd)]
pub enum AccessConfidence {
    /// Accès probable (haute confiance)
    Probable,
    /// Accès incertain (confiance moyenne)
    Uncertain,
    /// Accès improbable (faible confiance)
    Improbable,
}

/// Structure d'une ligne de cache
pub struct CacheLine {
    /// Tag de la ligne
    tag: u32,
    /// Données de la ligne
    data: [Word; CACHE_LINE_SIZE],
    /// Indique si la ligne est valide
    valid: bool,
    /// Indique si la ligne est modifiée (dirty)
    dirty: bool,
    /// Compteur d'utilisation pour la politique de remplacement
    usage_counter: u32,
    /// Niveau de confiance pour le préchargement
    confidence: AccessConfidence,
    /// Historique des accès (pour la prédiction)
    access_history: u32,
}

impl CacheLine {
    /// Crée une nouvelle ligne de cache vide
    pub fn new() -> Self {
        CacheLine {
            tag: 0,
            data: [Word::default_zero(); CACHE_LINE_SIZE],
            valid: false,
            dirty: false,
            usage_counter: 0,
            confidence: AccessConfidence::Uncertain,
            access_history: 0,
        }
    }
}

/// Structure d'un ensemble de cache
pub struct CacheSet {
    /// Lignes de l'ensemble
    lines: Vec<CacheLine>,
    /// Nombre de voies (associativité)
    ways: usize,
}

impl CacheSet {
    /// Crée un nouvel ensemble de cache
    pub fn new(ways: usize) -> Self {
        let mut lines = Vec::with_capacity(ways);
        for _ in 0..ways {
            lines.push(CacheLine::new());
        }
        
        CacheSet {
            lines,
            ways,
        }
    }
    
    /// Recherche une ligne dans l'ensemble
    pub fn find_line(&self, tag: u32) -> Option<usize> {
        for (i, line) in self.lines.iter().enumerate() {
            if line.valid && line.tag == tag {
                return Some(i);
            }
        }
        
        None
    }
    
    /// Trouve la ligne la moins récemment utilisée
    pub fn find_lru(&self) -> usize {
        let mut lru_index = 0;
        let mut min_counter = u32::MAX;
        
        for (i, line) in self.lines.iter().enumerate() {
            if !line.valid {
                return i;
            }
            
            if line.usage_counter < min_counter {
                min_counter = line.usage_counter;
                lru_index = i;
            }
        }
        
        lru_index
    }
}

/// Cache prédictif ternaire
pub struct TernaryPredictiveCache {
    /// Ensembles du cache
    sets: Vec<CacheSet>,
    /// Nombre d'ensembles
    num_sets: usize,
    /// Nombre de voies (associativité)
    ways: usize,
    /// Taille d'une ligne en mots
    line_size: usize,
    /// Nombre de bits pour l'index
    index_bits: usize,
    /// Nombre de bits pour l'offset
    offset_bits: usize,
    /// Compteur global pour la politique de remplacement
    global_counter: u32,
    /// Tampon de préchargement
    prefetch_buffer: Vec<(u32, AccessConfidence)>,
    /// Taille du tampon de préchargement
    prefetch_buffer_size: usize,
}

impl TernaryPredictiveCache {
    /// Crée un nouveau cache prédictif ternaire
    pub fn new(num_sets: usize, ways: usize, line_size: usize, prefetch_buffer_size: usize) -> Self {
        let mut sets = Vec::with_capacity(num_sets);
        for _ in 0..num_sets {
            sets.push(CacheSet::new(ways));
        }
        
        // Calculer le nombre de bits pour l'index et l'offset
        let offset_bits = (line_size * 4).trailing_zeros() as usize;
        let index_bits = num_sets.trailing_zeros() as usize;
        
        TernaryPredictiveCache {
            sets,
            num_sets,
            ways,
            line_size,
            index_bits,
            offset_bits,
            global_counter: 0,
            prefetch_buffer: Vec::with_capacity(prefetch_buffer_size),
            prefetch_buffer_size,
        }
    }
    
    /// Lire les données d'une ligne de cache sans modifier l'historique
    fn read_line_data(&self, line: &CacheLine, offset: usize) -> Word {
        line.data[offset]
    }
    
    /// Mettre à jour une ligne après un hit et retourner les données
    fn process_cache_access(&mut self, index: usize, line_index: usize, offset: usize, address: u32, memory: &mut [Word]) -> Word {
        // Copier les données pour éviter d'avoir un emprunt mutable lors de l'appel à d'autres méthodes
        let data;
        {
            let line = &mut self.sets[index].lines[line_index];
            data = line.data[offset];
            line.usage_counter = self.global_counter;
            
            // Mise à jour de l'historique d'accès sans utiliser self
            line.access_history = (line.access_history << 3) | (offset as u32);
        }
        
        // Prédiction basée sur l'adresse plutôt que sur la ligne
        self.simple_prefetch(address, offset, memory);
        
        data
    }
    
    /// Prédiction et préchargement simplifié sans emprunts multiples
    fn simple_prefetch(&mut self, address: u32, _current_offset: usize, memory: &mut [Word]) {
        // Calculer l'adresse suivante la plus probable
        let stride = 1; // Stride simple
        let prefetch_addr = address + (stride << (self.offset_bits as u32));
        
        // Décoder l'adresse à l'avance pour éviter les emprunts mutuels
        let (pfetch_tag, pfetch_index, _pfetch_offset) = self.decode_address(prefetch_addr);
        
        // Précharger seulement si pas déjà dans le tampon
        if !self.prefetch_buffer.iter().any(|entry| entry.0 == prefetch_addr) {
            if let Some(entry) = self.prefetch_buffer.iter_mut().find(|e| e.0 == 0) {
                entry.0 = prefetch_addr;
                entry.1 = AccessConfidence::Probable;
                
                // Précharger dans la mémoire (simulation simplifiée)
                let base_addr = prefetch_addr & !(self.line_size as u32 - 1);
                for i in 0..self.line_size {
                    let addr = base_addr + i as u32;
                    if addr < memory.len() as u32 {
                        // Ne rien faire, juste simuler une lecture
                    }
                }
            }
        }
    }
    
    /// Accède au cache pour une lecture
    pub fn read(&mut self, address: u32, memory: &mut [Word]) -> Word {
        self.global_counter = self.global_counter.wrapping_add(1);
        
        // Décomposer l'adresse
        let (tag, index, offset) = self.decode_address(address);
        
        // Rechercher dans le cache
        if let Some(line_index) = self.sets[index].find_line(tag) {
            // Hit de cache
            let result = self.process_cache_access(index, line_index, offset, address, memory);
            
            // Préchargement prédictif
            self.simple_prefetch(address, offset, memory);
            
            return result;
        } else {
            // Miss de cache
            
            // Avant de remplacer une ligne, vérifier si elle est modifiée (dirty)
            let victim_index = self.sets[index].find_lru();
            let victim_line = &self.sets[index].lines[victim_index];
            
            if victim_line.valid && victim_line.dirty {
                // Écrire la ligne victime en mémoire
                self.write_back_line_simple(index, victim_index, memory);
            }
            
            // Vérifier si l'adresse est dans le tampon de préchargement
            let prefetch_index = self.prefetch_buffer.iter().position(|entry| {
                let (entry_tag, entry_index, _) = self.decode_address(entry.0);
                entry_tag == tag && entry_index == index
            });
            
            if let Some((buffer_index, _confidence)) = prefetch_index.map(|i| (i, self.prefetch_buffer[i].1)) {
                // L'adresse était dans le tampon de préchargement, marque comme succès
                self.prefetch_buffer.remove(buffer_index);
            }
            
            // Charger la ligne depuis la mémoire
            self.load_line_from_memory(address, memory);
            
            // Trouver à nouveau la ligne (maintenant chargée)
            if let Some(line_index) = self.sets[index].find_line(tag) {
                return self.sets[index].lines[line_index].data[offset];
            }
        }
        
        // En cas d'erreur, retourner une valeur par défaut
        Word::default_zero()
    }
    
    /// Écrire dans le cache et gérer le hit/miss
    pub fn write(&mut self, address: u32, value: Word, memory: &mut [Word]) {
        self.global_counter = self.global_counter.wrapping_add(1);
        
        // Décomposer l'adresse
        let (tag, index, offset) = self.decode_address(address);
        
        // Rechercher dans le cache
        if let Some(line_index) = self.sets[index].find_line(tag) {
            // Hit de cache, mettre à jour la ligne
            let line = &mut self.sets[index].lines[line_index];
            line.data[offset] = value;
            line.dirty = true;
            line.usage_counter = self.global_counter;
            
            // Préchargement prédictif
            self.simple_prefetch(address, offset, memory);
        } else {
            // Miss de cache
            
            // Trouver une ligne victime à remplacer
            let victim_index = self.sets[index].find_lru();
            let line = &mut self.sets[index].lines[victim_index];
            
            // Si la ligne est modifiée, la sauvegarder en mémoire
            if line.valid && line.dirty {
                // Écrire la ligne victime en mémoire
                self.write_back_line_simple(index, victim_index, memory);
            }
            
            // Charger la ligne depuis la mémoire
            self.load_line_from_memory(address, memory);
            
            // Rechercher à nouveau la ligne (maintenant chargée)
            if let Some(line_index) = self.sets[index].find_line(tag) {
                // Mettre à jour avec la nouvelle valeur
                let line = &mut self.sets[index].lines[line_index];
                line.data[offset] = value;
                line.dirty = true;
            }
        }
    }
    
    /// Prédit les accès futurs et précharge les données
    fn predict_and_prefetch(&mut self, address: u32, line: &CacheLine, _memory: &mut [Word]) {
        // Historique des accès pour la prédiction
        let history = line.access_history;
        
        // Motifs pour la prédiction
        // Séquentiel : accès consécutifs (001, 010, 100)
        let sequential_pattern = 0b100010001;
        
        // Analyse des motifs pour prédiction
        let mut next_addresses = Vec::new();
        
        // Pour l'exemple, on ne fait qu'une prédiction simple
        if (history & sequential_pattern) == sequential_pattern {
            // Motif séquentiel détecté, précharger la ligne suivante
            let next_address = address + (self.line_size as u32);
            next_addresses.push((next_address, AccessConfidence::Probable));
        }
        
        // Ajouter les adresses prédites au tampon de préchargement
        for (addr, confidence) in next_addresses {
            self.add_to_prefetch_buffer(addr, confidence);
        }
    }
    
    /// Lance un préchargement en fonction d'une adresse
    fn prefetch_address(&mut self, address: u32, memory: &mut [Word]) {
        // Décomposer l'adresse
        let (tag, index, _offset) = self.decode_address(address);
        
        // Vérifier si la ligne est déjà dans le cache
        if let Some(_line_index) = self.sets[index].find_line(tag) {
            // Ligne déjà dans le cache, rien à faire
            return;
        }
        
        // Chercher une ligne libre ou à remplacer
        let victim_index = self.sets[index].find_lru();
        
        // Si la ligne est modifiée, la sauvegarder en mémoire
        {
            let victim_line = &self.sets[index].lines[victim_index];
            if victim_line.valid && victim_line.dirty {
                // Écrire la ligne victime en mémoire sans accéder directement à self
                let base_addr = (victim_line.tag << self.index_bits as u32) | (index as u32);
                
                // Écrire les données en mémoire
                for i in 0..self.line_size {
                    let addr = base_addr + i as u32;
                    if addr < memory.len() as u32 {
                        memory[addr as usize] = victim_line.data[i];
                    }
                }
                
                // Marquons la ligne comme non-modifiée après l'emprunt
                self.sets[index].lines[victim_index].dirty = false;
            }
        }
        
        // Charger la ligne depuis la mémoire
        // Base de la ligne
        let base_addr = address & !(self.line_size as u32 - 1);
        
        // Mise à jour de la ligne
        {
            let line = &mut self.sets[index].lines[victim_index];
            line.tag = tag;
            line.valid = true;
            line.dirty = false;
            line.usage_counter = self.global_counter - 1; // Priorité basse pour préchargement
            
            // Chargement des données
            for i in 0..self.line_size {
                let addr = base_addr + i as u32;
                if addr < memory.len() as u32 {
                    line.data[i] = memory[addr as usize];
                }
            }
        }
    }
    
    /// Décompose une adresse en tag, index et offset
    fn decode_address(&self, address: u32) -> (u32, usize, usize) {
        let word_address = address / 4;
        let offset = (word_address % (self.line_size as u32)) as usize;
        let index = ((word_address / (self.line_size as u32)) % (self.num_sets as u32)) as usize;
        let tag = word_address / ((self.line_size * self.num_sets) as u32);
        
        (tag, index, offset)
    }
    
    /// Charge une ligne depuis la mémoire
    fn load_line_from_memory(&mut self, address: u32, memory: &mut [Word]) {
        // Décomposer l'adresse
        let (tag, index, _) = self.decode_address(address);
        
        // Trouver une ligne à remplacer
        let line_index = self.sets[index].find_lru();
        
        // Si la ligne est dirty, écrire en mémoire (write-back) sans utiliser self et line simultanément
        {
            let line = &self.sets[index].lines[line_index];
            if line.valid && line.dirty {
                // Copier les données nécessaires pour le write-back
                let line_tag = line.tag;
                let line_data = line.data.clone();
                
                // Calculer l'adresse de base pour l'écriture
                let base_address = ((line_tag as u32) << self.index_bits) | (index as u32);
                
                // Écrire les données en mémoire
                for i in 0..self.line_size {
                    let addr = base_address + i as u32;
                    if let Some(word) = memory.get_mut(addr as usize) {
                        *word = line_data[i];
                    }
                }
            }
        }
        
        // Maintenant on peut emprunter de façon mutable
        let line = &mut self.sets[index].lines[line_index];
        
        // Charger la nouvelle ligne
        let base_address = (address / 4) & !(self.line_size as u32 - 1);
        for i in 0..self.line_size {
            let mem_index = (base_address + i as u32) as usize;
            if mem_index < memory.len() {
                line.data[i] = memory[mem_index];
            } else {
                line.data[i] = Word::zero();
            }
        }
        
        // Mettre à jour les métadonnées
        line.tag = tag;
        line.valid = true;
        line.dirty = false;
        line.usage_counter = self.global_counter;
        line.confidence = AccessConfidence::Uncertain;
        line.access_history = 0;
    }
    
    /// Écrit une ligne en mémoire (write-back)
    fn write_back_line(&self, line: &CacheLine, index: usize, memory: &mut [Word]) {
        let base_address = ((line.tag * (self.num_sets as u32) + index as u32) * (self.line_size as u32)) * 4;
        
        for i in 0..self.line_size {
            let mem_index = (base_address / 4 + i as u32) as usize;
            if mem_index < memory.len() {
                memory[mem_index] = line.data[i];
            }
        }
    }
    
    /// Version simplifiée de write_back_line sans prendre self et line simultanément
    fn write_back_line_simple(&mut self, index: usize, line_index: usize, memory: &mut [Word]) {
        let line = &self.sets[index].lines[line_index];
        // Calculer l'adresse de base de la ligne
        let base_addr = (line.tag << self.index_bits as u32) | (index as u32);
        
        // Écrire les données en mémoire
        for i in 0..self.line_size {
            let addr = base_addr + i as u32;
            if addr < memory.len() as u32 {
                memory[addr as usize] = line.data[i];
            }
        }
        
        // Marquer la ligne comme non-modifiée
        self.sets[index].lines[line_index].dirty = false;
    }
    
    /// Ajoute une adresse au tampon de préchargement
    fn add_to_prefetch_buffer(&mut self, address: u32, confidence: AccessConfidence) {
        // Vérifier si l'adresse est déjà dans le cache
        let (tag, index, _) = self.decode_address(address);
        if self.sets[index].find_line(tag).is_some() {
            return;
        }
        
        // Vérifier si l'adresse est déjà dans le tampon
        for (i, (addr, _)) in self.prefetch_buffer.iter().enumerate() {
            if *addr == address {
                // Mettre à jour la confiance si nécessaire
                if confidence == AccessConfidence::Probable {
                    self.prefetch_buffer[i].1 = confidence;
                }
                return;
            }
        }
        
        // Ajouter au tampon
        if self.prefetch_buffer.len() >= self.prefetch_buffer_size {
            // Supprimer l'entrée avec la confiance la plus faible
            let mut lowest_confidence_index = 0;
            let mut lowest_confidence = AccessConfidence::Probable;
            
            for (i, (_, conf)) in self.prefetch_buffer.iter().enumerate() {
                if *conf < lowest_confidence {
                    lowest_confidence = *conf;
                    lowest_confidence_index = i;
                }
            }
            
            if lowest_confidence < confidence {
                self.prefetch_buffer[lowest_confidence_index] = (address, confidence);
            }
        } else {
            self.prefetch_buffer.push((address, confidence));
        }
    }
    
    /// Recherche une adresse dans le tampon de préchargement
    fn find_in_prefetch_buffer(&self, address: u32) -> Option<(usize, AccessConfidence)> {
        for (i, (addr, confidence)) in self.prefetch_buffer.iter().enumerate() {
            if *addr == address {
                return Some((i, *confidence));
            }
        }
        
        None
    }
    
    /// Effectue le préchargement des données dans le tampon
    pub fn perform_prefetch(&mut self, memory: &mut [Word]) {
        // Trier le tampon par niveau de confiance
        self.prefetch_buffer.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        
        // Précharger les données avec la plus haute confiance
        let mut prefetched = 0;
        let max_prefetch = 2; // Limiter le nombre de préchargements par cycle
        
        let mut i = 0;
        while i < self.prefetch_buffer.len() && prefetched < max_prefetch {
            let (address, confidence) = self.prefetch_buffer[i];
            
            // Ne précharger que les données avec une confiance suffisante
            if confidence == AccessConfidence::Probable {
                // Vérifier si l'adresse est déjà dans le cache
                let (tag, index, _) = self.decode_address(address);
                if self.sets[index].find_line(tag).is_none() {
                    // Précharger la ligne
                    self.load_line_from_memory(address, memory);
                    prefetched += 1;
                }
                
                // Retirer du tampon
                self.prefetch_buffer.remove(i);
            } else {
                i += 1;
            }
        }
    }
    
    /// Compresse une ligne de cache
    pub fn compress_line(&self, line: &CacheLine) -> Word {
        // Implémentation simplifiée de la compression
        // Dans une implémentation réelle, on utiliserait un algorithme de compression adapté aux données ternaires
        
        // Pour cet exemple, on calcule simplement une signature de la ligne
        let mut signature = Word::zero();
        
        for (i, word) in line.data.iter().enumerate() {
            // XOR avec décalage
            let shifted_word = self.shift_word(*word, i);
            signature = self.ternary_xor(signature, shifted_word);
        }
        
        signature
    }
    
    /// Décompresse une ligne de cache
    pub fn decompress_line(&self, compressed: Word, original: &CacheLine) -> [Word; CACHE_LINE_SIZE] {
        // Dans une implémentation réelle, on utiliserait l'algorithme de décompression correspondant
        // Pour cet exemple, on retourne simplement la ligne originale
        original.data
    }
    
    /// Décale un mot ternaire
    fn shift_word(&self, word: Word, shift: usize) -> Word {
        let mut result = Word::zero();
        
        // Convertir le mot en trytes
        let mut trytes = [Tryte::default(); 8];
        for i in 0..8 {
            if let Some(tryte) = word.tryte(i) {
                trytes[i] = *tryte;
            }
        }
        
        // Effectuer le décalage
        for i in 0..8 {
            if let Some(tryte_result) = result.tryte_mut(i) {
                *tryte_result = trytes[(i + shift) % 8];
            }
        }
        
        result
    }
    
    /// XOR ternaire entre deux mots
    fn ternary_xor(&self, a: Word, b: Word) -> Word {
        let mut result = Word::zero();
        
        for i in 0..8 {
            if let (Some(tryte_a), Some(tryte_b), Some(tryte_result)) = 
                (a.tryte(i), b.tryte(i), result.tryte_mut(i)) {
                // Convertir les trytes en trits
                let trits_a = tryte_a.to_trits();
                let trits_b = tryte_b.to_trits();
                let mut xor_trits = [Trit::Z; 3];
                
                // XOR ternaire pour chaque trit
                for j in 0..3 {
                    xor_trits[j] = match (trits_a[j], trits_b[j]) {
                        (Trit::N, Trit::N) => Trit::P,
                        (Trit::N, Trit::Z) => Trit::N,
                        (Trit::N, Trit::P) => Trit::Z,
                        (Trit::Z, Trit::N) => Trit::N,
                        (Trit::Z, Trit::Z) => Trit::Z,
                        (Trit::Z, Trit::P) => Trit::P,
                        (Trit::P, Trit::N) => Trit::Z,
                        (Trit::P, Trit::Z) => Trit::P,
                        (Trit::P, Trit::P) => Trit::N,
                    };
                }
                
                *tryte_result = Tryte::from_trits(xor_trits);
            }
        }
        
        result
    }
}