# Conception du Pipeline PrismChrono

## Structure du Pipeline à 5 Étages

### 1. IF (Instruction Fetch)
- Récupération de l'instruction à l'adresse PC
- Calcul de PC+4 (ou PC+2 pour instructions compactes)
- Registres IF/ID :
  - PC actuel
  - Instruction
  - PC+4
  - Validité (pour gestion flush)

### 2. ID (Instruction Decode)
- Décodage de l'instruction
- Lecture des registres sources (Rs1, Rs2)
- Extension de l'immédiat
- Registres ID/EX :
  - Données Rs1, Rs2
  - Immédiat étendu
  - Adresse registre destination (Rd)
  - Signaux de contrôle pour EX/MEM/WB
  - PC (pour branches)
  - Validité

### 3. EX (Execute)
- Opération ALU
- Calcul adresse effective (Load/Store/Branch)
- Unité de forwarding
- Registres EX/MEM :
  - Résultat ALU
  - Donnée à écrire en mémoire
  - Adresse Rd
  - Signaux de contrôle pour MEM/WB
  - Condition de branchement
  - Validité

### 4. MEM (Memory Access)
- Accès mémoire (Load/Store)
- Résolution finale des branchements
- Registres MEM/WB :
  - Donnée lue en mémoire
  - Résultat ALU
  - Adresse Rd
  - Signaux de contrôle pour WB
  - Validité

### 5. WB (Write Back)
- Écriture dans le banc de registres
- Sélection source (ALU ou mémoire)

## Gestion des Aléas

### 1. Forwarding (Bypass)

Détection des aléas RAW :
```vhdl
-- Forwarding depuis EX/MEM vers EX
if (ex_mem_reg_write = '1' and ex_mem_rd /= 0 and
    ex_mem_rd = id_ex_rs1) then
    forward_a <= "10"; -- Depuis EX/MEM
elsif (mem_wb_reg_write = '1' and mem_wb_rd /= 0 and
       mem_wb_rd = id_ex_rs1) then
    forward_a <= "01"; -- Depuis MEM/WB
else
    forward_a <= "00"; -- Pas de forwarding
end if;
```

### 2. Stalls

Détection aléa Load-Use :
```vhdl
-- Stall si Load suivi d'utilisation immédiate
if (id_ex_mem_read = '1' and
    (id_ex_rd = if_id_rs1 or id_ex_rd = if_id_rs2)) then
    stall_pipeline <= '1';
else
    stall_pipeline <= '0';
end if;
```

### 3. Flush

Gestion des branchements :
```vhdl
-- Flush sur branchement pris
if (ex_mem_branch = '1' and ex_mem_branch_taken = '1') then
    flush_if_id <= '1';
    flush_id_ex <= '1';
else
    flush_if_id <= '0';
    flush_id_ex <= '0';
end if;
```

## Signaux de Contrôle par Étage

### IF → ID
- `if_id_pc`
- `if_id_instruction`
- `if_id_valid`

### ID → EX
- `id_ex_reg_write`
- `id_ex_mem_read`
- `id_ex_mem_write`
- `id_ex_branch`
- `id_ex_alu_op`
- `id_ex_alu_src`
- `id_ex_rs1_data`
- `id_ex_rs2_data`
- `id_ex_rd`
- `id_ex_imm`
- `id_ex_valid`

### EX → MEM
- `ex_mem_reg_write`
- `ex_mem_mem_read`
- `ex_mem_mem_write`
- `ex_mem_branch_taken`
- `ex_mem_alu_result`
- `ex_mem_write_data`
- `ex_mem_rd`
- `ex_mem_valid`

### MEM → WB
- `mem_wb_reg_write`
- `mem_wb_mem_to_reg`
- `mem_wb_read_data`
- `mem_wb_alu_result`
- `mem_wb_rd`
- `mem_wb_valid`

## Optimisations Futures

1. Prédiction de branchement
2. Gestion plus fine des stalls
3. Support des instructions multi-cycles
4. Bypass supplémentaires (ex: MEM vers MEM pour Store)
5. Optimisation du chemin critique