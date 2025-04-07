# Sprint 3 VHDL (PrismChrono): Datapath Initial, Unité de Contrôle & Premières Instructions

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Intégrer les blocs fondamentaux (ALU, Banc de Registres) dans un **datapath minimal** et développer une **unité de contrôle (Control Unit)** sous forme de machine à états finis (FSM). L'objectif est de pouvoir **simuler l'exécution complète** du cycle Fetch-Decode-Execute pour un **sous-ensemble très limité d'instructions** : `NOP`, `HALT`, et une instruction de base comme `ADDI`. Ce sprint valide l'interaction entre les composants principaux du CPU.

**State:** Not Started

**Priority:** Critique (Assemble les pièces pour former un CPU minimal fonctionnel)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - Conception de la FSM, interconnexions datapath, débogage cycle complet)

**Dependencies:**
*   **Sprint 2 VHDL Terminé :** Modules `alu_24t` et `register_file` fonctionnels et validés. Package `prismchrono_types_pkg` complet pour les types de base.
*   **ISA PrismChrono / Sprint 5 Simu :** Définition de l'encodage 12 trits pour `NOP`, `HALT`, `ADDI`, et des champs (OpCode, Rd, Rs1, Imm).

**Core Concepts:**
1.  **Datapath VHDL :** Interconnecter les modules (PC Register, Instruction Memory Interface, Register File, ALU, Control Unit) via des `signal`s VHDL représentant les bus (adresse, données, instruction) et les signaux de contrôle. Utilisation de multiplexeurs (MUX) pour sélectionner les sources de données (ex: pour l'entrée ALU, pour l'écriture dans RegFile).
2.  **Unité de Contrôle (FSM) :** Une machine à états (décrite dans un `process` VHDL) qui séquence le cycle d'instruction (Fetch, Decode, Execute). En fonction de l'OpCode décodé, elle génère les signaux de contrôle appropriés pour le datapath à chaque cycle d'horloge.
3.  **Cycle d'Instruction Simplifié :** Implémenter un cycle multi-cycles simple (ex: Fetch 1 cycle, Decode 1 cycle, Execute (ALU/Mem) 1+ cycles, Writeback 1 cycle).
4.  **Simulation Intégrée :** Créer un testbench pour le CPU complet (`prismchrono_core` ou `prismchrono_top`) qui simule la mémoire d'instruction (pré-chargée avec `NOP`/`HALT`/`ADDI`) et vérifie l'exécution correcte (évolution du PC, état des registres).

**Visualisation Simplifiée du Datapath & Contrôle :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [rtl/core/prismchrono_core.vhd]
        PC_Reg[PC Register (Sync)] -- Addr Out --> IMEM_IF(Instruction Mem I/F);
        IMEM_IF -- Instruction (EncodedWord 24t->48b?) --> IR[Instruction Register (Sync)];

        IR -- OpCode Field --> CU(Control Unit - FSM);
        IR -- Reg Addr Fields (Rs1, Rs2, Rd) --> REG_FILE(Register File);
        IR -- Imm Field --> IMM_EXT(Immediate Extender);

        REG_FILE -- Read Data 1 --> MUX_ALU_A;
        REG_FILE -- Read Data 2 --> MUX_ALU_B;
        IMM_EXT -- Sign-Extended Imm --> MUX_ALU_B;

        CU -- ALU Op Sel --> MUX_ALU_A;
        CU -- ALU Src B Sel --> MUX_ALU_B;

        MUX_ALU_A -- Operand A --> ALU(ALU 24t);
        MUX_ALU_B -- Operand B --> ALU;
        CU -- ALU Op Code --> ALU;
        ALU -- Result --> MUX_WR_DATA;
        ALU -- Flags --> CU;

        DMEM_IF(Data Mem I/F); %% Pour Load/Store plus tard
        DMEM_IF -- Read Data --> MUX_WR_DATA;

        PC_Reg -- PC Value --> MUX_ALU_A; %% Pour AUIPC plus tard

        CU -- Writeback Sel --> MUX_WR_DATA;
        MUX_WR_DATA -- Write Data --> REG_FILE;
        CU -- Reg Write Enable --> REG_FILE;

        CU -- PC Control Signals --> PC_Reg; %% (Hold, Inc, Load)

        %% Connections au monde extérieur (simplifié)
        IMEM_IF --> MEM_BUS(Memory Bus Interface);
        DMEM_IF --> MEM_BUS;
        CU --> Halt_Signal;
    end

    style CU fill:#f9f,stroke:#333,stroke-width:2px
    style PC_Reg fill:#ccf,stroke:#333,stroke-width:1px
    style IR fill:#ccf,stroke:#333,stroke-width:1px
    style REG_FILE fill:#cfc,stroke:#333,stroke-width:1px
    style ALU fill:#cfc,stroke:#333,stroke-width:1px
    style MUX_ALU_A fill:#eef,stroke:#333,stroke-width:1px
    style MUX_ALU_B fill:#eef,stroke:#333,stroke-width:1px
    style MUX_WR_DATA fill:#eef,stroke:#333,stroke-width:1px
    style IMM_EXT fill:#ffe,stroke:#333,stroke-width:1px
```
*(Note: Ce schéma est une simplification conceptuelle. Le VHDL décrira les interconnexions via des signaux et l'instanciation des composants.)*

**Deliverables:**
*   **Code VHDL :**
    *   `rtl/core/control_unit.vhd` : Entité et architecture FSM pour Fetch/Decode/Execute (NOP, HALT, ADDI).
    *   `rtl/core/datapath.vhd` : Entité et architecture assemblant PC, IR, RegFile, ALU, Mux, etc.
    *   `rtl/core/prismchrono_core.vhd` : Entité Top-Level du CPU, instanciant Datapath et Control Unit.
    *   (Optionnel) `rtl/core/mux*.vhd` : Modules génériques pour les multiplexeurs si non décrits directement.
    *   (Optionnel) `rtl/core/pc_register.vhd`, `rtl/core/instruction_register.vhd`.
    *   Mise à jour de `rtl/pkg/prismchrono_types_pkg.vhd` si besoin (ex: type pour états FSM, type pour signaux de contrôle).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_prismchrono_core.vhd` : Testbench pour le CPU complet.
        *   Simule la mémoire BRAM pré-chargée avec une séquence d'instructions `NOP`, `ADDI`, `HALT`.
        *   Génère l'horloge et le reset.
        *   Vérifie l'état final des registres (ex: le résultat de l'ADDI) et du PC après `HALT`.
        *   Utilise `assert` pour la validation.
*   **Simulation :**
    *   Mise à jour des scripts pour compiler et simuler `tb_prismchrono_core`.
    *   Fichier VCD généré pour `tb_prismchrono_core`.
*   **Documentation :**
    *   `doc/control_unit_fsm.md` : Diagramme d'états et description de la FSM.
    *   `doc/datapath_design.md` : Description de l'organisation du datapath et des signaux de contrôle.
    *   Mise à jour du `README.md` VHDL.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les nouveaux modules VHDL (`control_unit`, `datapath`, `prismchrono_core`, etc.) compilent sans erreur.
*   Le testbench `tb_prismchrono_core` compile, s'élabore et s'exécute sans erreur d'assertion.
*   La simulation pour `tb_prismchrono_core` montre :
    *   Le PC s'incrémente correctement après chaque instruction (sauf HALT).
    *   L'instruction `ADDI` est correctement décodée et exécutée :
        *   Les bons registres sources sont lus depuis `register_file`.
        *   L'immédiat est correctement extrait et étendu.
        *   L'ALU reçoit les bons opérandes et l'opcode `OP_ADD`.
        *   Le résultat de l'ALU est correctement écrit dans le registre destination (`Rd`) au cycle Writeback.
    *   L'instruction `NOP` ne modifie aucun état visible (sauf l'incrémentation du PC).
    *   L'instruction `HALT` arrête la progression du PC et met le CPU dans un état final (ex: assertion d'un signal `halted`).
*   Le fichier VCD de `tb_prismchrono_core` permet de tracer le flux d'une instruction à travers les étapes (Fetch, Decode, Execute, Writeback) et de vérifier les signaux de contrôle générés par la FSM.
*   La documentation de la FSM et du datapath est créée.

**Tasks:**

*   **[3.1] Mise à Jour Package Types:** Ajouter `type FsmStateType is (FETCH1, FETCH2, DECODE, EXEC_ADDI, WB_ADDI, HALTED, ...);`. Ajouter un type pour le bus de contrôle (ex: `record ControlSignals is ... end record;` ou `std_logic_vector`).
*   **[3.2] Conception Datapath (`datapath.vhd`):**
    *   Définir l'entité avec les ports d'interface vers la mémoire (Instruction & Données - simplifiés pour l'instant), les entrées de contrôle, et les sorties (ex: `halted`).
    *   Instancier `register_file`, `alu_24t`.
    *   Implémenter les registres PC et IR (process synchrones simples).
    *   Implémenter la logique d'extension de l'immédiat (pour ADDI).
    *   Implémenter les MUX nécessaires (sélection source ALU A/B, sélection donnée écriture RegFile) contrôlés par des signaux d'entrée.
    *   Implémenter la logique de calcul du prochain PC (Incrément +4 trytes, ou chargement si saut/branchement plus tard).
*   **[3.3] Conception Unité Contrôle FSM (`control_unit.vhd`):**
    *   Définir l'entité avec entrées (`clk`, `rst`, `opcode_from_ir`, `flags_from_alu`) et sorties (`ControlSignals`).
    *   Implémenter la FSM avec un `process(clk, rst)`:
        *   Signal pour l'état courant `current_state`, signal pour le prochain état `next_state`.
        *   Logique de transition d'état basée sur l'état courant et l'opcode (ex: si `DECODE` et `opcode=OPCODE_ADDI`, alors `next_state <= EXEC_ADDI;`).
        *   Logique combinatoire (ou process séparé) pour générer les `ControlSignals` de sortie en fonction de l'état courant (`current_state`). Ex: si `EXEC_ADDI`, alors `ctrl.alu_op <= OP_ADD; ctrl.reg_write_enable <= '0'; ...`. Si `WB_ADDI`, alors `ctrl.reg_write_enable <= '1'; ctrl.writeback_sel <= SEL_ALU_RESULT; ...`.
    *   Gérer les états `FETCH1`, `FETCH2`, `DECODE`, `EXEC_ADDI`, `WB_ADDI`, `HALTED`. L'état `EXEC_ADDI` active l'ALU. L'état `WB_ADDI` active l'écriture dans le RegFile. L'état `HALTED` bloque le PC.
*   **[3.4] Intégration CPU Core (`prismchrono_core.vhd`):**
    *   Instancier `datapath` et `control_unit`.
    *   Connecter les sorties de contrôle de `control_unit` aux entrées de contrôle de `datapath`.
    *   Connecter l'opcode de l'IR (depuis datapath) à l'entrée de `control_unit`.
    *   Connecter les flags de l'ALU (depuis datapath) à l'entrée de `control_unit`.
    *   Gérer l'interface mémoire externe simplifiée (pour l'instant, peut-être juste des ports directs vers le testbench).
*   **[3.5] Testbench CPU Core (`tb_prismchrono_core.vhd`):**
    *   Instancier `prismchrono_core`.
    *   **Simuler la Mémoire d'Instruction :** Utiliser un tableau VHDL constant (`signal instr_rom : ...`) pré-chargé avec l'encodage binaire des instructions `NOP`, `ADDI R1, R0, 5`, `ADDI R2, R1, N`, `HALT`.
    *   Connecter la sortie de cette ROM simulée à l'entrée instruction du `prismchrono_core` en fonction du PC.
    *   Générer `clk` et `rst`.
    *   **Vérifications :**
        *   Process qui surveille `clk`.
        *   Après un nombre suffisant de cycles pour atteindre `HALT`, vérifier la valeur des registres R1 et R2.
        *   Vérifier que le signal `halted` est actif.
        *   Utiliser `assert`.
    *   Générer VCD.
*   **[3.6] Simulation & Débogage:**
    *   Mettre à jour les scripts pour compiler tout le projet (`ghdl -a ...`).
    *   Exécuter `tb_prismchrono_core` (`ghdl -e ...`, `ghdl -r ... --vcd=core.vcd`).
    *   Si assertions échouent, ouvrir `core.vcd` avec GTKWave.
    *   Tracer le PC, l'état FSM (`current_state`), l'instruction dans l'IR, les signaux de contrôle, les opérandes ALU, le résultat ALU, les données écrites dans RegFile cycle par cycle pour comprendre où l'exécution dévie.
*   **[3.7] Documentation:** Rédiger `doc/control_unit_fsm.md` (avec diagramme d'états) et `doc/datapath_design.md`.

**Risks & Mitigation:**
*   **Risque :** Conception FSM complexe, erreurs de transition ou de génération des signaux de contrôle. -> **Mitigation :** Faire un diagramme d'états clair *avant* de coder. Tester la FSM de manière isolée si possible. Débogage VCD intensif.
*   **Risque :** Erreurs d'interconnexion dans le datapath. -> **Mitigation :** Nommer les signaux VHDL clairement. Vérifier les connexions dans le VCD.
*   **Risque :** Problèmes de timing / cycles dans la simulation (ex: résultat ALU disponible trop tôt/tard). -> **Mitigation :** Bien comprendre le modèle d'exécution VHDL (delta cycles). S'assurer que la FSM attend le bon nombre de cycles pour chaque étape.
*   **Risque :** Débogage VCD fastidieux. -> **Mitigation :** Ajouter des signaux internes clés (état FSM, données sur les bus) à la liste des signaux dumpés dans le VCD (`$dumpvars` / équivalent). Utiliser les fonctionnalités de GTKWave (groupes de signaux, curseurs, recherche).

**Notes:**
*   Ce sprint est crucial car il valide l'architecture de base du CPU en exécutant de vraies instructions (même simples) de bout en bout.
*   La FSM de l'unité de contrôle va devenir beaucoup plus complexe dans les sprints suivants pour gérer toutes les instructions. Il est important de la concevoir de manière modulaire et extensible.

**AIDEX Integration Potential:**
*   Aide à la conception du diagramme d'états FSM.
*   Génération du boilerplate VHDL pour la FSM (structure `case current_state is ...`) et le datapath (instanciations, connexions de ports).
*   Aide à l'écriture de la logique de génération des signaux de contrôle pour NOP/HALT/ADDI.
*   Suggestions pour la structure du testbench `tb_prismchrono_core`, y compris la simulation mémoire et les assertions.
*   Aide au débogage VHDL en interprétant les messages d'erreur GHDL ou en suggérant des signaux à observer dans GTKWave.
*   Explication des concepts de FSM, datapath, cycle d'instruction en VHDL.