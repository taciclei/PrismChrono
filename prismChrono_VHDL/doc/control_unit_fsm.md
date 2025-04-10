# Documentation de l'Unité de Contrôle (FSM) pour PrismChrono

## Introduction

L'unité de contrôle est le cœur du processeur PrismChrono. Elle est implémentée sous forme d'une machine à états finis (FSM - Finite State Machine) qui séquence le cycle d'instruction et génère les signaux de contrôle appropriés pour le datapath. Cette documentation décrit le fonctionnement de la FSM, ses états et les transitions entre ces états.

## Diagramme d'États

```
+-------+     +-------+     +---------+
| RESET | --> | FETCH | --> | DECODE  |
+-------+     +-------+     +---------+
                                |
                                v
                          +-----------+
                     +--> | EXEC_NOP  | --+
                     |    +-----------+   |
                     |                    |
                     |    +-----------+   |
                     |    | EXEC_ADDI | --|--> +----------+
                     |    +-----------+   |    | WB_ADDI  | --+
                     |                    |                   |
                     |    +-----------+   |                   |
                     |    | EXEC_JAL  | --|--> +----------+  |
                     |    +-----------+   |    | WB_JAL   |  |
                     |                    |                |  |
                     |    +-----------+   |                |  |
                     |    | EXEC_JALR | --|--> +----------+  |
                     |    +-----------+   |                   |
                     |                    |                   |
                     |    +-----------+   |                   |
                     |    | EXEC_BRANCH | +                   |
+---------+          |    +-----------+                       |
| HALTED  | <--------+                                        |
+---------+          |                                        |
    ^                +----------------------------------------+
    |                                     |
    +-------------------------------------+
```

## Description des États

### RESET
État initial après un reset du système. Aucun signal de contrôle n'est actif dans cet état.

### FETCH
État de récupération de l'instruction depuis la mémoire d'instructions. Le signal `mem_read` est activé pour lire l'instruction à l'adresse pointée par le PC (Program Counter).

### DECODE
État de décodage de l'instruction. L'opcode est extrait et utilisé pour déterminer l'état suivant.

### EXEC_NOP
État d'exécution de l'instruction NOP (No Operation). Le PC est incrémenté, mais aucune autre opération n'est effectuée.

### EXEC_ADDI
État d'exécution de l'instruction ADDI (Add Immediate). L'ALU est configurée pour effectuer une addition entre le registre source (Rs1) et la valeur immédiate.

### EXEC_JAL
État d'exécution de l'instruction JAL (Jump And Link). L'adresse cible est calculée (PC + offset*4) et le PC est chargé avec cette valeur. L'adresse de retour (PC+1) est préparée pour être écrite dans le registre destination (Rd).

### EXEC_JALR
État d'exécution de l'instruction JALR (Jump And Link Register). L'adresse cible est calculée ((Rs1 + offset) & AlignMask(4)) et le PC est chargé avec cette valeur. L'adresse de retour (PC+1) est préparée pour être écrite dans le registre destination (Rd).

### EXEC_BRANCH
État d'exécution de l'instruction BRANCH (branchement conditionnel). La condition de branchement est évaluée en fonction des flags de l'ALU. Si la condition est vraie, l'adresse cible est calculée (PC + offset*4) et le PC est chargé avec cette valeur. Sinon, le PC est simplement incrémenté.

### WB_ADDI
État de write-back pour l'instruction ADDI. Le résultat de l'ALU est écrit dans le registre destination (Rd) et le PC est incrémenté.

### WB_JAL
État de write-back pour l'instruction JAL. L'adresse de retour (PC+1) est écrite dans le registre destination (Rd).

### WB_JALR
État de write-back pour l'instruction JALR. L'adresse de retour (PC+1) est écrite dans le registre destination (Rd).

### HALTED
État d'arrêt du CPU après l'exécution d'une instruction HALT. Le signal `halted` est activé et le CPU reste dans cet état jusqu'à un reset.

## Transitions d'États

- **RESET → FETCH**: Transition automatique après un reset.
- **FETCH → DECODE**: Transition automatique après la récupération de l'instruction.
- **DECODE → EXEC_NOP**: Si l'opcode est NOP.
- **DECODE → EXEC_ADDI**: Si l'opcode est ADDI.
- **DECODE → EXEC_JAL**: Si l'opcode est JAL.
- **DECODE → EXEC_JALR**: Si l'opcode est JALR.
- **DECODE → EXEC_BRANCH**: Si l'opcode est BRANCH.
- **DECODE → HALTED**: Si l'opcode est HALT.
- **EXEC_NOP → FETCH**: Transition automatique après l'exécution de NOP.
- **EXEC_ADDI → WB_ADDI**: Transition automatique après l'exécution de ADDI.
- **EXEC_JAL → WB_JAL**: Transition automatique après l'exécution de JAL.
- **EXEC_JALR → WB_JALR**: Transition automatique après l'exécution de JALR.
- **EXEC_BRANCH → FETCH**: Transition directe après l'évaluation de la condition et la mise à jour du PC.
- **WB_ADDI → FETCH**: Transition automatique après le write-back.
- **WB_JAL → FETCH**: Transition automatique après le write-back.
- **WB_JALR → FETCH**: Transition automatique après le write-back.
- **HALTED → HALTED**: Le CPU reste dans l'état HALTED jusqu'à un reset.

## Signaux de Contrôle

Les signaux de contrôle générés par la FSM dépendent de l'état courant :

### FETCH
- `mem_read = '1'` : Activer la lecture mémoire pour récupérer l'instruction.

### EXEC_NOP
- `pc_inc = '1'` : Incrémenter le PC.

### EXEC_ADDI
- `alu_op = OP_ADD` : Configurer l'ALU pour l'addition.
- `alu_src_a = '0'` : Source A = registre source 1 (Rs1).
- `alu_src_b = '1'` : Source B = valeur immédiate.

### EXEC_JAL
- `pc_load = '1'` : Charger une nouvelle valeur dans le PC.
- `pc_src = "10"` : Source = adresse cible JAL (PC + offset*4).

### EXEC_JALR
- `pc_load = '1'` : Charger une nouvelle valeur dans le PC.
- `pc_src = "01"` : Source = adresse cible JALR ((Rs1 + offset) & AlignMask(4)).

### EXEC_BRANCH
- `branch_taken` : Signal indiquant si le branchement est pris (basé sur l'évaluation de la condition).
- Si `branch_taken = '1'` :
  - `pc_load = '1'` : Charger une nouvelle valeur dans le PC.
  - `pc_src = "11"` : Source = adresse cible BRANCH (PC + offset*4).
- Si `branch_taken = '0'` :
  - `pc_inc = '1'` : Incrémenter le PC normalement.

### WB_ADDI
- `reg_write = '1'` : Activer l'écriture dans le banc de registres.
- `reg_dst = "00"` : Destination = registre destination (Rd).
- `reg_src = "00"` : Source = résultat de l'ALU.
- `pc_inc = '1'` : Incrémenter le PC.

### WB_JAL
- `reg_write = '1'` : Activer l'écriture dans le banc de registres.
- `reg_dst = "00"` : Destination = registre destination (Rd).
- `reg_src = "10"` : Source = PC+1 (adresse de retour).

### WB_JALR
- `reg_write = '1'` : Activer l'écriture dans le banc de registres.
- `reg_dst = "00"` : Destination = registre destination (Rd).
- `reg_src = "10"` : Source = PC+1 (adresse de retour).

### HALTED
- `halted = '1'` : Indiquer que le CPU est arrêté.

## Conclusion

L'unité de contrôle FSM implémentée pour le processeur PrismChrono permet d'exécuter un ensemble complet d'instructions incluant les opérations arithmétiques (ADDI), les sauts inconditionnels (JAL, JALR) et les branchements conditionnels (BRANCH) en séquençant correctement les opérations et en générant les signaux de contrôle appropriés pour le datapath. 

La gestion du contrôle de flux (sauts et branchements) rend le processeur Turing-complet, lui permettant d'exécuter des algorithmes arbitraires avec des boucles et des conditions. Cette conception modulaire et extensible permettra d'ajouter facilement de nouvelles instructions dans les sprints futurs, notamment les instructions de chargement et de stockage en mémoire.