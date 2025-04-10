
# Sprint 13 VHDL (PrismChrono): Interruptions Asynchrones, Atomics & Introduction Format Compact

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Augmenter significativement les capacités système et potentiellement la densité de code du cœur `prismchrono_core` en :
1.  Implémentant la **gestion des interruptions asynchrones** (Timer et Externes simples), essentiel pour les systèmes d'exploitation préemptifs.
2.  Finalisant le support des **instructions atomiques ternaires (`LR.T`/`SC.T` et potentiellement les AMOs)** pour une synchronisation robuste.
3.  **(Objectif Étendu/Optionnel)** Commençant l'intégration du **format d'instruction compact 8 trits (Format C)** pour améliorer la densité de code, en modifiant les étages Fetch et Decode du pipeline.
Tout en continuant à rechercher des **optimisations de performance (FMax)** et des moyens d'**exploiter la logique ternaire**.

**State:** Not Started

**Priority:** Très Élevée (Interruptions indispensables pour OS préemptif, Atomics pour synchro, Compressé pour densité/cache)

**Estimated Effort:** Très Large (ex: 25-40 points, T-shirt XL/XXL - Interruptions + Atomics + Début Format C est un gros morceau avec des interactions pipeline complexes)

**Dependencies:**
*   **Sprint 12 VHDL Terminé :** Cœur pipeliné avec Cache L1, MMU de base, accès DDR, ISA de base (incluant MUL), privilèges M/S/U, traps synchrones fonctionnels. Potentielles optimisations pipeline déjà en place.
*   **ISA PrismChrono Complète :** Définition précise des mécanismes d'interruption (CSRs `m/sie`, `m/sip`, `m/sideleg`, `m/scounteren` analogues ternaires), des instructions atomiques (`LR.T`, `SC.T`, `AMO*.T` ternaires), et l'encodage/sémantique des instructions compactes 8 trits.
*   **Carte FPGA :** Pins GPIO disponibles pour simuler des interruptions externes.

**Core Concepts:**
1.  **Interruptions Asynchrones :**
    *   **Détection :** La Control Unit doit vérifier *à chaque cycle* (ou à un point précis du pipeline, ex: fin de WB) si une interruption autorisée (`mip & mie`, en tenant compte du niveau de privilège et délégation) est pendante.
    *   **Mécanisme de Trap Modifié :** Si une interruption est détectée et doit être prise, le pipeline doit être "interrompu" *entre deux instructions*. L'instruction en cours d'exécution termine (jusqu'à WB?), le PC de l'instruction *suivante* est sauvegardé dans `m/sepc`, la cause mise à jour (`m/scause` avec code d'interruption), le privilège géré, et le CPU saute au handler (`m/stvec`).
    *   **Sources :**
        *   **Timer :** Implémenter un compteur VHDL (`mcycle`/`time`?) et un comparateur (`mtimecmp`) mappés à des CSRs. Générer une interruption timer (`MTIP`/`STIP`) quand `mtime >= mtimecmp`.
        *   **Externe :** Ajouter une logique simple (PLIC simulé minimal) connectée à quelques pins GPIO de la carte. Un changement sur ces pins lève une interruption externe (`MEIP`/`SEIP`).
    *   **CSRs :** Implémenter les analogues ternaires de `mie`, `mip`, `sie`, `sip`, `mideleg`, `medeleg` (si non déjà fait), `m/scounteren`.
2.  **Instructions Atomiques Ternaires (A) :**
    *   Finaliser et tester `LR.T`/`SC.T` en interaction avec le cache L1 et la mémoire DDR. Gérer l'invalidation de la réservation (`LR`) lors d'écritures concurrentes (simulées) ou de changements de contexte.
    *   **(Optionnel) AMOs Ternaires :** Implémenter `AMOADD.T`, `AMOSWAP.T`, `AMOMIN.T`, `AMOMAX.T`... Nécessite une unité ALU/mémoire capable de lire-modifier-écrire atomiquement. Peut nécessiter des stalls ou une logique de verrouillage du bus/cache.
3.  **Format Compact 8 Trits (C) - Introduction :**
    *   **Modification Fetch (IF) :** L'étage IF doit pouvoir lire soit 8 trits, soit 12 trits, potentiellement en fonction des premiers trits de l'instruction ou d'un buffer d'alignement/pré-décodage. Gérer l'incrémentation du PC (variable : +2 ou +3 Trytes? L'ISA compacte utilise-t-elle des adresses alignées sur 2 trytes ?). *Simplification : Peut-être que IF fetch toujours 12t et ID détermine si c'est 8t ou 12t?*
    *   **Modification Decode (ID) :** Décodeur principal doit reconnaître les opcodes 8t et 12t. Il doit extraire les champs (plus petits) des instructions 8t et générer les signaux de contrôle appropriés. Un décodeur d'instruction compact séparé peut être nécessaire.
    *   **Impact Pipeline :** Gérer la longueur variable peut introduire des bulles ou nécessiter une logique de contrôle plus complexe.
4.  **Optimisation Continue :** Poursuivre l'analyse de timing et les micro-optimisations pour améliorer la FMax.

**Visualisation des Points d'Intégration :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Évolution Majeure]
        %% Interrupt Handling
        External_Pins(FPGA GPIO Pins) --> PLIC_Simple(PLIC Simplifié);
        Timer_Unit(Timer Unit<br/>(mtime/mtimecmp)) --> INT_Logic(Interrupt Logic);
        PLIC_Simple --> INT_Logic;
        INT_Logic -- Interrupt Pending? --> CU(Control Unit);
        CU -- Interrupt Ack/Control --> INT_Logic;
        CSR_Module -- mie/mip/sie/sip/deleg --> INT_Logic;
        CU -- Trigger Async Trap --> Trap_Handling_Logic;

        %% Atomics
        MEM_Stage <--> L1_CACHE;
        L1_CACHE <--> MEM_CTRL;
        Atomic_Unit(Atomic Unit<br/>(LR/SC, AMOs?)) -- Interacts with --> MEM_Stage;
        Atomic_Unit -- Interacts with --> L1_CACHE; %% Cache coherence/reservation handling

        %% Compact Instructions
        IF_Stage -- Fetches 8t/12t? --> Instr_Buffer(Instruction Buffer/Aligner?);
        Instr_Buffer --> ID_Stage;
        ID_Stage -- Decodes 8t/12t --> CU;
        CU -- Variable PC Inc --> PC_Reg;
    end

    style INT_Logic fill:#fec,stroke:#333,stroke-width:1px
    style Atomic_Unit fill:#ffc,stroke:#333,stroke-width:1px
    style Instr_Buffer fill:#eef,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL Mis à Jour :**
    *   `rtl/core/control_unit.vhd` / `rtl/core/trap.rs` : Logique de détection et de gestion des interruptions asynchrones, intégration avec traps synchrones, gestion délégation. Potentiellement modifié pour support C.
    *   `rtl/core/pipeline_stages.vhd` (ou équivalent) : Modifications IF/ID pour le format C.
    *   `rtl/csr/csr_registers.vhd` : Ajout/Finalisation des CSRs d'interruption (`mie`, `mip`, etc.) et de timer.
    *   `rtl/timer/timer_unit.vhd` (Nouveau) : Compteur `mtime`, comparateur `mtimecmp`.
    *   `rtl/intc/plic_simple.vhd` (Nouveau) : Logique minimale pour gérer quelques interruptions externes depuis GPIO.
    *   `rtl/core/atomic_unit.vhd` (Nouveau ou intégré à MEM/ALU) : Implémentation `LR.T`/`SC.T` et AMOs optionnels.
    *   Mise à jour `rtl/pkg/` : Nouveaux opcodes (compact, atomiques), causes d'interruption, adresses CSR.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** Support pour l'encodage des instructions atomiques et (si implémenté) des instructions compactes 8 trits.
*   **Fichier de Contraintes :** Mappage des pins GPIO pour les interruptions externes.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_interrupts.vhd` : Testbench CPU complet simulant :
        *   Déclenchement d'une interruption Timer, sauvegarde état, saut handler M/S, retour `MRET`/`SRET`.
        *   Déclenchement d'une interruption Externe, idem.
        *   Test de la priorité et du masquage (`mie`/`sie`).
        *   (Optionnel) Test de délégation d'interruption.
    *   `sim/testbenches/tb_atomics.vhd` : Testbench (potentiellement multi-cœur simulé si S14b a été fait) validant `LR.T`/`SC.T` et AMOs dans des scénarios de concurrence simples.
    *   (Si Format C impl.) `sim/testbenches/tb_compact_instr.vhd` : Testbench exécutant un mix d'instructions 12t et 8t, vérifiant le décodage et l'exécution corrects.
*   **Simulation & Synthèse :**
    *   Résultats de simulation validant les interruptions, atomiques, et format compact (si fait).
    *   Rapport de Synthèse/Timing : Évaluer l'impact des nouvelles fonctionnalités sur les ressources et la FMax.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent. Les testbenches passent sans erreur d'assertion.
*   **Interruptions :**
    *   Le CPU peut être interrompu par le timer (`MTIP`/`STIP`) et par un signal externe (`MEIP`/`SEIP`).
    *   Le mécanisme de trap gère correctement les interruptions asynchrones (sauvegarde PC *suivant*, cause correcte, saut handler).
    *   Les CSRs `m/sie`, `m/sip` contrôlent l'activation/pendance des interruptions. `MRET`/`SRET` restaurent l'état d'activation. La délégation (si impl.) fonctionne.
*   **Atomiques :**
    *   `LR.T`/`SC.T` fonctionnent correctement pour implémenter une section critique simple (ex: accès à un compteur partagé par plusieurs process simulés ou via interruptions). La réservation est correctement invalidée.
    *   (Optionnel) Les AMOs ternaires implémentés produisent le résultat attendu atomiquement.
*   **(Si Format C impl.) Format Compact :**
    *   Le CPU décode et exécute correctement un mélange d'instructions 8t et 12t.
    *   Le PC est correctement incrémenté en fonction de la taille de l'instruction.
*   Le design complet est synthétisé et implémenté avec une FMax acceptable (ou les limitations sont comprises).
*   `prismchrono_asm` supporte les nouvelles instructions.

**Tasks:**

*   **[13.1] Conception Interruptions:** Finaliser le schéma ternaire pour `mie/mip/sie/sip`, les codes de cause d'interruption, la logique de priorité/délégation.
*   **[13.2] Implémentation Timer & PLIC:** Écrire `timer_unit.vhd` et `plic_simple.vhd`. Mettre à jour les CSRs.
*   **[13.3] Modification Control Unit (Interruptions):** Intégrer la logique de détection d'interruption asynchrone dans la FSM. Gérer l'interruption du pipeline et le déclenchement du trap (différent d'un trap synchrone). Adapter `MRET`/`SRET` pour la restauration de l'état d'interruption.
*   **[13.4] Finalisation Atomics:** Implémenter/Tester `LR.T`/`SC.T` avec le cache/mémoire. Implémenter les AMOs ternaires optionnels (nécessite modification ALU/Interface Mémoire). Implémenter `FENCE.T` (sémantique à définir précisément).
*   **[13.5] (Optionnel) Conception Format Compact:** Définir quelles instructions ont un format 8t et leur encodage précis. Comment IF/ID gèrent la longueur variable ?
*   **[13.6] (Optionnel) Modification IF/ID pour Format C:** Implémenter la logique de fetch/decode pour les instructions 8t/12t.
*   **[13.7] Mise à Jour Assembleur:** Ajouter support pour atomiques et (si fait) instructions compactes.
*   **[13.8] Testbenches:** Écrire/Exécuter `tb_interrupts.vhd`, `tb_atomics.vhd`, `tb_compact_instr.vhd` (si applicable).
*   **[13.9] Simulation & Débogage:** Valider toutes les nouvelles fonctionnalités via simulation et VCD.
*   **[13.10] Synthèse & Analyse Timing:** Vérifier l'impact sur les ressources et la FMax.
*   **[13.11] Documentation:** Mettre à jour tous les documents pertinents (ISA, Privilèges, Mémoire, Pipeline, Interruptions...).

**Risks & Mitigation:**
*   **Risque :** Gestion des interruptions asynchrones dans un pipeline complexe est très difficile (quand interrompre exactement ? restauration état précise ?). -> **Mitigation :** Commencer par interrompre à un point simple (ex: après WB). Étudier les implémentations RISC-V pour l'inspiration. Tests très rigoureux.
*   **Risque :** Implémentation correcte et performante des atomiques (surtout avec cache/mémoire externe). -> **Mitigation :** Bien définir la sémantique. Tester les scénarios de concurrence (même simulés séquentiellement).
*   **Risque :** L'ajout du format compact déstabilise le pipeline ou consomme trop de ressources. -> **Mitigation :** Envisager de le reporter. Commencer par une modification minimale du fetch/decode.
*   **Risque :** Dépassement des ressources FPGA ou chute drastique de FMax. -> **Mitigation :** Surveiller l'utilisation après chaque ajout majeur. Être prêt à désactiver/simplifier des fonctionnalités (ex: AMOs complexes, format compact) si nécessaire pour tenir sur la cible.

**Notes:**
*   Ce sprint ajoute des fonctionnalités *système* essentielles (interruptions) et *avancées* (atomiques, potentiellement compactes).
*   La complexité de la Control Unit et des interactions pipeline atteint un pic ici.
*   Prioriser la fonctionnalité correcte des interruptions et des atomiques de base (LR/SC) est clé.

**AIDEX Integration Potential:**
*   Aide à la conception de la logique de gestion des interruptions asynchrones et de la délégation ternaire.
*   Génération de code VHDL pour le timer, le PLIC simple, l'unité atomique.
*   Assistance pour la modification complexe du pipeline (IF/ID) pour le format compact.
*   Aide à l'écriture des testbenches complexes pour interruptions et atomiques.
*   Analyse des traces VCD pour déboguer les problèmes d'interruptions ou de concurrence atomique.
*   Suggestions d'optimisation VHDL pour améliorer la FMax malgré la complexité ajoutée.
