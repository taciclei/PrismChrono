Okay, let's refine the description for **Sprint "Omega"**, incorporating the new project name "PrismChrono" and adding more detail based on your current code structure.

---

## Sprint Ω (Omega): Fondations Système PrismChrono (Privilèges & Traps Simplifiés)

*   **Nom de Code :** Sprint Ω (Omega) - Le dernier sprint dans `prismChrono_sim` avant la transition majeure vers l'assembleur `prismChrono_asm`.
*   **Objectif :** Établir les fondations architecturales **minimales** dans le simulateur `prismChrono_sim` pour la gestion des **niveaux de privilège (Machine/User)** et un mécanisme de **"trap"** (exception/syscall) contrôlé. Ceci afin de préparer le terrain pour l'exécution de code plus structuré (noyau vs application) qui sera généré par l'assembleur.
*   **Motivation :** Ajouter la couche de contrôle et de protection la plus fondamentale, permettant au simulateur d'exécuter un micro-noyau interagissant via des appels système simulés, rendant ainsi la plateforme plus réaliste avant de générer du code pour elle.
*   **Portée :**
    *   **Inclus :**
        *   Deux niveaux de privilège (`Machine`, `User`).
        *   4 CSRs ternaires *ultra-minimalistes* (`mstatus_t`, `mtvec_t`, `mepc_t`, `mcause_t`) pour gérer l'état des traps.
        *   Mécanisme de trap centralisé déclenché par :
            *   `ECALL` depuis User-mode.
            *   Instruction illégale (opcode inconnu, instruction privilégiée en User-mode).
            *   Erreurs d'accès mémoire (hors limites, mauvais alignement - si non géré comme erreur fatale).
        *   Instruction de retour de trap (`MRET_T`).
        *   Instructions CSR minimales (`CSRRW_T`, `CSRRS_T`) pour accéder aux CSRs définis.
    *   **Exclus :** Pas de MMU/mémoire virtuelle, pas d'interruptions (externes, timer, logiciel - `EBREAK` peut rester une simple pause/halt pour l'instant), pas de gestion complexe des CSRs standards RISC-V, pas de multi-cœur.
*   **Dépendances :** Sprint 9 (PrismChrono ISA Base ≈ RV32I) terminé. Toutes les instructions de base sont dans `execute_alu.rs`, `execute_mem.rs`, `execute_branch.rs`, `execute_system.rs`. `ECALL`/`EBREAK` existent mais leur gestion sera modifiée.

*   **Tâches Clés :**

    1.  **[Architecture & Docs] Définition Privilèges & CSRs Minimalistes :**
        *   **Tâche :** Créer `docs/prismchrono_privilege_v0.1.md`. Documenter :
            *   Les 2 niveaux (`Machine`, `User`) et leurs capacités.
            *   Les 4 CSRs ternaires :
                *   `mstatus_t` (Word): Champs simplifiés (ex: `MPP_t` [1 trit: M/U], `MIE_t` [1 trit: P=on/N=off]).
                *   `mtvec_t` (Word): Adresse base du handler (champ adresse 16t).
                *   `mepc_t` (Word): PC sauvegardé lors du trap (champ adresse 16t).
                *   `mcause_t` (Word): Code cause (valeurs ternaires distinctes pour `ECALL_U`, `ECALL_M`, `IllegalInstruction`, `LoadAddressMisaligned`, `LoadAccessFault`, `StoreAddressMisaligned`, `StoreAccessFault`).
        *   **Livraison :** Fichier `docs/prismchrono_privilege_v0.1.md`.

    2.  **[CPU State] Implémentation État Privilège & CSRs :**
        *   **Tâche :** Dans `src/cpu/registers.rs`:
            *   Ajouter `pub enum PrivilegeLevel { Machine, User }`.
            *   Ajouter à `ProcessorState`:
                *   `pub current_privilege: PrivilegeLevel`,
                *   `pub mstatus_t: Word`,
                *   `pub mtvec_t: Word`,
                *   `pub mepc_t: Word`,
                *   `pub mcause_t: Word`.
            *   Dans `ProcessorState::new()`, initialiser `current_privilege = PrivilegeLevel::Machine`, et les CSRs à Zéro (ou valeurs par défaut logiques).
        *   **Livraison :** Code `src/cpu/registers.rs` mis à jour et testé (compilation).

    3.  **[ISA & Exécution] Instructions CSR Ultra-Minimales (`CSRRW_T`, `CSRRS_T`) :**
        *   **Tâche :**
            *   Définir un encodage pour `CSRRW_T Rd, csr_idx, Rs1` et `CSRRS_T Rd, csr_idx, Rs1`. Comment `csr_idx` (index ou ID ternaire des 4 CSRs) est-il encodé dans les 12 trits ? (Ex: utiliser un format I modifié où `imm5` encode le CSR ? Ou OpCode dédié ?).
            *   Implémenter leur logique dans `src/cpu/execute_system.rs`.
            *   Ajouter la vérification des privilèges : lecture permise en U/M pour la plupart, écriture seulement en M-mode pour `mstatus_t`, `mtvec_t`. Déclencher `TrapCause::IllegalInstruction` si accès non autorisé.
        *   **Livraison :** Code `src/cpu/isa.rs` (enum `Instruction`), `src/cpu/decode.rs`, `src/cpu/execute_system.rs`. Nouveaux tests unitaires dans `src/cpu/tests/execute_system_tests.rs`.

    4.  **[CPU Core & Exécution] Logique de Trap Centralisée :**
        *   **Tâche :**
            *   Définir `enum TrapCause { ECALL_U, ECALL_M, IllegalInstruction, LoadAddressMisaligned, ... }` (probablement dans `isa.rs` ou `cpu/mod.rs`).
            *   Modifier les fonctions `execute_*` (dans `execute_alu.rs`, `execute_mem.rs`, `execute_system.rs`, `decode.rs`) : au lieu de `Err(ExecuteError::SomeProblem)`, retourner `Ok(ExecutionStatus::Trap(TrapCause::SomeProblem))`. `Ok(ExecutionStatus::Executed)` pour succès normal.
            *   Créer `src/cpu/trap.rs` (ou dans `execute_core.rs`) avec `fn handle_trap(cpu: &mut Cpu, cause: TrapCause)`.
            *   Implémenter la logique dans `handle_trap`: lire `cpu.state.pc`, `cpu.state.current_privilege`, les sauvegarder dans `mepc_t`, `mstatus_t.MPP_t`, mettre la `cause` dans `mcause_t`, forcer `cpu.state.current_privilege = PrivilegeLevel::Machine`, lire `cpu.state.mtvec_t`, mettre `cpu.state.pc = mtvec_t_address`.
            *   Modifier `Cpu::step` dans `src/cpu/execute_core.rs` pour appeler `handle_trap` si `execute` retourne `ExecutionStatus::Trap`.
        *   **Livraison :** Nouveau `enum ExecutionStatus`, refonte des retours des `execute_*`, nouveau module/fonction `trap.rs`/`handle_trap`, `Cpu::step` mis à jour.

    5.  **[ISA & Exécution] Implémentation `MRET_T` :**
        *   **Tâche :** Définir l'encodage de `MRET_T` (OpCode système dédié ?). L'implémenter dans `src/cpu/execute_system.rs`.
        *   **Logique :** Vérifier privilège M-mode. Lire `cpu.state.mepc_t` et `cpu.state.mstatus_t`. Restaurer `cpu.state.pc` depuis `mepc_t`. Restaurer `cpu.state.current_privilege` depuis le champ `MPP_t` de `mstatus_t`. (Optionnel: gérer `MIE_t`).
        *   **Livraison :** Code `isa.rs`, `decode.rs`, `execute_system.rs`. Test unitaire dans `execute_system_tests.rs`.

    6.  **[Exécution] Renforcement des Vérifications de Privilège :**
        *   **Tâche :** Ajouter explicitement la vérification `if self.state.current_privilege != PrivilegeLevel::Machine { return Ok(ExecutionStatus::Trap(TrapCause::IllegalInstruction)); }` au début des fonctions `execute_*` pour les instructions privilégiées (`MRET_T`, écritures CSRs critiques).
        *   **Livraison :** Code `execute_system.rs` (et autres si pertinent) mis à jour.

    7.  **[ECALL] Raffinement Gestion `ECALL` :**
        *   **Tâche :** Dans `src/cpu/execute_system.rs`, pour `Instruction::Ecall`:
            *   Si `cpu.state.current_privilege == PrivilegeLevel::User`, retourner `Ok(ExecutionStatus::Trap(TrapCause::ECALL_U))`.
            *   Si `cpu.state.current_privilege == PrivilegeLevel::Machine`, retourner `Ok(ExecutionStatus::Trap(TrapCause::ECALL_M))`.
            *   Supprimer toute logique de side-effect (ex: `println!`) qui était là avant.
        *   **Livraison :** Code `execute_system.rs` mis à jour pour `Ecall`.

    8.  **[Simulateur] Fonctionnalité de Chargement Améliorée :**
        *   **Tâche :** Créer une fonction (ex: dans `src/lib.rs` ou `src/main.rs`) `load_ternary_program(memory: &mut Memory, program: &[(Address, Vec<Tryte>)]) -> Result<(), LoadError>` qui prend une liste de segments (adresse de départ, données ternaires) et les charge en mémoire.
        *   **Livraison :** Nouvelle fonction de chargement.

    9.  **[Tests] Test Intégré "Proto-Noyau" :**
        *   **Tâche :** Créer un nouveau fichier binaire de test : `src/bin/test_privilege_switch.rs`.
            *   Définir manuellement `Vec<Tryte>` pour le code M-mode (`KERNEL_CODE`) et U-mode (`USER_CODE`). Adresses: `KERNEL_START = 0`, `USER_CODE_START = 100` (par exemple).
            *   `KERNEL_CODE` doit :
                1.  Utiliser `LUI`/`ADDI` pour mettre l'adresse du handler `TRAP_HANDLER` dans R1.
                2.  Utiliser `CSRRW_T R0, mtvec_t, R1` pour configurer le vecteur de trap.
                3.  Utiliser `LUI`/`ADDI` pour mettre `USER_CODE_START` dans R1.
                4.  Utiliser `CSRRW_T R0, mepc_t, R1` pour définir le retour en U-mode.
                5.  Lire `mstatus_t` dans R1 (`CSRRS_T R1, mstatus_t, R0`).
                6.  Modifier R1 pour mettre `MPP_t` à `User`. (Nécessite des opérations logiques ou de décalage non définies ? Alternative: préparer une valeur complète pour `mstatus_t` et utiliser `CSRRW_T`). -> **Simplification:** On peut juste préparer la valeur `mstatus_t` complète avec `MPP=User` dans un registre et l'écrire avec `CSRRW_T`.
                7.  `MRET_T`.
            *   `TRAP_HANDLER` (partie de `KERNEL_CODE`) doit:
                1.  Lire `mcause_t` (`CSRRS_T R1, mcause_t, R0`).
                2.  Comparer R1 avec `ECALL_U_CODE` (`ADDI` R2, R0, ECALL_U_CODE; `CMP` R1, R2).
                3.  Si égal (`BRANCH EQ`), simuler l'action (ex: `ADDI R7, R7, 1` pour compter les syscalls).
                4.  Lire `mepc_t` dans R1 (`CSRRS_T R1, mepc_t, R0`).
                5.  Ajouter 4 au PC sauvegardé (`ADDI R1, R1, 4`).
                6.  Écrire le PC+4 dans `mepc_t` (`CSRRW_T R0, mepc_t, R1`).
                7.  `MRET_T`.
            *   `USER_CODE` doit :
                1.  Faire une opération simple (ex: `ADDI R3, R3, 1`).
                2.  `ECALL`.
                3.  Faire une autre opération (ex: `ADDI R4, R4, 1`).
                4.  (Optionnel) Exécuter une instruction invalide (OpCode bidon).
                5.  Boucler ou `HALT`.
            *   Le test Rust doit :
                1.  Créer `Memory` et `ProcessorState`.
                2.  Utiliser `load_ternary_program` pour charger `KERNEL_CODE` à 0 et `USER_CODE` à 100.
                3.  Créer `Cpu` et appeler `cpu.run()` (ou `step` par `step`).
                4.  Ajouter des `println!` dans le *simulateur* (ex: dans `handle_trap`, `MRET_T`, `CSRRW_T`) pour tracer ce qui se passe.
                5.  Après `run`, vérifier l'état final (ex: R7 a été incrémenté ? Le PC est où ?).
        *   **Livraison :** Fichier `src/bin/test_privilege_switch.rs` fonctionnel.

*   **Definition of Done (DoD) :**
    *   Le simulateur gère `Machine` et `User` modes.
    *   Les 4 CSRs minimalistes sont implémentés et modifiables/lisibles via `CSRRW_T`/`CSRRS_T` (avec contrôle de privilège).
    *   Les traps (ECALL U-mode, IllegalInstr, MemoryFaults) déclenchent `handle_trap` qui met à jour les CSRs, passe en M-mode et saute à `mtvec_t`.
    *   `MRET_T` retourne correctement au contexte et privilège précédents.
    *   `ECALL` ne provoque plus d'effet de bord direct dans le simulateur mais trap.
    *   La fonction `load_ternary_program` permet de charger plusieurs segments.
    *   Le test `test_privilege_switch.rs` (avec code machine manuel) s'exécute et valide le flux M->U->ECALL->M(Handler)->U.

*   **Intégration AIDEX :** (Identique à la version précédente, mais avec des noms de fichiers/modules mis à jour si besoin).

---

Cette version "Omega" est plus précise sur les livrables (fichiers Rust, documentation), détaille la logique de trap et de test, et utilise le nouveau nom de projet. Elle fournit une base solide pour que le futur assembleur puisse générer du code qui interagira avec ce système de privilèges et d'exceptions minimal.