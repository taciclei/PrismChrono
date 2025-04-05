## Sprint 14: Systèmes Avancés PrismChrono - MMU Ternaire & Support Parallélisme Initial

**Nom de Code Projet :** PrismChrono
**Composants :** `prismchrono_sim`, `prismchrono_asm` (pour nouvelles instructions), Documentation de Conception

**Objective:** Faire évoluer le simulateur `prismchrono_sim` pour intégrer les mécanismes fondamentaux nécessaires à un système d'exploitation moderne : la **gestion de la mémoire virtuelle via une MMU ternaire (`MMU_T`)** et le **support initial pour le parallélisme via des instructions atomiques ternaires**. Ce sprint implique une phase de **conception architecturale significative** pour définir ces mécanismes dans le contexte ternaire unique de PrismChrono, suivie de leur implémentation dans le simulateur. Le modèle de privilèges M/U/S et les CSRs seront également étendus pour supporter ces nouvelles fonctionnalités.

**State:** Not Started

**Priority:** Très Élevée (Étape fondamentale pour simuler l'exécution d'un noyau avec isolation mémoire et capacités de synchronisation)

**Estimated Effort:** Exceptionnellement Grand (ex: 35-55+ points, T-shirt XXL / Multi-Sprint?) - Nécessite une conception ternaire approfondie et des modifications majeures du simulateur.

**Dependencies:**
*   **Sprint Ω (Fondations Système Simu - si fait):** A potentiellement introduit M/U modes et traps de base. Ce sprint l'étend massivement. *Si Omega n'a pas été fait, ses éléments essentiels (privilèges, traps base) doivent être intégrés ici.*
*   **Sprint 11 (Assembleur Complet - si fait):** L'assembleur devra être mis à jour pour les nouvelles instructions. *Si non fait, ce sprint se concentrera sur la simulation, l'assembleur suivra.*
*   **README / ISA Actuelle:** L'implémentation doit être cohérente avec l'ISA PrismChrono définie (y compris MUL/DIV, flags, etc.).

**Core Concepts:**

1.  **MMU Ternaire (`MMU_T`) Conception & Implémentation :**
    *   **Objectif :** Traduire les adresses virtuelles générées par le CPU en adresses physiques, en appliquant des permissions.
    *   **Conception :**
        *   Définir le **format du CSR `satp_t`** (analogue ternaire de `satp`) : contient le mode de pagination (ex: Bare, Sv24_T?) et l'adresse physique de base de la table de pages racine.
        *   Définir le **format de l'entrée de table de pages ternaire (`PTE_T`)** : Flags (Valid, R, W, X, User, Global, Accessed, Dirty - encodés en trits ?), PPN (Physical Page Number - ternaire).
        *   Définir le **schéma de parcours de table de pages ternaire** (ex: 2 niveaux pour Sv24_T ? Tailles de pages ternaires ?).
        *   Définir les **causes de faute de page** (`mcause_t` étendus).
    *   **Implémentation :**
        *   Module `mmu.rs` avec `fn translate(...)`.
        *   Intégration dans `execute_mem.rs` et `Cpu::fetch`.
        *   Gestion des fautes via le mécanisme de trap.
        *   (Optionnel) TLB simulé simple.
2.  **Support Parallélisme Initial :**
    *   **Objectif :** Permettre la synchronisation basique entre plusieurs threads d'exécution (simulés comme des cœurs).
    *   **Conception :**
        *   Définir la sémantique des **instructions atomiques ternaires** :
            *   `LR.T Rd, (Rs1)` (Load-Reserved Ternary).
            *   `SC.T Rd, Rs2, (Rs1)` (Store-Conditional Ternary): `Rd` reçoit statut (Z=succès, N=échec?).
            *   (Optionnel) Instructions `AMOADD.T`, `AMOSWAP.T`, `AMOMIN.T`, `AMOMAX.T` (naturelles pour PrismChrono).
        *   Définir la sémantique de `FENCE.T` (ordonnancement mémoire - peut être simple au début).
    *   **Implémentation :**
        *   Simulation multi-cœur (modèle séquentiel recommandé pour commencer).
        *   Module `execute_atomic.rs` (?) pour les atomiques, gérant l'état de réservation par cœur.
        *   Implémentation de `FENCE.T`.
3.  **Extension Privilèges & CSRs :**
    *   **Objectif :** Supporter S-mode et les CSRs nécessaires pour MMU et potentiellement la délégation.
    *   **Conception :**
        *   Confirmer/Définir le modèle M/S/U.
        *   Définir les analogues ternaires des CSRs S-mode: `sstatus_t`, `stvec_t`, `sepc_t`, `scause_t`, `satp_t`.
        *   Définir les règles d'accès (quels modes peuvent lire/écrire quels CSRs).
        *   (Optionnel) Définir les CSRs de délégation de trap (`mideleg_t`, `medeleg_t`).
    *   **Implémentation :**
        *   Ajouter état S-mode et CSRs à `ProcessorState`.
        *   Implémenter `SRET_T`.
        *   Mettre à jour `CSRRW`/`CSRRS` pour gérer les nouveaux CSRs et permissions.
        *   Mettre à jour `handle_trap` pour gérer les traps en S-mode et la délégation (si impl.).

**Deliverables:**
*   **Documents de Conception MAJEURS :**
    *   `docs/prismchrono_privilege_v1.0.md` (Modèle M/S/U, CSRs M/S/U, Traps, Délégation).
    *   `docs/prismchrono_mmu_t_v1.0.md` (satp_t, PTE_T, Page Walk, Fautes).
    *   `docs/prismchrono_sync_v1.0.md` (LR.T, SC.T, AMOs?, FENCE.T).
*   **Simulateur (`prismchrono_sim`) mis à jour :**
    *   Support M/S/U, nouveaux CSRs ternaires.
    *   MMU_T fonctionnelle (translation, fautes).
    *   Simulation multi-cœur (2+ cœurs, modèle séquentiel).
    *   Instructions `SRET_T`, `SFENCE.VMA_T`, `FENCE.T`, `LR.T`, `SC.T` (et AMOs optionnels).
*   **Assembleur (`prismchrono_asm`) mis à jour :** Support pour *toutes* les nouvelles instructions et CSRs.
*   **Tests d'Intégration Cruciaux :**
    *   Test d'activation/utilisation de la MMU depuis S-mode.
    *   Test de gestion d'une faute de page (levée, trap vers handler S/M, retour).
    *   Test de spinlock ou compteur atomique utilisant `LR.T`/`SC.T` sur 2+ cœurs simulés.

**Acceptance Criteria (DoD - Definition of Done):**
*   Les 3 documents de conception sont clairs et complets.
*   Le simulateur gère les privilèges M/S/U et les transitions via `MRET_T`/`SRET_T`/Traps.
*   Les CSRs M et S définis sont implémentés et accessibles selon les règles.
*   La **MMU ternaire fonctionne** : les adresses virtuelles sont traduites, les permissions sont vérifiées, les fautes de page génèrent des traps corrects.
*   `SFENCE.VMA_T` est implémentée (même si NOP logique pour TLB simple).
*   Le simulateur exécute **plusieurs cœurs** partageant la mémoire.
*   Les atomiques **`LR.T` et `SC.T`** permettent une synchronisation fonctionnelle (démontrée par test).
*   `FENCE.T` est implémentée (peut être NOP).
*   `prismchrono_asm` assemble le code utilisant les nouvelles instructions/CSRs.
*   Les **3 tests d'intégration clés** (MMU simple, Faute de Page, Spinlock Multi-Cœur) réussissent sur le simulateur.

**Tasks (Haut Niveau - Chacune est un projet en soi):**

*   **[14.1] Conception Architecturale Détaillée:** Rédaction et validation des 3 documents de conception (MMU, Privilèges/CSRs étendus, Synchro). C'est l'étape la plus critique.
*   **[14.2] Implémentation Noyau Simulateur (Privilèges/CSRs):** Mettre à jour `ProcessorState`, `registers.rs`, `privilege.rs` (nouveau?), `trap.rs` pour M/S/U et tous les nouveaux CSRs. Implémenter `SRET_T`. Modifier `execute_system.rs` pour les accès CSR étendus.
*   **[14.3] Implémentation Module MMU (`mmu.rs`):** Écrire la logique de `translate`, Page Table Walk ternaire, parsing `PTE_T`, gestion TLB simple.
*   **[14.4] Intégration MMU (`execute_mem.rs`, `fetch`):** Modifier tous les accès mémoire pour passer par la MMU. Gérer les `PageFault` traps. Implémenter `SFENCE.VMA_T`.
*   **[14.5] Implémentation Multi-Cœur (`main.rs`/`lib.rs`):** Mettre en place la structure `Vec<Cpu>`, le scheduler simple (round-robin séquentiel). Gérer le partage de `Memory` (ex: `Rc<RefCell<Memory>>`).
*   **[14.6] Implémentation Atomics & Fence (`execute_atomic.rs`?):** Ajouter état de réservation par cœur. Implémenter `LR.T`, `SC.T`, `FENCE.T` (et AMOs si décidé).
*   **[14.7] Mise à Jour Assembleur (`prismchrono_asm`):** Ajouter le parsing et l'encodage pour `SRET_T`, `SFENCE.VMA_T`, `FENCE.T`, `LR.T`, `SC.T` (et AMOs?). Gérer les nouveaux CSRs (syntaxe `CSRRW R1, satp_t, R2`?).
*   **[14.8] Écriture Tests d'Intégration:** Coder les scénarios assembleur pour MMU, faute de page, et spinlock multi-cœur.
*   **[14.9] Exécution & Débogage:** Lancer les tests d'intégration, déboguer intensivement les interactions complexes (MMU, traps, privilèges, atomiques).

**Risks & Mitigation:**
*   **(Identique - MAXIMAL)** **Complexité Conception Ternaire:** Risque majeur. -> **Mitigation :** Itérer sur la conception. Commencer par la version la plus simple possible qui *fonctionne*. Documenter les hypothèses. S'inspirer fortement de RISC-V pour la *structure* mais adapter la *sémantique* au ternaire.
*   **(Identique - MAXIMAL)** **Complexité Implémentation Simulateur:** Refonte majeure. -> **Mitigation :** Tests unitaires très forts pour la MMU et les atomiques. Débogage pas-à-pas. Logging intensif. **Envisager de scinder ce sprint en 14a (MMU+Priv Ext) et 14b (Multi-Core+Atomics).**
*   **(Identique - Élevé)** **Débogage :** Problèmes très difficiles à isoler. -> **Mitigation :** Outils de débogage améliorés dans le simulateur (trace d'accès mémoire V/P, trace état TLB, trace état réservation atomique).

**Notes:**
*   Ce sprint est **extrêmement ambitieux** et représente le passage à la simulation de systèmes de type OS.
*   Le succès se mesure par la **faisabilité démontrée** de ces concepts (MMU, atomiques) dans un analogue ternaire simulé, même simplifié.
*   La **qualité de la conception** documentée est primordiale.

**AIDEX Integration Potential:**
*   **Indispensable pour la Conception :** Explorer les implications du ternaire sur les formats PTE, les algorithmes de Page Walk, la sémantique LR/SC. Proposer des solutions ternaires spécifiques.
*   **Architecture du Simulateur :** Suggestions pour intégrer MMU et Multi-Cœur sans trop casser le code existant. Gestion du partage mémoire (`Rc<RefCell>`?).
*   **Implémentation Logique Complexe :** Aide pour le code du Page Table Walker, la logique de réservation/validation SC.T, la gestion des traps étendus.
*   **Tests Complexes :** Aide à écrire les scénarios de test assembleur pour MMU et concurrence, et le code Rust pour les exécuter et valider.
*   **Débogage Stratégique :** Aide à analyser les logs et à identifier les causes profondes des bugs complexes.
```