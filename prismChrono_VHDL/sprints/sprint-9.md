# Sprint 9 VHDL (PrismChrono): Finalisation ISA Base, Système Privilèges Complet & Tests Intégrés

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Amener le cœur CPU VHDL `prismchrono_core` à un niveau de **complétude fonctionnelle pour l'ISA de base (≈RV32IM + spécifiques PrismChrono)** et le **système de privilèges M/S/U**. Ce sprint se concentre sur l'implémentation des instructions restantes critiques comme la **multiplication et la division** (potentiellement multi-cycles), la finalisation de **toutes les conditions de branchement**, l'intégration complète de la **logique de trap et des CSRs M/S/U**, et la création d'un **testbench système robuste** capable d'exécuter des séquences de code validant ces nouvelles fonctionnalités et les interactions (ex: faute de page gérée par un handler S-mode).

**State:** Not Started

**Priority:** Très Élevée (Complète l'essentiel de l'ISA et des mécanismes système pour exécuter un noyau simple)

**Estimated Effort:** Très Large (ex: 20-30 points, T-shirt XL - MUL/DIV matériels sont complexes, finalisation traps/privilèges/CSRs, testbench système élaboré)

**Dependencies:**
*   **Sprint 8 VHDL Terminé (ou fonctionnel en simulation) :** Cœur CPU avec Cache L1 et accès à la mémoire externe DDR/SDRAM (via contrôleur).
*   **Sprint Ω / 14 Conceptuel (Simu) / Sprint 7 VHDL :** Mécanisme de trap, CSRs de base, privilèges M/U (et S si défini) conceptuellement prêts ou partiellement implémentés.
*   **ISA PrismChrono Complète (README Simu / Phase 3) :** Encodage et sémantique précis pour `MUL`, `DIV`, `MOD`, toutes les conditions `BRANCH`, et *tous* les CSRs M/S/U prévus (y compris `satp_t`, `sstatus_t`, `stvec_t`, `sepc_t`, `scause_t`, délégations `medeleg`/`mideleg`).

**Core Concepts:**
1.  **Implémentation MUL/DIV/MOD :**
    *   Décider de l'approche :
        *   **Option A (Multi-Cycles Simple - Recommandé) :** Implémenter des algorithmes itératifs (décalages et additions/soustractions ternaires) dans une unité dédiée ou au sein de l'ALU. L'instruction prendra plusieurs cycles. Nécessite une modification de la FSM pour gérer les états d'attente.
        *   **Option B (Matériel Combinatoire/Pipeliné Rapide) :** Concevoir un multiplieur/diviseur ternaire rapide. **Très complexe** et gourmand en ressources (surtout le diviseur). Probablement hors scope initial.
        *   **Option C (Trap Logiciel) :** Déclencher un trap "Instruction Réservée" et laisser un handler logiciel (en M-mode) émuler l'opération. Simple en VHDL mais lent à l'exécution.
    *   *Recommandation :* Commencer par l'Option A (Multi-Cycles) pour MUL. Reporter DIV/MOD ou utiliser l'Option C initialement.
2.  **Finalisation Branchements :** Implémenter la logique d'évaluation pour *toutes* les conditions (`EQ`, `NE`, `LT`, `GE`, `LTU`, `GEU`, `BOF`, `BCF`, `BSPEC`, `B`). Nécessite la définition de l'arithmétique non signée ternaire et la gestion des flags CF/OF par l'ALU.
3.  **Système Privilèges & CSRs Complet :**
    *   Implémenter tous les CSRs M/S/U définis (`mstatus_t`, `sstatus_t`, `satp_t`, etc.) dans `csr_registers.vhd` (ou équivalent).
    *   Implémenter la logique de contrôle d'accès complète (lecture/écriture selon privilège actuel et CSR cible).
    *   Gérer les écritures qui ont des effets de bord (ex: écrire dans `satp_t` doit potentiellement vider le TLB simulé).
4.  **Gestion des Traps Complète :**
    *   La FSM doit gérer correctement *tous* les traps synchrones prévus (ECALL, EBREAK, IllegalInstr, AlignFault, PageFaults, accès CSR privilégié).
    *   Implémenter la logique de **délégation de trap** (si définie) : vérifier `medeleg`/`mideleg` pour décider si le trap va en S-mode (`stvec`) ou M-mode (`mtvec`).
    *   Assurer la sauvegarde/restauration correcte de *tous* les états pertinents lors des traps et des `MRET`/`SRET`.
5.  **Testbench Système Avancé :** Un testbench qui charge un "noyau" minimaliste (en M/S-mode) et une "application" (en U-mode) dans la mémoire DDR simulée. Le test doit valider les transitions de privilèges, la gestion des syscalls (ECALL U->S/M), la gestion des fautes (ex: faute de page U->S/M), et l'exécution des nouvelles instructions (MUL).

**Visualisation des Évolutions :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Mise à Jour Finale ISA Base]
        %% ALU Enhancements
        subgraph ALU_Unit [ALU 24t Étendue]
            ALU_Logic{ALU Logic} -- Now includes --> MUL_DIV_Unit(MUL/DIV/MOD Logic<br/>(Multi-Cycle?));
            ALU_Logic -- Generates --> Full_Flags(Flags Bus Complet<br/>ZF, SF, OF, CF, XF);
        end

        %% Control Unit Enhancements
        subgraph CU [Control Unit - Gestion Complète]
             FSM_States((FSM States)) -- Handles --> All_Instructions(Toutes Instr. Base);
             FSM_States -- Handles --> All_Traps(Tous Traps Sync.);
             FSM_States -- Handles --> Privilege_Transitions(M/S/U Transitions);
             FSM_States -- Handles --> Stall_Logic(Stall pour Multi-Cycle<br/>MUL/DIV/Cache/Mem);
             CU -- Reads --> Delegation_CSRs(medeleg, mideleg);
             CU -- Controls --> CSR_Access(Accès CSRs M/S/U);
             CU -- Evaluates --> All_Branch_Conds(Toutes Conditions Branchement);
        end

        %% CSR Module Enhancements
        subgraph CSR_Module [CSR Registers - Complet]
            CSR_Regs[(mstatus_t, sstatus_t, satp_t, mtvec, stvec, mepc, sepc, mcause, scause, mideleg, medeleg, ...)];
            CSR_AccessLogic{Logique Accès<br/>(Privilège, Effets Bord)};
            CSR_Regs <--> CSR_AccessLogic;
        end

        %% Connections
        ALU_Unit -- Full_Flags --> CU;
        IR --> CU;
        Datapath <--> CU;
        Datapath <--> CSR_Module;
        Datapath --> ALU_Unit;
        CPU_Core -- Access --> L1_CACHE; %% From Sprint 8
    end
```

**Deliverables:**
*   **Code VHDL Mis à Jour :**
    *   `rtl/core/alu_24t.vhd` : Ajout de la logique MUL (multi-cycles) et potentiellement DIV/MOD (multi-cycles ou trap). Génération complète et correcte des flags OF/CF.
    *   `rtl/core/control_unit.vhd` : FSM finale pour l'ISA de base, gérant les stalls multi-cycles, tous les traps synchrones, la délégation, et toutes les conditions de branchement.
    *   `rtl/core/csr_registers.vhd` : Implémentation de *tous* les CSRs M/S/U définis, avec logique d'accès et effets de bord (ex: écriture `satp_t`).
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Opcodes/funct pour MUL/DIV/MOD, toutes les conditions de branchement, tous les index/adresses CSR.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_mul_div_unit.vhd` (Si unité séparée) : Testbench pour l'unité MUL/DIV multi-cycles.
    *   `sim/testbenches/tb_prismchrono_core_full_system.vhd` (Nouveau/Final) : Testbench système complet chargeant un noyau minimaliste M/S et une application U en mémoire DDR simulée. Le test doit couvrir :
        *   Exécution `MUL` (et DIV/MOD si impl.).
        *   Toutes les conditions de branchement (incluant U, OF, CF, BSPEC).
        *   Transition M -> S -> U (`MRET`/`SRET`).
        *   `ECALL` U -> S/M (selon délégation).
        *   Faute de Page U -> S/M (selon délégation).
        *   Accès CSR privilégié depuis U -> Trap Illegal Instruction.
        *   Lecture/Écriture de `satp_t` depuis S/M.
*   **Simulation :** Scripts mis à jour. VCD pour le testbench système.
*   **Documentation :** Mise à jour de tous les documents de conception (ISA, Privilèges, MMU, CSRs, FSM, Datapath) pour refléter l'état final de l'implémentation de base.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent.
*   Le testbench `tb_prismchrono_core_full_system` s'exécute **sans erreur d'assertion**.
*   La simulation démontre l'exécution correcte de :
    *   `MUL` (résultat correct, FSM gère les cycles multiples). DIV/MOD si implémentés.
    *   **Toutes** les conditions de `BRANCH` fonctionnent comme spécifié (y compris U, OF, CF, BSPEC).
    *   Le système de privilèges M/S/U est respecté pour l'accès aux CSRs et l'exécution des instructions (`MRET`/`SRET`).
    *   Les traps (ECALL, IllegalInstr, Faults) sont correctement détectés, la délégation (si impl.) est appliquée, le bon handler est appelé, et le retour via `MRET`/`SRET` fonctionne.
    *   L'écriture dans `satp_t` est possible depuis S/M mode.
*   Le fichier VCD permet de tracer des scénarios complexes impliquant des changements de privilège, des traps, et des instructions multi-cycles.
*   La documentation reflète l'état final de l'ISA de base et des mécanismes système implémentés.

**Tasks:**

*   **[9.1] Implémentation MUL/DIV/MOD:**
    *   Choisir l'approche (Multi-cycles recommandé).
    *   Implémenter l'unité/logique VHDL (peut nécessiter une sous-FSM).
    *   Adapter l'ALU et la Control Unit (états de stall).
    *   Tester isolément si possible.
*   **[9.2] Finalisation Branchements:**
    *   Définir la logique ternaire pour l'arithmétique/comparaison non signée (`LTU`/`GEU`).
    *   Assurer que l'ALU génère correctement OF/CF.
    *   Implémenter la logique d'évaluation de *toutes* les conditions dans `control_unit.vhd`.
    *   Tester toutes les conditions dans `tb_prismchrono_core_full_system`.
*   **[9.3] Implémentation CSRs Complets:**
    *   Implémenter tous les registres CSRs M/S/U définis (dans `csr_registers.vhd`).
    *   Implémenter la logique de contrôle d'accès fine basée sur le mode et le CSR.
    *   Gérer les effets de bord (écriture `satp_t` -> flush TLB simulé?).
*   **[9.4] Finalisation Gestion Traps:**
    *   Implémenter la logique de délégation de trap (lecture `medeleg`/`mideleg`).
    *   Assurer la sauvegarde/restauration complète et correcte de l'état (`mepc`/`sepc`, `mcause`/`scause`, `mstatus`/`sstatus` bits `MPP`/`SPP`/`MPIE`/`SPIE`/`MIE`/`SIE`).
    *   Modifier `MRET`/`SRET` pour gérer cette restauration complète.
*   **[9.5] Testbench Système Avancé (`tb_prismchrono_core_full_system.vhd`):**
    *   Concevoir la structure du "noyau" M/S minimal et de l'"app" U.
    *   Écrire le code ternaire (manuel/binaire) pour ces composants, incluant la configuration initiale (`mtvec`, `stvec`, délégations), le passage M->S->U, un handler de trap simple en S/M (qui lit `mcause` et retourne), un ECALL depuis U, une faute de page depuis U.
    *   Pré-charger ce code dans le modèle de mémoire DDR simulée.
    *   Ajouter des assertions pour vérifier l'état final après des scénarios spécifiques.
*   **[9.6] Simulation & Débogage Final:** Exécuter le testbench système. Déboguer intensivement les interactions complexes entre privilèges, traps, MMU (fautes), et instructions multi-cycles. Utiliser GTKWave massivement.
*   **[9.7] Documentation Finale:** Mettre à jour tous les documents pour refléter l'état complet de l'implémentation VHDL de base.

**Risks & Mitigation:**
*   **Risque :** Complexité MUL/DIV ternaire multi-cycles. -> **Mitigation :** Commencer par MUL seul. Utiliser des algorithmes connus (adaptés). Tester isolément. Envisager de trapper pour DIV/MOD au début.
*   **Risque :** Interaction subtile entre traps, délégation, privilèges, et restauration d'état. -> **Mitigation :** Suivre la spécification RISC-V pour l'inspiration *structurelle*. Tests très ciblés pour chaque type de trap et de transition dans le testbench système. Débogage VCD très attentif.
*   **Risque :** Effort de débogage du testbench système très important. -> **Mitigation :** Ajouter beaucoup de points de vérification (`assert`) et de messages (`report`) dans le testbench. Procéder par étapes dans le scénario de test.
*   **Risque :** Le design complet devient trop gros ou trop lent pour le FPGA cible une fois synthétisé. -> **Mitigation :** Surveiller les estimations de ressources fournies par Yosys/Vivado. Reporter les optimisations de performance ou de surface à des sprints ultérieurs. Accepter une fréquence d'horloge plus basse initialement.

**Notes:**
*   Ce sprint vise à avoir un cœur CPU **fonctionnellement complet** pour l'ISA de base et les mécanismes système essentiels.
*   C'est la fondation sur laquelle un véritable micro-noyau ternaire pourrait être démarré.
*   Les optimisations de performance (pipeline avancé, caches complexes, prédicteurs de branchement) et les instructions spécialisées (neuronales, compactes) sont laissées pour les sprints futurs (10+ VHDL).

**AIDEX Integration Potential:**
*   Aide à la conception/implémentation VHDL des unités MUL/DIV multi-cycles.
*   Assistance pour implémenter la logique de délégation de trap et la gestion complète des CSRs.
*   Aide à l'écriture du testbench système complexe et des séquences de code ternaire manuel pour le noyau/app de test.
*   Génération des assertions VHDL complexes.
*   Analyse assistée des traces VCD pour déboguer les interactions système (traps, privilèges).
*   Suggestions pour structurer la FSM afin de gérer les stalls multi-cycles et les états de trap/retour.