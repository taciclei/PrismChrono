# Sprint 5 VHDL (PrismChrono): Contrôle de Flux - Sauts et Branchements

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Implémenter la logique de contrôle de flux dans le cœur `prismchrono_core`, permettant l'exécution correcte des **instructions de saut inconditionnel (JAL, JALR)** et des **instructions de branchement conditionnel (BRANCH)** basées sur les flags générés par l'ALU. Cela implique d'étendre l'unité de contrôle (FSM) et le datapath pour calculer les adresses cibles, évaluer les conditions de branchement, et mettre à jour le Program Counter (PC) de manière appropriée.

**State:** Not Started

**Priority:** Critique (Essentiel pour exécuter tout programme non trivial avec boucles/conditions)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - Logique de calcul d'adresse complexe, évaluation conditions, modification FSM et PC)

**Dependencies:**
*   **Sprint 4 VHDL Terminé :** Cœur CPU (`prismchrono_core`) exécutant les instructions ALU (qui mettent à jour les flags FR dans l'ALU) et CSR. FSM et datapath de base fonctionnels.
*   **Sprint 2 VHDL Terminé :** Module `alu_24t` générant correctement les flags (ZF, SF, OF, CF, XF - au moins ZF et SF sont critiques ici).
*   **ISA PrismChrono / Phase 3 Simu :** Encodage 12 trits précis pour `JAL` (Format J), `JALR` (Format I), `BRANCH` (Format B avec champ `cond`). Définition des codes ternaires pour chaque condition de branchement (`EQ`, `NE`, `LT`, `GE`, `XS`, `XN`, etc.) et leur mapping sur les flags (ZF, SF, XF).

**Core Concepts:**
1.  **Calcul d'Adresse Cible :**
    *   **JAL :** `PC_cible = PC_actuel + SignExtend(OffsetJ * 4)` (offset relatif au PC).
    *   **JALR :** `PC_cible = (Rs1 + SignExtend(ImmI)) & AlignMask(4)` (saut indirect via registre + offset, aligné).
    *   **BRANCH :** `PC_cible = PC_actuel + SignExtend(OffsetB * 4)` (offset relatif au PC).
2.  **Évaluation Condition Branchement :** Logique combinatoire dans l'unité de contrôle qui prend les `flags` de l'ALU (issus de l'instruction `CMP` précédente) et le champ `cond` de l'instruction `BRANCH` pour déterminer si le branchement doit être pris (`branch_taken = '1'`) ou non (`'0'`).
3.  **Mise à Jour du PC :** La logique de contrôle du PC doit être étendue pour pouvoir :
    *   S'incrémenter normalement (+4 trytes).
    *   Charger `PC_cible` calculé pour JAL/JALR.
    *   Charger `PC_cible` calculé pour BRANCH *seulement si* `branch_taken = '1'`.
4.  **Sauvegarde Adresse de Retour (Link) :** Pour `JAL` et `JALR`, l'adresse de l'instruction suivante (`PC_actuel + 4`) doit être acheminée vers le port d'écriture du banc de registres (`Rd`).
5.  **Extension FSM :** Ajouter des états pour les différentes phases de JAL, JALR, BRANCH (potentiellement : calcul d'adresse, évaluation condition, mise à jour PC).

**Visualisation des Changements Datapath/Contrôle :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Mise à Jour]
        IR -- OffsetJ, OffsetB, Cond Fields --> CU;
        IR -- ImmI Field --> IMM_EXT;
        IMM_EXT -- ImmI Ext --> AddrCalcLogic;

        REG_FILE -- Read Data 1 (Rs1 for JALR/BRANCH?) --> AddrCalcLogic;
        REG_FILE -- Read Data 1 (Rs1 for CMP) --> MUX_ALU_A;
        REG_FILE -- Read Data 2 (Rs2 for CMP) --> MUX_ALU_B;

        PC_Reg -- PC Value --> AddrCalcLogic;
        AddrCalcLogic[Addr Calc Logic<br/>(PC + Offset, Rs1 + Imm)] -- Target Addr --> MUX_PC_NEXT;

        PC_Plus_4[PC + 4 Logic] -- Incr PC --> MUX_PC_NEXT;
        PC_Plus_4 -- Link Addr --> MUX_WR_DATA; %% Pour JAL/JALR

        ALU -- Flags --> CU;
        CU -- Branch Cond Eval --> BranchTaken_Signal;
        BranchTaken_Signal --> MUX_PC_NEXT; %% Contrôle si branchement pris

        CU -- PC Next Sel --> MUX_PC_NEXT;
        MUX_PC_NEXT -- Next PC Value --> PC_Reg; %% Charge la prochaine valeur du PC

        CU -- Writeback Sel (ALU/Mem/CSR/LinkAddr) --> MUX_WR_DATA;
        MUX_WR_DATA --> REG_FILE; %% Écriture Rd pour JAL/JALR
    end

    style CU fill:#f9f,stroke:#333,stroke-width:2px
    style AddrCalcLogic fill:#ffe,stroke:#333,stroke-width:1px
    style PC_Reg fill:#ccf,stroke:#333,stroke-width:1px
    style MUX_PC_NEXT fill:#eef,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL Mis à Jour :**
    *   `rtl/core/control_unit.vhd` : FSM étendue pour gérer JAL, JALR, BRANCH (toutes conditions de base). Logique d'évaluation des conditions de branchement.
    *   `rtl/core/datapath.vhd` : Mise à jour avec la logique de calcul d'adresse cible, le MUX de sélection du prochain PC, et le chemin pour sauvegarder l'adresse de retour.
    *   `rtl/core/pc_register.vhd` (si séparé) : Mise à jour pour accepter le chargement d'une nouvelle valeur (pas juste l'incrément).
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Ajouter les opcodes et codes de condition manquants.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_prismchrono_core_ctrl_flow.vhd` (Nouveau ou extension) : Testbench simulant des séquences d'instructions incluant :
        *   `JAL` vers un label, puis `JALR` pour retourner (vérifier `Rd`).
        *   `CMP` suivi de `BRANCH` (tester au moins `BEQ`, `BNE`, `BLT`, `BGE`, `B` inconditionnel). Vérifier que le PC saute correctement si la condition est vraie/fausse.
        *   Une boucle simple utilisant `CMP` et `BNE`.
*   **Simulation :**
    *   Mise à jour des scripts de simulation.
    *   Fichier VCD généré pour `tb_prismchrono_core_ctrl_flow`.
*   **Documentation :**
    *   Mise à jour `doc/control_unit_fsm.md` (nouveaux états pour sauts/branches).
    *   Mise à jour `doc/datapath_design.md` (logique de calcul d'adresse, contrôle PC).
    *   `doc/branch_conditions.md` (Nouveau?) : Tableau mappant les codes `cond` ternaires aux flags et aux mnémoniques.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL mis à jour compilent sans erreur.
*   Le testbench `tb_prismchrono_core_ctrl_flow` s'exécute **sans erreur d'assertion**.
*   La simulation démontre l'exécution correcte de :
    *   `JAL Rd, label` : Le PC saute à l'adresse du `label`, et `PC+4` est écrit dans `Rd` (si `Rd != R0`).
    *   `JAL R0, label` (Jump) : Le PC saute à l'adresse du `label`, `R0` n'est pas modifié (ou l'écriture est ignorée).
    *   `JALR Rd, imm(Rs1)` : Le PC saute à l'adresse `(Rs1 + imm)` (correctement alignée), et `PC+4` est écrit dans `Rd` (si `Rd != R0`).
    *   `CMP Rs1, Rs2` : Les flags ZF, SF sont correctement mis à jour par l'ALU.
    *   `BRANCH cond, label` :
        *   Le PC saute à l'adresse du `label` **si et seulement si** la condition (`cond`) est vraie selon les flags générés par le `CMP` précédent.
        *   Le PC s'incrémente normalement si la condition est fausse.
        *   Testé pour `EQ`, `NE`, `LT`, `GE`, `B` (toujours pris).
*   Le calcul des adresses cibles (PC relatif pour JAL/BRANCH, Registre+Offset pour JALR) est correct.
*   L'alignement pour JALR est correctement appliqué.
*   La FSM de l'unité de contrôle passe par les bons états pour gérer ces instructions et génère les signaux corrects pour le contrôle du PC et l'écriture de `Rd` (pour JAL/JALR).
*   Le fichier VCD permet de suivre le calcul d'adresse, l'évaluation de condition, et la mise à jour du PC.
*   La documentation est mise à jour.

**Tasks:**

*   **[5.1] Conception Calcul Adresse & Contrôle PC:**
    *   Définir précisément la logique VHDL pour calculer `PC + Offset*4` et `(Rs1 + Imm) & AlignMask`.
    *   Concevoir le MUX qui sélectionne la source du prochain PC (PC+4, Target JAL/JALR, Target BRANCH).
    *   Concevoir les signaux de contrôle pour ce MUX et pour l'enable/load du registre PC.
*   **[5.2] Conception Évaluation Condition Branchement:**
    *   Implémenter la logique combinatoire dans `control_unit.vhd` qui prend `flags_from_alu` et `cond_from_ir` et produit `branch_taken : out std_logic`. Couvrir `EQ`(ZF), `NE`(!ZF), `LT`(SF & !ZF ? - *Vérifier la définition exacte de SF*), `GE`(!SF | ZF ?), `B`('1'). *Reporter les conditions U/XF si non prêtes.*
*   **[5.3] Mise à Jour Datapath (`datapath.vhd`):**
    *   Instancier/implémenter la logique de calcul d'adresse.
    *   Ajouter le MUX de sélection du prochain PC.
    *   Ajouter le chemin `PC+4 -> MUX_WR_DATA`.
    *   Connecter les flags de l'ALU à la Control Unit.
    *   Connecter le signal `branch_taken` (venant de CU) au contrôle du MUX PC.
*   **[5.4] Mise à Jour Unité Contrôle (`control_unit.vhd`):**
    *   **Décodage :** Reconnaître OpCodes JAL, JALR, BRANCH. Extraire `cond`.
    *   **Nouveaux États FSM :** Ajouter des états pour :
        *   `EXEC_JAL`: Calculer cible, préparer écriture Rd, préparer chargement PC.
        *   `EXEC_JALR`: Lire Rs1, calculer cible, préparer écriture Rd, préparer chargement PC.
        *   `EXEC_BRANCH`: Évaluer condition. Préparer chargement PC (cible ou PC+4). (Note: CMP se fait via l'état EXEC_ALU_R).
    *   **Logique Contrôle :** Générer les signaux pour :
        *   Activer le calcul d'adresse approprié.
        *   Sélectionner la source du prochain PC via `MUX_PC_NEXT`.
        *   Activer le chargement du PC si saut ou branchement pris.
        *   Sélectionner `PC+4` comme donnée à écrire pour JAL/JALR et activer `reg_write_enable`.
        *   Passer le `cond` et les `flags` à la logique d'évaluation.
*   **[5.5] Mise à Jour `prismchrono_core.vhd`:** Connecter les nouveaux signaux si nécessaire.
*   **[5.6] Testbench CPU Core Étendu (`tb_prismchrono_core_ctrl_flow.vhd`):**
    *   Créer ROM simulée avec des séquences testant JAL, JALR (retour simple), CMP+BEQ (cas pris/non pris), CMP+BNE (cas pris/non pris), CMP+BLT, CMP+BGE, boucle simple (`ADDI R1, R1, -1; CMP R1, R0; BNE loop_label`).
    *   Ajouter des assertions pour vérifier :
        *   La valeur finale de R1 après la boucle.
        *   La valeur de `Rd` après JAL/JALR.
        *   Le PC final après chaque séquence de branchement (a-t-il sauté ou non comme prévu?).
*   **[5.7] Simulation & Débogage:** Exécuter, vérifier assertions. Utiliser GTKWave pour tracer le PC, l'état FSM, les flags ALU, le signal `branch_taken`, la sortie du MUX PC, les écritures RegFile. Déboguer la FSM et le calcul d'adresse.
*   **[5.8] Documentation:** Mettre à jour FSM, Datapath. Créer `branch_conditions.md`.

**Risks & Mitigation:**
*   **Risque :** Erreurs dans le calcul complexe des adresses cibles (relatif vs registre, alignement JALR). -> **Mitigation :** Tests unitaires pour la logique de calcul si possible. Vérification minutieuse dans GTKWave.
*   **Risque :** Erreurs dans la logique d'évaluation des conditions de branchement (mapping flags <-> condition). -> **Mitigation :** Tableau de vérité clair. Tester chaque condition explicitement dans le testbench. Attention à la définition de SF (négatif ou < 0?).
*   **Risque :** Timing incorrect de la mise à jour du PC ou de l'écriture de Rd dans la FSM. -> **Mitigation :** Bien définir dans quels états FSM ces actions doivent se produire. Vérifier dans VCD.
*   **Risque :** Interaction avec le pipeline (si déjà partiellement implémenté) - ex: annulation d'instruction après branchement. -> **Mitigation :** Pour ce sprint, supposer un pipeline simple ou mono-cycle. La gestion complète des aléas de contrôle est un sujet avancé (Sprint suivant). Si un pipeline existe, il faudra implémenter le flush lors des sauts/branches pris.

**Notes:**
*   Ce sprint rend le CPU "Turing-complet" (en théorie, avec mémoire infinie). Il peut maintenant exécuter des algorithmes arbitraires.
*   La performance (fréquence d'horloge) dépendra fortement de la complexité du chemin critique (probablement calcul d'adresse ou ALU).
*   La gestion des aléas de contrôle (si le pipeline est plus avancé) n'est pas l'objectif principal ici mais devra être considérée bientôt.

**AIDEX Integration Potential:**
*   Aide à la conception VHDL de la logique de calcul d'adresse et d'évaluation des conditions.
*   Génération du code VHDL pour les nouveaux états et transitions de la FSM.
*   Aide à la création des séquences de test assembleur (manuelles pour l'instant) pour le testbench VHDL.
*   Génération des assertions VHDL pour le testbench.
*   Débogage assisté des simulations, interprétation des formes d'onde VCD pour les problèmes de contrôle de flux.
