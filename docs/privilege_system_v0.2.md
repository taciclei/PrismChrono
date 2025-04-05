# Système de Privilèges et CSRs Ternaires v0.2

Ce document définit le système de privilèges et les CSRs (Control and Status Registers) pour l'architecture PrismChrono. Cette implémentation permet la gestion des exceptions et la distinction entre code noyau, code système d'exploitation et code utilisateur.

## Niveaux de Privilège

L'architecture PrismChrono implémente trois niveaux de privilège :

| Niveau | Nom | Description |
|--------|-----|-------------|
| 2 | Machine (M-mode) | Mode le plus privilégié, accès complet au matériel et aux CSRs |
| 1 | Supervisor (S-mode) | Mode intermédiaire, utilisé par le système d'exploitation |
| 0 | User (U-mode) | Mode non privilégié, utilisé par les applications |

Le niveau de privilège actuel est stocké dans le champ `current_privilege` de l'état du processeur. Au démarrage, le processeur démarre en mode Machine (M-mode).

## CSRs Ternaires

Les CSRs (Control and Status Registers) sont des registres spéciaux qui contrôlent et reflètent l'état du processeur. Dans cette implémentation, nous définissons 10 CSRs ternaires :

### CSRs Machine (0-3)

#### 1. `mstatus_t` - Machine Status Register (CSR 0)

| Champ | Trits | Description |
|-------|-------|--------------|
| MPP_t | 2 | Previous Privilege Mode (stocke le niveau de privilège précédent) |
| MIE_t | 1 | Machine Interrupt Enable (non utilisé dans cette version) |
| MPIE_t | 1 | Machine Previous Interrupt Enable (non utilisé dans cette version) |
| Réservé | 20 | Réservé pour usage futur |

Le champ MPP_t stocke le niveau de privilège précédent avant un trap. Il est utilisé par l'instruction MRET pour restaurer le niveau de privilège.

#### 2. `mtvec_t` - Machine Trap Vector Register (CSR 1)

| Champ | Trits | Description |
|-------|-------|--------------|
| BASE_t | 22 | Adresse de base du gestionnaire de trap |
| MODE_t | 2 | Mode de vectorisation (non utilisé dans cette version, toujours 0) |

Le champ BASE_t contient l'adresse de base du gestionnaire de trap. Lorsqu'un trap se produit en mode Machine, le processeur saute à cette adresse.

#### 3. `mepc_t` - Machine Exception Program Counter (CSR 2)

| Champ | Trits | Description |
|-------|-------|--------------|
| EPC_t | 24 | Adresse de l'instruction qui a causé le trap |

Le registre `mepc_t` stocke l'adresse de l'instruction qui a causé le trap. Il est utilisé par l'instruction MRET pour retourner à l'instruction suivante après le traitement du trap.

#### 4. `mcause_t` - Machine Cause Register (CSR 3)

| Champ | Trits | Description |
|-------|-------|--------------|
| CODE_t | 24 | Code de cause du trap |

Le registre `mcause_t` stocke le code de cause du trap.

### CSRs Supervisor (4-7)

#### 5. `sstatus_t` - Supervisor Status Register (CSR 4)

| Champ | Trits | Description |
|-------|-------|--------------|
| SPP_t | 1 | Previous Privilege Mode (stocke le niveau de privilège précédent) |
| SIE_t | 1 | Supervisor Interrupt Enable (non utilisé dans cette version) |
| SPIE_t | 1 | Supervisor Previous Interrupt Enable (non utilisé dans cette version) |
| Réservé | 21 | Réservé pour usage futur |

Le champ SPP_t stocke le niveau de privilège précédent avant un trap en mode Supervisor. Il est utilisé par l'instruction SRET pour restaurer le niveau de privilège.

#### 6. `stvec_t` - Supervisor Trap Vector Register (CSR 5)

| Champ | Trits | Description |
|-------|-------|--------------|
| BASE_t | 22 | Adresse de base du gestionnaire de trap |
| MODE_t | 2 | Mode de vectorisation (non utilisé dans cette version, toujours 0) |

Le champ BASE_t contient l'adresse de base du gestionnaire de trap en mode Supervisor. Lorsqu'un trap délégué se produit, le processeur saute à cette adresse.

#### 7. `sepc_t` - Supervisor Exception Program Counter (CSR 6)

| Champ | Trits | Description |
|-------|-------|--------------|
| EPC_t | 24 | Adresse de l'instruction qui a causé le trap |

Le registre `sepc_t` stocke l'adresse de l'instruction qui a causé le trap en mode Supervisor. Il est utilisé par l'instruction SRET pour retourner à l'instruction suivante après le traitement du trap.

#### 8. `scause_t` - Supervisor Cause Register (CSR 7)

| Champ | Trits | Description |
|-------|-------|--------------|
| CODE_t | 24 | Code de cause du trap |

Le registre `scause_t` stocke le code de cause du trap en mode Supervisor.

### Registres de Délégation (8-9)

#### 9. `medeleg_t` - Machine Exception Delegation Register (CSR 8)

| Champ | Trits | Description |
|-------|-------|--------------|
| DELEG_t | 24 | Bits de délégation pour chaque type d'exception |

Le registre `medeleg_t` contrôle quelles exceptions sont déléguées au mode Supervisor. Chaque trit correspond à un code de cause d'exception. Si le trit est P, l'exception correspondante est déléguée au mode Supervisor.

#### 10. `mideleg_t` - Machine Interrupt Delegation Register (CSR 9)

| Champ | Trits | Description |
|-------|-------|--------------|
| DELEG_t | 24 | Bits de délégation pour chaque type d'interruption |

Le registre `mideleg_t` contrôle quelles interruptions sont déléguées au mode Supervisor. Chaque trit correspond à un code d'interruption. Si le trit est P, l'interruption correspondante est déléguée au mode Supervisor.

## Codes de Cause de Trap

Les codes de cause suivants sont définis :

| Code | Nom | Description |
|------|-----|-------------|
| 0 | EcallU | Appel système depuis U-mode |
| 1 | EcallS | Appel système depuis S-mode |
| 2 | EcallM | Appel système depuis M-mode |
| 3 | IllegalInstr | Instruction illégale |
| 4 | LoadFault | Erreur d'accès mémoire en lecture |
| 5 | StoreFault | Erreur d'accès mémoire en écriture |
| 6 | BreakPoint | Point d'arrêt (instruction EBREAK) |

## Instructions CSR

Deux instructions CSR sont implémentées pour accéder aux CSRs :

1. `CSRRW Rd, csr, Rs1` - CSR Read & Write
   - Lit la valeur actuelle du CSR dans Rd
   - Écrit la valeur de Rs1 dans le CSR

2. `CSRRS Rd, csr, Rs1` - CSR Read & Set
   - Lit la valeur actuelle du CSR dans Rd
   - Effectue un OR bit à bit entre la valeur actuelle du CSR et Rs1, et écrit le résultat dans le CSR

## Instructions de Retour de Trap

### `MRET` - Machine Return

1. Restaure le niveau de privilège depuis `mstatus_t.MPP_t`
2. Restaure le PC depuis `mepc_t`

### `SRET` - Supervisor Return

1. Restaure le niveau de privilège depuis `sstatus_t.SPP_t` (toujours User)
2. Restaure le PC depuis `sepc_t`

## Mécanisme de Trap

Lorsqu'un événement déclencheur survient (instruction illégale, faute d'accès mémoire, ECALL, EBREAK), le processeur :

1. Vérifie si le trap peut être délégué au mode Supervisor en consultant `medeleg_t`
2. Si le trap est délégué et que le niveau de privilège actuel est User :
   - Sauvegarde PC dans `sepc_t`
   - Sauvegarde la cause dans `scause_t`
   - Sauvegarde le privilège actuel dans `sstatus_t.SPP_t`
   - Passe en mode Supervisor
   - Saute à l'adresse contenue dans `stvec_t`
3. Sinon :
   - Sauvegarde PC dans `mepc_t`
   - Sauvegarde la cause dans `mcause_t`
   - Sauvegarde le privilège actuel dans `mstatus_t.MPP_t`
   - Passe en mode Machine
   - Saute à l'adresse contenue dans `mtvec_t`

Le gestionnaire de trap peut alors traiter l'exception et utiliser `MRET` ou `SRET` pour retourner au contexte précédent.

## Règles de Délégation

- Un trap ne peut être délégué que si le niveau de privilège actuel est strictement inférieur au niveau de privilège cible (par exemple, un trap depuis le mode User peut être délégué au mode Supervisor).
- Un trap depuis le mode Supervisor ne peut pas être délégué au mode Supervisor lui-même, il doit être traité en mode Machine.
- Seul le mode Machine peut configurer les registres de délégation.