# Sprint 10 VHDL (PrismChrono): Pipeline Simple & Gestion des Aléas de Base

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Transformer le cœur CPU `prismchrono_core` (actuellement mono-cycle ou multi-cycles simple) en une architecture **pipelinée à 5 étages (IF, ID, EX, MEM, WB)**, similaire à celle décrite dans le README du simulateur. Ce sprint se concentre sur la mise en place de la **structure du pipeline**, l'ajout des **registres de pipeline** entre les étages, et l'implémentation de la **gestion des aléas de données les plus simples** via le **forwarding (bypass)** pour améliorer les performances en réduisant les stalls. La gestion des aléas de contrôle (branchements) sera simplifiée (ex: flush basique).

**State:** Not Started

**Priority:** Élevée (Amélioration majeure de la performance théorique et rapprochement de l'architecture cible décrite)

**Estimated Effort:** Très Large (ex: 20-30 points, T-shirt XL - Refonte majeure de la structure du CPU, logique de forwarding complexe, gestion des registres pipeline)

**Dependencies:**
*   **Sprint 9 VHDL Terminé :** Cœur CPU fonctionnel pour l'ISA de base, avec ALU, RegFile, accès mémoire (via cache/DDR si S8 fait), gestion des traps/privilèges de base. L'unité de contrôle existe mais sera refondue.
*   **Conception Pipeline (README Simu / à définir) :** Définition claire des 5 étages (IF, ID, EX, MEM, WB) et des informations qui doivent passer de l'un à l'autre via les registres de pipeline.

**Core Concepts:**
1.  **Structure Pipelinée 5 Étages :**
    *   **IF (Instruction Fetch) :** Récupère l'instruction à `PC` depuis le cache I (ou mémoire). Calcule `PC+4` (ou `PC+2` pour compact?).
    *   **ID (Instruction Decode) :** Décode l'instruction, lit les opérandes depuis le `Register File`, étend l'immédiat.
    *   **EX (Execute) :** Effectue l'opération ALU, calcule l'adresse pour Load/Store/Branches.
    *   **MEM (Memory Access) :** Accède au cache D (ou mémoire) pour Load/Store.
    *   **WB (Write Back) :** Écrit le résultat (ALU, Load) dans le `Register File`.
2.  **Registres de Pipeline :** Des registres (implémentés avec des FFs en VHDL) insérés *entre* chaque étage pour stocker les informations nécessaires à l'étage suivant (ex: `IF/ID_register` stocke l'instruction et PC+4 ; `ID/EX_register` stocke les opérandes lus, l'immédiat étendu, l'opcode, l'adresse Rd, etc.). Ils sont mis à jour à chaque front d'horloge.
3.  **Forwarding (Bypass) :** Logique combinatoire qui détecte les **aléas de données RAW (Read After Write)** (ex: une instruction dans ID/EX veut lire un registre qui est en train d'être écrit par une instruction précédente dans MEM ou WB). Si détecté, le résultat est directement "forwardé" depuis la sortie de l'étage MEM ou WB vers l'entrée de l'étage EX, en court-circuitant la lecture du Register File. Cela évite un stall.
4.  **Gestion des Aléas de Contrôle (Simple) :** Lorsqu'un branchement est résolu (typiquement à l'étage EX ou MEM), s'il est pris et que la prédiction était fausse (ou s'il n'y a pas de prédiction), les instructions déjà entrées dans les étages IF et ID (qui sont sur le mauvais chemin) doivent être annulées (**flush**). Pour ce sprint, on peut implémenter un flush simple : invalider les registres IF/ID et ID/EX si un branchement est pris. Pas de prédiction avancée.
5.  **Stalls (Détection d'Aléas Structurels / Load-Use) :**
    *   Si une instruction `LOAD` est suivie immédiatement par une instruction qui utilise le résultat (aléa Load-Use), et que le forwarding depuis MEM n'est pas suffisant (la donnée n'arrive qu'à WB), il faut "figer" les étages IF et ID pendant un cycle (`stall`).
    *   D'autres stalls peuvent être nécessaires si la mémoire ou l'ALU multi-cycle ne sont pas prêtes.

**Visualisation du Pipeline et Forwarding :**

```mermaid
graph LR
    Fetch[IF<br/>Fetch Instr<br/>PC -> PC+4] --> RegIFID(IF/ID<br/>Register);
    RegIFID --> Decode[ID<br/>Decode Instr<br/>Read Regs];
    Decode --> RegIDEX(ID/EX<br/>Register);
    RegIDEX --> Execute[EX<br/>ALU Op<br/>Addr Calc];
    Execute --> RegEXMEM(EX/MEM<br/>Register);
    RegEXMEM --> Memory[MEM<br/>Load/Store<br/>Branch Resolve?];
    Memory --> RegMEMWB(MEM/WB<br/>Register);
    RegMEMWB --> WriteBack[WB<br/>Write Reg];

    subgraph Forwarding Paths
        direction TB
        RegEXMEM -- Forward ALU Result? --> Execute;
        RegMEMWB -- Forward ALU/Load Result? --> Execute;
        RegMEMWB -- Forward Load Result? --> Memory; %% Pour Rs2 de Store
    end

    subgraph Hazard Control
        DetectHazard{Hazard Unit} -->|Stall| Fetch;
        DetectHazard -->|Stall| Decode;
        DetectHazard -->|Flush| RegIFID;
        DetectHazard -->|Flush| RegIDEX;
        Decode -- Reg Reads --> DetectHazard;
        RegIDEX -- Rd / Mem Access --> DetectHazard;
        RegEXMEM -- Rd / Branch Taken --> DetectHazard;
        RegMEMWB -- Rd --> DetectHazard;
    end

    WriteBack -- Write Data --> RegFile(Register File);
    Decode -- Read Addrs --> RegFile;
    RegFile -- Read Data --> Decode;

    style RegIFID fill:#eee, stroke:#333, stroke-dasharray: 5 5
    style RegIDEX fill:#eee, stroke:#333, stroke-dasharray: 5 5
    style RegEXMEM fill:#eee, stroke:#333, stroke-dasharray: 5 5
    style RegMEMWB fill:#eee, stroke:#333, stroke-dasharray: 5 5
    style Forwarding Paths fill:none, stroke:#00f, stroke-width:1px, color:#00f
    style Hazard Control fill:none, stroke:#f00, stroke-width:1px, color:#f00
```

**Deliverables:**
*   **Code VHDL Refactorisé :**
    *   Structure de `prismchrono_core.vhd` (ou nouveau `pipelined_core.vhd`) reflétant les 5 étages.
    *   Définition et implémentation des registres de pipeline (`if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`) stockant les données et les signaux de contrôle nécessaires.
    *   Logique de **forwarding** implémentée (MUX additionnels aux entrées de l'étage EX).
    *   Logique de **détection d'aléas** (RAW, Load-Use) et de **stall** (fige PC et IF/ID).
    *   Logique de **flush** simple pour les branchements pris.
    *   L'Unité de Contrôle est maintenant distribuée : chaque étage reçoit des signaux de contrôle du précédent et génère ceux pour le suivant (stockés dans les registres pipeline).
*   **Testbenches VHDL Mis à Jour/Nouveaux :**
    *   `sim/testbenches/tb_pipelined_core.vhd` : Testbench simulant des séquences d'instructions conçues **spécifiquement pour tester les aléas et le forwarding** :
        *   Séquence RAW simple (ex: `ADDI R1, R0, 5; ADD R2, R1, R1`). Vérifier que R2 reçoit 10 grâce au forwarding, sans stall.
        *   Séquence Load-Use (ex: `LOADW R1, addr; ADDI R2, R1, 1`). Vérifier qu'un stall d'un cycle est inséré avant l'ADDI.
        *   Séquence avec branchement pris. Vérifier que les instructions suivantes sont flushées.
*   **Simulation :** Scripts mis à jour. VCD montrant clairement le passage des instructions dans les étages, l'activation du forwarding et des stalls/flushs.
*   **Documentation :**
    *   `doc/pipeline_design.md` : Description détaillée des 5 étages, du contenu des registres pipeline, de la logique de forwarding et de gestion des aléas.

**Acceptance Criteria (DoD - Definition of Done):**
*   Le design pipeliné compile sans erreur.
*   Le testbench `tb_pipelined_core` s'exécute **sans erreur d'assertion**.
*   La simulation démontre :
    *   Les instructions progressent correctement à travers les 5 étages cycle après cycle.
    *   Le **forwarding** fonctionne pour les aléas RAW simples entre EX->EX, MEM->EX, WB->EX (évite les stalls).
    *   Un **stall** est correctement inséré pour l'aléa Load-Use (LOAD dans MEM, utilisation dans EX suivant).
    *   Un **flush** simple annule les instructions dans IF/ID lorsqu'un branchement est pris (résolu en EX ou MEM).
    *   Les résultats finaux des calculs et des accès mémoire sont corrects malgré le pipeline et les aléas.
*   Le fichier VCD permet de visualiser le contenu des registres pipeline, les signaux de forwarding actifs, les signaux de stall/flush, et de vérifier le timing des opérations.
*   La documentation du pipeline est créée/mise à jour.

**Tasks:**

*   **[10.1] Conception Détaillée Pipeline:**
    *   Définir précisément les signaux passant par chaque registre pipeline (PC, Instruction, Données Registres, Immédiat, Opcode, Signaux Contrôle MEM/WB, Adresse Rd, etc.).
    *   Concevoir la logique de forwarding : quelles sources (EX/MEM, MEM/WB) peuvent forwarder vers quelles destinations (Entrée A ALU, Entrée B ALU, Donnée pour Store en MEM). Conditions d'activation.
    *   Concevoir la logique de détection d'aléas : Comparer les `Rs1`/`Rs2` lus en ID avec les `Rd` écrits dans les étages EX, MEM, WB. Détecter spécifiquement l'aléa Load-Use.
    *   Concevoir la logique de stall (figer PC et IF/ID) et de flush (invalider IF/ID, ID/EX).
    *   Documenter dans `pipeline_design.md`.
*   **[10.2] Refactoring VHDL - Étages & Registres Pipeline:**
    *   Réorganiser le code de `prismchrono_core` (ou créer `pipelined_core`) en 5 sections/process correspondant aux étages.
    *   Implémenter les 4 registres de pipeline (`if_id_reg`, `id_ex_reg`, `ex_mem_reg`, `mem_wb_reg`) comme des signaux mis à jour par des `process(clk, rst)`. Gérer le `stall` et le `flush` sur ces registres.
*   **[10.3] Implémentation Logique de Forwarding:** Ajouter les MUX aux entrées de l'étage EX. Écrire la logique combinatoire qui compare les registres sources/destinations dans les différents étages et génère les signaux de sélection pour ces MUX.
*   **[10.4] Implémentation Détection Aléas & Contrôle Pipeline:** Implémenter l'unité de détection d'aléas (Hazard Unit). Générer les signaux `stall_ifid`, `stall_idex`, `flush_ifid`, `flush_idex` et les utiliser pour contrôler le PC et les registres pipeline.
*   **[10.5] Adaptation Unité de Contrôle:** La logique de contrôle est maintenant distribuée. Chaque étage propage les signaux de contrôle nécessaires à l'étage suivant via les registres pipeline (ex: `id_ex_reg.alu_op`, `ex_mem_reg.mem_write_enable`, `mem_wb_reg.reg_write_enable`).
*   **[10.6] Testbench Pipeline (`tb_pipelined_core.vhd`):**
    *   Créer une ROM simulée avec des séquences spécifiques pour tester :
        *   Instructions indépendantes.
        *   Aléa RAW avec forwarding (EX->EX, MEM->EX, WB->EX).
        *   Aléa Load-Use avec stall.
        *   Branchement pris avec flush.
        *   Branchement non pris.
    *   Utiliser des `assert` pour vérifier les valeurs finales des registres *et* potentiellement le nombre de cycles total (pour vérifier les stalls).
*   **[10.7] Simulation & Débogage Pipeline:** Exécuter, vérifier assertions. Utiliser GTKWave intensivement pour visualiser le flux dans le pipeline, les données dans les registres inter-étages, l'activation du forwarding, des stalls, des flushs. C'est l'étape la plus longue.
*   **[10.8] Documentation:** Finaliser `doc/pipeline_design.md`.

**Risks & Mitigation:**
*   **(Risque MAJEUR) Complexité Logique Pipeline:** La gestion des aléas (surtout forwarding et stalls combinés) est notoirement complexe et sujette aux erreurs subtiles. -> **Mitigation :** Conception très modulaire. Tests unitaires pour l'unité de forwarding/hazard si possible. Commencer par le forwarding simple, puis ajouter le stall load-use, puis le flush. Débogage VCD systématique. Utiliser des exemples de pipeline RISC-V classiques comme référence.
*   **Risque :** Timing du Chemin Critique:** L'ajout de la logique de forwarding/hazard peut allonger le chemin critique et réduire la fréquence d'horloge maximale atteignable sur FPGA. -> **Mitigation :** Écrire du code HDL propre et synchrone. Analyser les rapports de timing après synthèse. Reporter les optimisations de timing complexes. Accepter une fréquence plus basse initialement.
*   **Risque :** Interaction avec instructions multi-cycles (MUL/DIV). -> **Mitigation :** Implémenter des stalls supplémentaires pour gérer ces instructions. La FSM doit pouvoir bloquer l'avancement du pipeline pendant que l'unité MUL/DIV travaille.

**Notes:**
*   Ce sprint apporte un gain de performance théorique majeur (instructions/cycle proche de 1 en l'absence d'aléas).
*   C'est une étape fondamentale vers une implémentation CPU moderne.
*   La complexité du débogage augmente considérablement avec le pipeline.

**AIDEX Integration Potential:**
*   Aide à la conception de la structure VHDL pipelinée et des registres inter-étages.
*   Génération de la logique VHDL (complexe) pour le forwarding et la détection d'aléas/stalls/flush.
*   Assistance pour adapter l'unité de contrôle à un modèle distribué sur le pipeline.
*   Génération de séquences de test assembleur (manuel) ciblant spécifiquement les aléas pour le testbench VHDL.
*   Analyse assistée des formes d'onde VCD pour déboguer les problèmes de pipeline (ex: pourquoi un stall inattendu ? pourquoi le forwarding ne s'active pas ?).
*   Explication des différents types d'aléas et des techniques pour les résoudre en VHDL.
