# Sprint 12: Intégration, Tests End-to-End & Benchmarking Initial

**Nom de Code Projet :** PrismChrono
**Composants :** `prismchrono_asm`, `prismchrono_sim`

**Objective:** Valider l'ensemble de la chaîne d'outils PrismChrono (`assembleur -> simulateur`) en écrivant, assemblant et exécutant des programmes de test **significatifs** et des **micro-benchmarks** standards. Ajouter les fonctionnalités nécessaires au simulateur pour charger le format binaire (`.tbin`), collecter des métriques d'exécution de base (nombre d'instructions, accès mémoire, etc.), et fournir des capacités de débogage minimales. L'objectif final est de réaliser une première **évaluation quantitative et qualitative** des caractéristiques architecturales de PrismChrono sur des tâches concrètes.

**State:** Not Started

**Priority:** Very High (Étape de validation cruciale et première évaluation concrète de l'architecture)

**Estimated Effort:** Very Large (ex: 20-30 points, T-shirt XL - Implique écriture d'assembleur conséquente, ajout de fonctionnalités simu, exécution/analyse de tests)

**Dependencies:**
*   **Sprint 11 (Assembleur Complet):** `prismchrono_asm` est capable d'assembler toute l'ISA v1.0 et de produire un format binaire `.tbin`.
*   **Sprint Ω (Fondations Système Simu):** `prismchrono_sim` gère les privilèges et traps de base.

**Core Concept: Toolchain Validation and Architectural Characterization**

Ce sprint fait le lien entre tous les développements précédents. On utilise l'assembleur pour créer des exécutables ternaires, on améliore le simulateur pour les charger et les analyser, puis on exécute ces programmes pour trouver des bugs et obtenir des premières données objectives sur le comportement de l'architecture PrismChrono.

```mermaid
graph TD
    subgraph Workflow Sprint 12
        direction LR
        A[Programmes Assembleur .s<br/>(Benchmarks, Tests Complexes)] --> B{prismchrono_asm (v1.0)};
        B --> C[Code Machine .tbin];
        C --> D{prismchrono_sim (Amélioré)};

        subgraph D [Simulateur Amélioré]
            direction TB
            D1[Loader .tbin] --> D2[Moteur d'Exécution<br/>(Instrumenté)];
            D2 --> D3[Capacités Débogage<br/>(Dump État, Mémoire)];
            D2 --> D4[Collecte Métriques<br/>(Inst. Count, Mem Ops, Branches)];
        end

        D --> E[Résultats Exécution & Métriques];
        E --> F[Analyse & Validation<br/>(Correction, Bugs, Caractéristiques Archi)];
        F --> G((Rapport de Benchmark Initial & Bugfixes));
    end

    style D fill:#dde,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Simulateur (`prismchrono_sim`) mis à jour :**
    *   Fonctionnalité de chargement pour le format binaire `.tbin`.
    *   Instrumentation pour collecter les métriques clés (Instructions exécutées, Loads, Stores, Branches totales/prises).
    *   Fonctionnalités de débogage minimales (ex: dump des registres et de la mémoire sur `HALT` ou `EBREAK`).
*   **Assembleur (`prismchrono_asm`) mis à jour :** Principalement des corrections de bugs découverts pendant l'intégration.
*   **Suite de Programmes Assembleur (`prismchrono_asm/examples/` ou `benchmarks/`) :**
    *   Au moins 3-4 micro-benchmarks implémentés (ex: Sum Array, Memcpy, Factorial (iter), Linear Search).
    *   Au moins 1-2 tests d'intégration plus complexes (ex: appels de fonctions imbriqués avec gestion de pile, boucle complexe avec conditions).
*   **Scripts de Workflow :** Scripts (`Makefile`, `justfile`, `*.sh`) pour automatiser l'assemblage, le chargement, l'exécution et potentiellement la vérification des résultats pour les benchmarks.
*   **Document de Résultats (`docs/benchmark_initial_results.md`) :** Tableau récapitulant les métriques collectées pour chaque benchmark, accompagné d'une **analyse qualitative** initiale des observations (ex: nombre d'instructions vs complexité perçue, ratio accès mémoire, etc.). Ce document évalue la "viabilité architecturale" (pas la vitesse brute).

**Acceptance Criteria (DoD - Definition of Done):**
*   `cargo build --release` et `cargo test` réussissent pour les deux crates.
*   Le simulateur `prismchrono_sim` peut charger et exécuter des fichiers `.tbin` générés par `prismchrono_asm`.
*   L'instrumentation du simulateur collecte et affiche correctement les métriques (Compteur d'instructions, `LOADW`/`LOADT`/`LOADTU` count, `STOREW`/`STORET` count, `BRANCH` total/pris count).
*   Les fonctionnalités de débogage (au minimum, dump état/mémoire sur `HALT`/`EBREAK`) sont opérationnelles.
*   Au moins **trois** micro-benchmarks sont écrits en assembleur PrismChrono, s'assemblent correctement, et s'exécutent sur le simulateur en produisant le **résultat mathématique/logique attendu** (vérifiable par l'état final de la mémoire ou des registres).
*   Le workflow d'exécution automatisé (via scripts) fonctionne pour les benchmarks.
*   Les métriques de performance architecturales sont collectées pour les benchmarks exécutés et consignées dans le document de résultats.
*   Le document `benchmark_initial_results.md` contient une première analyse des métriques, soulignant les observations intéressantes sur l'ISA et l'architecture (ex: "La factorielle a nécessité X instructions, dont Y% étaient des accès mémoire...", "Le ratio instructions/accès mémoire pour Memcpy est Z...").
*   Les bugs majeurs découverts dans `prismchrono_asm` ou `prismchrono_sim` pendant ce sprint sont corrigés.

**Tasks:**

*   **[12.1] `prismchrono_sim`: Loader `.tbin`:**
    *   Implémenter une fonction `load_tbin(filepath: &str) -> Result<Vec<(Address, Tryte)>, LoadError>` qui lit le format binaire défini au Sprint 11.
    *   Intégrer ce loader dans `main.rs` ou un nouveau binaire de simulation.
*   **[12.2] `prismchrono_sim`: Instrumentation / Métriques:**
    *   Ajouter des compteurs (ex: `u64`) dans `Cpu` ou `ProcessorState` pour : `instructions_executed`, `memory_reads`, `memory_writes`, `branches_total`, `branches_taken`.
    *   Incrémenter `instructions_executed` dans `Cpu::step`.
    *   Incrémenter `memory_reads`/`writes` dans les fonctions `execute_mem.rs` appropriées.
    *   Incrémenter `branches_total`/`taken` dans `execute_branch.rs`.
    *   Ajouter une méthode `cpu.report_metrics()` ou afficher les compteurs à la fin de `cpu.run()`.
*   **[12.3] `prismchrono_sim`: Débogage Minimal:**
    *   Implémenter une fonction `cpu.dump_state()` qui affiche joliment l'état de `ProcessorState` (PC, SP, GPRs R0-R7, Flags FR).
    *   Implémenter une fonction `cpu.dump_memory(start_addr: Address, num_trytes: usize)` qui affiche une plage mémoire.
    *   Modifier la gestion de `HALT` ou `EBREAK` dans `execute_system.rs` pour appeler `dump_state` et `dump_memory` (sur une petite zone autour de SP par ex.) avant de terminer. (Optionnel: ajouter une option CLI pour activer/désactiver ce dump).
*   **[12.4] Assembleur: Écriture Benchmark 1 (ex: Sum Array):**
    *   Écrire `sum_array.s`. Définir un tableau en mémoire (`.word` ou `.tryte`), écrire la boucle pour sommer les éléments dans un registre. Terminer par `HALT`.
*   **[12.5] Assembleur: Écriture Benchmark 2 (ex: Memcpy):**
    *   Écrire `memcpy.s`. Définir une zone source et une zone destination. Écrire la boucle `LOADW`/`STOREW` (ou `LOADT`/`STORET`). Terminer par `HALT`.
*   **[12.6] Assembleur: Écriture Benchmark 3 (ex: Factorial Iterative):**
    *   Écrire `factorial.s`. Prendre une entrée `N` (ex: définie avec `.equ` ou chargée depuis mémoire). Calculer `N!` (suppose `MUL` non dispo -> simuler ou faire pour N petit). Stocker le résultat en mémoire. Terminer par `HALT`.
*   **[12.7] Assembleur: Écriture Test Intégration (ex: Function Call):**
    *   Écrire `func_call.s`. Définir une fonction `main` et une fonction `add_one`. `main` initialise la pile, appelle `add_one` avec un argument sur la pile (convention à définir !), récupère le résultat. `add_one` lit l'argument, ajoute 1, le met sur la pile pour retour, retourne (`JALR`).
*   **[12.8] Workflow & Exécution:**
    *   Créer un `Makefile` ou `justfile` ou script shell.
    *   Ajouter des cibles/commandes pour : `asm(source.s, output.tbin)`, `sim(program.tbin)`, `test_benchmark(benchmark_name)`.
    *   Exécuter tous les benchmarks et tests via le script.
*   **[12.9] Collecte & Analyse Résultats:**
    *   Récupérer les métriques affichées par le simulateur pour chaque benchmark.
    *   Remplir le tableau dans `docs/benchmark_initial_results.md`.
    *   Rédiger une première analyse qualitative : Qu'est-ce que ces chiffres suggèrent ? Points forts/faibles apparents de l'ISA ? Comparaison des ratios (Inst/Mem...).
*   **[12.10] Bug Fixing:** Corriger les problèmes découverts dans `prismchrono_asm` ou `prismchrono_sim` pendant les tests d'intégration.

**Risks & Mitigation:**
*   **Risque :** Écrire de l'assembleur PrismChrono est lent et difficile. -> Commencer par les benchmarks les plus simples. Ne pas viser des algorithmes trop complexes pour ce sprint. Utiliser AIDEX pour aider à générer des squelettes de code assembleur.
*   **Risque :** Des bugs subtils dans l'interaction ISA/Simulateur/Assembleur sont découverts. -> C'est l'objectif ! Allouer du temps pour le débogage. Améliorer les capacités de débogage du simulateur si nécessaire.
*   **Risque :** L'instrumentation affecte (légèrement) la performance du simulateur. -> Accepter ce coût pour l'instant, la mesure est qualitative/comparative, pas de vitesse absolue.
*   **Risque :** Les résultats des benchmarks sont difficiles à interpréter sans point de comparaison binaire direct. -> Se concentrer sur l'analyse *interne* (comparaison entre benchmarks PrismChrono, ratios) et qualitative ("cela semble nécessiter beaucoup d'instructions pour X"). Reporter les comparaisons binaires détaillées à une phase ultérieure.

**Notes:**
*   Ce sprint est l'aboutissement du développement de la base de l'écosystème PrismChrono. Il fournit la première validation holistique.
*   L'évaluation de la "viabilité" est ici architecturale : l'ISA permet-elle d'exprimer ces algorithmes ? Les métriques de base (instruction count, etc.) sont-elles dans des ordres de grandeur raisonnables ?
*   La *vitesse d'exécution* du simulateur lui-même n'est *pas* une métrique pertinente pour l'architecture PrismChrono à ce stade.

**AIDEX Integration Potential:**
*   Génération de squelettes de code assembleur pour les benchmarks.
*   Aide à l'implémentation du loader `.tbin` et des fonctions de débogage dans le simulateur.
*   Suggestions pour l'implémentation de l'instrumentation (où placer les compteurs).
*   Aide à la création des scripts de workflow (Makefile, etc.).
*   Assistance pour l'analyse initiale des métriques collectées (identifier les tendances, les ratios intéressants).
*   Débogage collaboratif des problèmes découverts.
```