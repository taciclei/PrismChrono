# Système de Privilèges et CSRs Ternaires v0.1

Ce document définit le système de privilèges et les CSRs (Control and Status Registers) minimalistes pour l'architecture LGBT+. Cette implémentation est volontairement simplifiée pour servir de fondation au mécanisme de trap et à la distinction entre code noyau et code utilisateur.

## Niveaux de Privilège

L'architecture LGBT+ implémente deux niveaux de privilège :

| Niveau | Nom | Description |
|--------|-----|-------------|
| 1 | Machine (M-mode) | Mode le plus privilégié, accès complet au matériel et aux CSRs |
| 0 | User (U-mode) | Mode non privilégié, accès restreint aux ressources |

Le niveau de privilège actuel est stocké dans le champ `current_privilege` de l'état du processeur. Au démarrage, le processeur démarre en mode Machine (M-mode).

## CSRs Ternaires Essentiels

Les CSRs (Control and Status Registers) sont des registres spéciaux qui contrôlent et reflètent l'état du processeur. Dans cette implémentation minimaliste, nous définissons 4 CSRs ternaires essentiels :

### 1. `mstatus_t` - Machine Status Register

| Champ | Trits | Description |
|-------|-------|-------------|
| MPP_t | 2 | Previous Privilege Mode (stocke le niveau de privilège précédent) |
| MIE_t | 1 | Machine Interrupt Enable (non utilisé dans cette version) |
| MPIE_t | 1 | Machine Previous Interrupt Enable (non utilisé dans cette version) |
| Réservé | 20 | Réservé pour usage futur |

Le champ MPP_t stocke le niveau de privilège précédent avant un trap. Il est utilisé par l'instruction MRET_T pour restaurer le niveau de privilège.

### 2. `mtvec_t` - Machine Trap Vector Register

| Champ | Trits | Description |
|-------|-------|-------------|
| BASE_t | 22 | Adresse de base du gestionnaire de trap |
| MODE_t | 2 | Mode de vectorisation (non utilisé dans cette version, toujours 0) |

Le champ BASE_t contient l'adresse de base du gestionnaire de trap. Lorsqu'un trap se produit, le processeur saute à cette adresse.

### 3. `mepc_t` - Machine Exception Program Counter

| Champ | Trits | Description |
|-------|-------|-------------|
| EPC_t | 24 | Adresse de l'instruction qui a causé le trap |

Le registre `mepc_t` stocke l'adresse de l'instruction qui a causé le trap. Il est utilisé par l'instruction MRET_T pour retourner à l'instruction suivante après le traitement du trap.

### 4. `mcause_t` - Machine Cause Register

| Champ | Trits | Description |
|-------|-------|-------------|
| CODE_t | 24 | Code de cause du trap |

Le registre `mcause_t` stocke le code de cause du trap. Les codes de cause suivants sont définis :

| Code | Nom | Description |
|------|-----|-------------|
| 0 | ECALL_U | Appel système depuis U-mode |
| 1 | ECALL_M | Appel système depuis M-mode |
| 2 | IllegalInstr | Instruction illégale |
| 3 | LoadFault | Erreur d'accès mémoire en lecture |
| 4 | StoreFault | Erreur d'accès mémoire en écriture |

## Instructions CSR

Deux instructions CSR sont implémentées pour accéder aux CSRs :

1. `CSRRW_T Rd, csr_t, Rs1` - CSR Read & Write
   - Lit la valeur actuelle du CSR dans Rd
   - Écrit la valeur de Rs1 dans le CSR

2. `CSRRS_T Rd, csr_t, Rs1` - CSR Read & Set
   - Lit la valeur actuelle du CSR dans Rd
   - Effectue un OR bit à bit entre la valeur actuelle du CSR et Rs1, et écrit le résultat dans le CSR

## Instruction de Retour de Trap

L'instruction `MRET_T` est utilisée pour retourner d'un trap :

1. Restaure le niveau de privilège depuis `mstatus_t.MPP_t`
2. Restaure le PC depuis `mepc_t`

## Mécanisme de Trap

Lorsqu'un événement déclencheur survient (instruction illégale, faute d'accès mémoire, ECALL depuis U-Mode), le processeur :

1. Sauvegarde PC dans `mepc_t`
2. Sauvegarde la cause dans `mcause_t`
3. Sauvegarde le privilège actuel dans `mstatus_t.MPP_t`
4. Passe en mode Machine
5. Saute à l'adresse contenue dans `mtvec_t`

Le gestionnaire de trap peut alors traiter l'exception et utiliser `MRET_T` pour retourner au contexte précédent.