## Sprint 12 VHDL (PrismChrono): Optimisation Pipeline, Instructions Ternaires Spécialisées & Validation Système

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Raffiner l'implémentation VHDL du cœur `prismchrono_core` en se concentrant sur l'**optimisation du pipeline** (meilleure gestion des aléas, amélioration FMax potentielle) et l'implémentation d'un **premier sous-ensemble d'instructions ternaires spécialisées** (ex: manipulation de trits, comparaison ternaire directe) pour commencer à exploiter les avantages uniques de l'architecture. Valider ces améliorations via des tests et benchmarks plus poussés sur le système complet (CPU+Cache+MMU+DDR).

**State:** Not Started

**Priority:** Élevée (Améliore la performance réelle sur FPGA et commence à différencier PrismChrono)

**Estimated Effort:** Très Large (ex: 20-30 points, T-shirt XL - Optimisation pipeline est complexe, nouvelles instructions, validation système)

**Dependencies:**
*   **Sprint 11 VHDL Terminé :** Cœur pipeliné avec Caches L1 séparés, MMU de base, et accès DDR fonctionnels (au moins en simulation).
*   **ISA PrismChrono (README Simu / Phase 3 / Sprint Futur Instruc) :** Définition et encodage des instructions ternaires spécialisées ciblées (ex: `TCMP3`, `TMIN`, `TMAX`, `TRITINV`, `ABS_T`, `SIGNUM_T`...).
*   **Outils de Synthèse/Timing (Vivado/Yosys+Nextpnr) :** Capacité à analyser les rapports de timing pour identifier les chemins critiques.

**Core Concepts:**
1.  **Optimisation Pipeline :**
    *   **Analyse de Timing :** Utiliser les rapports des outils FPGA pour identifier les chemins critiques limitant la FMax (souvent dans l'ALU, le décodeur, la logique de forwarding/hazard, ou le contrôleur mémoire).
    *   **Rééquilibrage :** Déplacer de la logique combinatoire complexe d'un étage à un autre si possible, ou ajouter des micro-étages (peut nécessiter de passer à un pipeline > 5 étages, mais complexe).
    *   **Amélioration Aléas :** Affiner la logique de forwarding et de stall pour couvrir plus de cas ou réduire les stalls inutiles. Implémenter une prédiction de branchement statique simple (ex: prédire non pris) pour réduire le flush systématique.
2.  **Instructions Ternaires Spécialisées (Sous-Ensemble) :**
    *   Choisir un premier groupe d'instructions ternaires "utiles" et "faisables" en HDL (celles qui n'ajoutent pas une complexité matérielle démesurée initialement).
    *   **Exemples Cibles :**
        *   `TCMP3 Rd, Rs1, Rs2` : Comparaison ternaire directe (résultat N/Z/P dans Rd). Logique combinatoire dans l'ALU.
        *   `TMIN`/`TMAX`/`TRITINV` (Format R) : Si non déjà implémentées comme opérations ALU de base, les ajouter. Logique bit-pair simple.
        *   `ABS_T Rd, Rs1` : Valeur absolue ternaire. Logique simple dans l'ALU (test signe + INV).
        *   `SIGNUM_T Rd, Rs1` : Extraction de signe ternaire. Logique simple.
    *   **Implémentation :** Ajouter les opcodes/fonctions à l'ALU, étendre le décodeur et la Control Unit.
3.  **Validation Système Intégrée :** Utiliser des programmes assembleur plus longs ou des benchmarks (ceux du Sprint 13 simulé) pour tester le CPU optimisé avec cache et MMU dans des scénarios plus réalistes, incluant l'utilisation des nouvelles instructions ternaires.

**Visualisation :** Pas de changement majeur de structure globale, mais raffinement interne du pipeline, de l'ALU, et de la Control Unit.

**Deliverables:**
*   **Code VHDL Optimisé/Étendu :**
    *   Mise à jour `rtl/core/alu_24t.vhd` avec les nouvelles opérations ternaires spécialisées et potentiellement des optimisations de timing.
    *   Mise à jour `rtl/core/control_unit.vhd` et `rtl/core/datapath.vhd` (ou `pipelined_core.vhd`) avec la logique de pipeline affinée (forwarding/stall/flush améliorés) et le support des nouvelles instructions.
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` avec les nouveaux opcodes/fonctions.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** Ajouter le support syntaxique et l'encodage pour les nouvelles instructions ternaires spécialisées implémentées en VHDL.
*   **Testbenches VHDL :**
    *   Mise à jour `sim/testbenches/tb_pipelined_core.vhd` (ou `tb_prismchrono_core_full_system.vhd`) avec des séquences de test utilisant les nouvelles instructions ternaires et testant les cas d'aléas plus complexes.
    *   (Optionnel) Nouveaux testbenches ciblant spécifiquement les optimisations pipeline ou les nouvelles instructions.
*   **Simulation & Synthèse :**
    *   Résultats de simulation validant les optimisations et les nouvelles instructions.
    *   **Rapport de Synthèse/Timing Comparatif :** Comparer l'utilisation des ressources et la FMax obtenue avec celle du Sprint 11 pour évaluer l'impact des optimisations/ajouts.
*   **Documentation :**
    *   Mise à jour `doc/pipeline_design.md` avec les optimisations.
    *   `doc/ternary_instructions_hdl.md` (Nouveau) : Description des instructions ternaires implémentées en VHDL.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent.
*   Les testbenches mis à jour s'exécutent **sans erreur d'assertion**.
*   La simulation démontre :
    *   L'exécution correcte des nouvelles instructions ternaires spécialisées (`TCMP3`, `ABS_T`, etc.).
    *   Un comportement potentiellement amélioré face aux aléas (moins de stalls ou gestion plus fine) grâce aux optimisations pipeline.
*   Le design complet est **synthétisé et implémenté avec succès**, et le **rapport de timing montre une FMax stable ou améliorée** par rapport au Sprint 11 (ou au moins, l'impact des ajouts est compris).
*   `prismchrono_asm` peut assembler le code utilisant les nouvelles instructions.
*   (Bonus) Un benchmark simple montre un gain de performance (moins de cycles) grâce à une instruction ternaire spécialisée par rapport à une séquence d'instructions de base équivalente.
*   La documentation est à jour.

**Tasks:**

*   **[12.1] Analyse de Timing & Plan Optimisation:**
    *   Analyser les rapports de timing du design du Sprint 11 (générés par Vivado ou `nextpnr --timing-driven`). Identifier les 2-3 chemins les plus critiques.
    *   Décider des stratégies d'optimisation : réécriture HDL simple, rééquilibrage pipeline (déplacer logique entre étages), amélioration forwarding/stall.
*   **[12.2] Implémentation Optimisations Pipeline:** Modifier le code VHDL (`control_unit`, `datapath`) pour implémenter les optimisations choisies (ex: prédicteur statique simple, forwarding plus complet, logique de stall affinée).
*   **[12.3] Sélection Instructions Ternaires Spécialisées:** Choisir 3-5 instructions du README Simu (section "Instructions Ternaires Spécialisées") qui sont jugées utiles et *relativement* simples à ajouter à l'ALU/datapath existant (ex: `TCMP3`, `ABS_T`, `SIGNUM_T`, `TMIN`/`TMAX`/`TRITINV` si pas déjà faits).
*   **[12.4] Implémentation Instructions Spécialisées (VHDL):**
    *   Ajouter la logique correspondante dans `alu_24t.vhd` (majoritairement combinatoire).
    *   Ajouter les opcodes/fonctions dans `prismchrono_types_pkg.vhd`.
    *   Mettre à jour le décodeur et la FSM (`control_unit.vhd`) pour gérer ces nouvelles instructions.
*   **[12.5] Mise à Jour Assembleur:** Ajouter le support syntaxique et l'encodage pour les nouvelles instructions ternaires dans `prismchrono_asm`.
*   **[12.6] Mise à Jour Testbenches:**
    *   Ajouter des séquences de test dans `tb_pipelined_core.vhd` (ou autre) qui utilisent les nouvelles instructions et vérifient leur résultat.
    *   Ajouter des tests qui ciblent spécifiquement les optimisations pipeline (ex: vérifier qu'un stall précédemment nécessaire a disparu grâce au forwarding amélioré).
*   **[12.7] Simulation & Débogage:** Exécuter les simulations étendues. Déboguer les nouvelles instructions et les optimisations pipeline via GTKWave.
*   **[12.8] Synthèse, Implémentation & Analyse Timing (Itératif):**
    *   Lancer la chaîne FPGA complète.
    *   Comparer les rapports de ressources et de timing avec le Sprint 11.
    *   Si la FMax a régressé ou si des violations de timing apparaissent, analyser et itérer sur les optimisations HDL (Tâches 12.1/12.2).
*   **[12.9] Documentation:** Mettre à jour les documents de conception. Créer `ternary_instructions_hdl.md`.

**Risks & Mitigation:**
*   **Risque :** Optimisations de timing difficiles ou peu efficaces sans refonte majeure. -> **Mitigation :** Se concentrer sur les gains faciles. Accepter une FMax modeste si le design est fonctionnel. Documenter les chemins critiques restants pour de futures optimisations.
*   **Risque :** L'ajout de nouvelles instructions complexifie trop la Control Unit ou l'ALU, impactant le timing. -> **Mitigation :** Choisir des instructions spécialisées simples pour commencer. Bien modulariser leur implémentation.
*   **Risque :** Le débogage du pipeline optimisé devient encore plus complexe. -> **Mitigation :** Ajouter plus de signaux de debug internes visibles dans le VCD. Tests très ciblés.

**Notes:**
*   Ce sprint commence à réaliser la promesse "Prism" de l'architecture en exploitant le ternaire de manière plus directe en matériel.
*   L'optimisation des performances (FMax) devient un objectif concret, même si la fonctionnalité reste prioritaire.
*   C'est un bon moment pour refactoriser et nettoyer le code VHDL avant d'ajouter des fonctionnalités encore plus complexes (MMU avancée, Multi-Cœur réel, Caches L2...).

**AIDEX Integration Potential:**
*   Analyse assistée des rapports de timing pour identifier les chemins critiques.
*   Suggestions d'optimisation VHDL pour la performance (réécriture de logique, pipelining interne de calculs).
*   Aide à l'implémentation VHDL des instructions ternaires spécialisées.
*   Génération de code assembleur utilisant ces nouvelles instructions pour les testbenches.
*   Débogage assisté des problèmes de timing ou des erreurs logiques dans le pipeline optimisé.