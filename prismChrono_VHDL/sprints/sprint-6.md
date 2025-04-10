# Sprint 6 VHDL (PrismChrono): Accès Mémoire (Load/Store) & Interface BRAM

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Permettre au cœur `prismchrono_core` d'interagir avec la mémoire principale (simulée dans les BRAMs du FPGA) en implémentant le support complet (Fetch, Decode, Execute/Memory, Writeback) pour les **instructions de chargement (LOADW, LOADT, LOADTU)** et de **stockage (STOREW, STORET)**. Cela nécessite d'étendre le datapath pour calculer les adresses mémoire effectives, d'interfacer avec un contrôleur BRAM, de gérer l'alignement et l'extension de signe/zéro, et d'adapter l'unité de contrôle (FSM) pour l'étape mémoire du cycle d'instruction.

**State:** Not Started

**Priority:** Critique (Permet au CPU de lire et écrire des données, essentiel pour tout programme réel)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - Logique d'adressage mémoire, interface BRAM, gestion alignement/extension, FSM étendue)

**Dependencies:**
*   **Sprint 5 VHDL Terminé :** Cœur CPU (`prismchrono_core`) fonctionnel avec ALU, CSRs, Sauts et Branches. FSM et datapath gérant ces instructions.
*   **ISA PrismChrono / Phase 3 Simu :** Encodage 12 trits précis pour `LOADW` (I), `LOADT` (I), `LOADTU` (I), `STOREW` (S), `STORET` (S). Sémantique précise (Little-Endian, extension signe/zéro, gestion alignement).
*   **Conception Interface BRAM :** Définition des signaux nécessaires pour communiquer avec les primitives BRAM du FPGA (adresse, donnée écrite, donnée lue, write enable, byte/tryte enable si supporté).

**Core Concepts:**
1.  **Calcul d'Adresse Mémoire :** `Adresse = Base (Rs1/Base) + SignExtend(OffsetI/OffsetS)`. Cette logique existe déjà partiellement pour JALR mais doit être utilisée pour Load/Store.
2.  **Interface Mémoire BRAM :** Créer ou utiliser un module VHDL (`bram_controller.vhd`?) qui abstrait l'accès aux primitives BRAM spécifiques du FPGA (ex: `DPRAM`, `SPRAM` de Lattice ECP5). Ce contrôleur prendra une adresse (binaire), des données écrites (`EncodedWord`/`EncodedTryte`), un signal d'écriture, et retournera les données lues. Il devra gérer l'encodage/décodage ternaire<->binaire et potentiellement l'accès par tryte.
3.  **Gestion Données Load/Store :**
    *   **Store :** Acheminer la donnée `Src` (depuis RegFile) vers l'entrée de données du contrôleur BRAM. Pour `STORET`, extraire le tryte de poids faible. Gérer l'activation du signal d'écriture (`mem_write_enable`).
    *   **Load :** Récupérer la donnée lue (`mem_read_data`) depuis le contrôleur BRAM. Pour `LOADT`/`LOADTU`, extraire le tryte approprié (selon adresse et Little-Endian) et l'étendre (signe ou zéro) à un `EncodedWord` complet avant de l'envoyer au RegFile pour écriture dans `Rd`.
4.  **Gestion Alignement :** La logique doit vérifier si l'adresse calculée pour `LOADW`/`STOREW` est alignée sur 8 trytes. Si non alignée, elle doit générer un **trap** (Exception : LoadAddressMisaligned / StoreAddressMisaligned). `LOADT`/`STORET` n'ont pas de contrainte d'alignement.
5.  **Extension FSM (Étape MEM) :** Introduire explicitement l'état `MEMORY_ACCESS` dans la FSM. Pour les Loads, cet état active la lecture mémoire. Pour les Stores, il active l'écriture mémoire. Les instructions ALU/Branch peuvent court-circuiter cet état. L'état `WRITEBACK` est utilisé après `MEMORY_ACCESS` pour écrire la donnée chargée dans le RegFile.

**Visualisation des Changements Datapath/Contrôle :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Mise à Jour]
        %% Datapath Additions/Modifications
        AddrCalcLogic -- Eff Addr --> ALIGN_CHECK(Alignment Check<br/>(Word Access));
        ALIGN_CHECK -- Addr OK --> MEM_IF(Memory Interface<br/>(to BRAM Controller));
        ALIGN_CHECK -- Addr Error --> CU(Control Unit - Signal Trap);

        REG_FILE -- Read Data 2 (Src for Store) --> MEM_IF;
        CU -- Mem Write Enable --> MEM_IF;
        CU -- Mem Read Enable --> MEM_IF;
        MEM_IF -- Read Data Out --> LOAD_EXTEND(Load Data<br/>Sign/Zero Extend);
        LOAD_EXTEND -- Extended Data --> MUX_WR_DATA; %% Path for Load Writeback

        %% Control Unit Modifications
        CU -- Génère Trap Cause --> Trap_Handling_Logic; %% Si alignement échoue
        IR -- Instruction Fields --> CU; %% Decode Load/Store opcodes

        subgraph CU [Control Unit - FSM Étendue]
            direction TB
            Decode_State{DECODE} --> Select_Exec{Select Exec Path};
            Select_Exec -- LOAD Op --> Exec_AddrCalc_LS[EXEC_ADDR_CALC];
            Select_Exec -- STORE Op --> Exec_AddrCalc_LS;
            Select_Exec -- ALU/Branch/etc --> ...

            Exec_AddrCalc_LS --> CheckAlign{CHECK_ALIGNMENT};
            CheckAlign -- OK --> MemAccess{MEMORY_ACCESS};
            CheckAlign -- Error --> Trap_State{TRAP}; %% Génère trap
            MemAccess -- Load Done --> WB_Load[WRITEBACK_LOAD];
            MemAccess -- Store Done --> Fetch_State[FETCH]; %% Store n'écrit pas dans RegFile
            WB_Load --> Fetch_State;
        end
    end

    style MEM_IF fill:#fdc,stroke:#333,stroke-width:1px
    style ALIGN_CHECK fill:#fdf,stroke:#333,stroke-width:1px
    style LOAD_EXTEND fill:#ffe,stroke:#333,stroke-width:1px
    style CU fill:#f9f,stroke:#333,stroke-width:2px
```

**Deliverables:**
*   **Code VHDL Mis à Jour :**
    *   `rtl/core/datapath.vhd` : Étendu avec logique de calcul d'adresse pour S-Format, logique d'alignement, logique d'extraction/extension pour Load/Store, interface vers contrôleur BRAM.
    *   `rtl/core/control_unit.vhd` : FSM étendue avec états `MEMORY_ACCESS`, `WRITEBACK_LOAD`, gestion des signaux `mem_read/write_en`, gestion des traps d'alignement.
    *   `rtl/mem/bram_controller.vhd` (Nouveau ou adapté) : Module interface BRAM gérant l'adresse binaire, l'encodage/décodage ternaire<->binaire, et potentiellement l'accès par tryte (via byte enable ou lecture/modification).
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Ajouter opcodes Load/Store. Ajouter causes de trap (`LoadAddressMisaligned`, `StoreAddressMisaligned`).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_bram_controller.vhd` (Nouveau) : Testbench pour valider le contrôleur BRAM isolément (écriture/lecture de mots/trytes ternaires).
    *   `sim/testbenches/tb_prismchrono_core_memory.vhd` (Nouveau ou extension) : Testbench CPU complet simulant des séquences `STOREW`/`STORET` suivies de `LOADW`/`LOADT`/`LOADTU` pour vérifier l'écriture et la lecture correctes, incluant les cas d'extension signe/zéro. Tester également les accès alignés et **non alignés** pour `LOADW`/`STOREW` et vérifier que le trap est bien généré.
*   **Simulation :**
    *   Mise à jour des scripts de simulation.
    *   Fichiers VCD générés pour les nouveaux testbenches.
*   **Documentation :**
    *   `doc/memory_interface.md` : Description de l'interface BRAM et de la gestion Load/Store (alignement, extension).
    *   Mise à jour FSM et Datapath docs.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL mis à jour et nouveaux compilent.
*   Le testbench `tb_bram_controller` valide les lectures/écritures ternaires via l'interface BRAM.
*   Le testbench `tb_prismchrono_core_memory` s'exécute **sans erreur d'assertion** et démontre :
    *   `STOREW` écrit correctement un mot ternaire en mémoire (vérifié par `LOADW` ultérieur).
    *   `STORET` écrit correctement le tryte de poids faible en mémoire (vérifié par `LOADT`/`LOADTU`).
    *   `LOADW` lit correctement un mot ternaire depuis la mémoire vers `Rd`.
    *   `LOADT` lit un tryte et l'étend **correctement avec le signe ternaire** sur 24 trits dans `Rd`.
    *   `LOADTU` lit un tryte et l'étend **correctement avec des zéros ternaires** sur 24 trits dans `Rd`.
    *   La logique **Little-Endian** est respectée pour les accès `LOADT`/`LOADTU`/`STORET`.
    *   Un accès `LOADW` ou `STOREW` à une adresse **non alignée** (non multiple de 8 trytes) **déclenche un trap** avec la cause appropriée (`LoadAddressMisaligned` ou `StoreAddressMisaligned`).
    *   Les accès `LOADT`/`STORET` fonctionnent pour **n'importe quelle adresse**.
*   La FSM passe bien par les états `MEMORY_ACCESS` et `WRITEBACK_LOAD` aux moments appropriés.
*   Le fichier VCD permet de tracer les adresses mémoire calculées, les données écrites/lues, les signaux de contrôle mémoire, et la génération de trap d'alignement.
*   La documentation est mise à jour.

**Tasks:**

*   **[6.1] Conception Interface BRAM:** Définir les signaux exacts pour `bram_controller.vhd` en fonction des primitives BRAM de l'ECP5 (ex: `DP16KD`). Décider comment gérer l'accès par tryte (ex: read-modify-write pour STORET, ou utiliser les byte enables si possible et pertinents). Gérer la conversion adresse logique ternaire -> adresse BRAM binaire.
*   **[6.2] Implémentation `bram_controller.vhd`:** Écrire le module VHDL. Instancier la primitive BRAM. Gérer l'encodage/décodage EncodedWord/Tryte <-> données BRAM binaires.
*   **[6.3] Testbench `tb_bram_controller.vhd`:** Écrire et exécuter le testbench pour valider le contrôleur isolément.
*   **[6.4] Mise à Jour Datapath (`datapath.vhd`):**
    *   Ajouter l'instance de `bram_controller` (ou l'interface directe si non séparé).
    *   Calculer l'adresse effective pour Load/Store (Rs1/Base + Offset).
    *   Implémenter la logique de vérification d'alignement pour LOADW/STOREW (vérifier si les 3 derniers trits de l'adresse logique sont Zéro ? Adapter à l'encodage binaire). Générer un signal `alignment_error`.
    *   Connecter `Rs2` (Src pour Store) à l'entrée de données mémoire.
    *   Implémenter la logique d'extraction/extension pour les Loads (Sign/Zero extend).
    *   Connecter la sortie de données mémoire (après extension si Load) au MUX de Writeback.
*   **[6.5] Mise à Jour Unité Contrôle (`control_unit.vhd`):**
    *   **Décodage :** Reconnaître les OpCodes Load/Store (I/S formats).
    *   **Nouveaux États FSM :** Ajouter `EXEC_ADDR_CALC_LS`, `CHECK_ALIGNMENT`, `MEMORY_ACCESS`, `WRITEBACK_LOAD`. Gérer les transitions (aller vers TRAP si `alignment_error`).
    *   **Logique Contrôle :** Générer les signaux `mem_read_enable`, `mem_write_enable`, `mem_byte_enable` (si utilisé), sélection source Writeback pour Load, etc., dans les bons états. Propager le signal `alignment_error` pour déclencher un trap.
*   **[6.6] Intégration Trap Alignement:** Connecter le signal `alignment_error` (ou un signal `trigger_trap` de CU) au mécanisme de trap (Sprint Omega / 14) avec les bonnes causes.
*   **[6.7] Testbench CPU Core Étendu (`tb_prismchrono_core_memory.vhd`):**
    *   Créer ROM simulée avec des séquences :
        *   STOREW R1, addr ; LOADW R2, addr -> assert R1=R2.
        *   STORET R1, addr ; LOADT R2, addr -> assert R2 = sign_extend(tryte(R1)).
        *   STORET R1, addr ; LOADTU R3, addr -> assert R3 = zero_extend(tryte(R1)).
        *   Tester Little Endian (ex: STOREW, puis LOADT à addr, addr+1... addr+7).
        *   Tester STOREW/LOADW sur adresse non alignée -> Doit finir dans l'état HALTED après un trap (si le handler de trap par défaut fait HALT).
        *   Tester STORET/LOADT sur adresse non alignée -> Doit fonctionner normalement.
    *   Ajouter les assertions nécessaires.
*   **[6.8] Simulation & Débogage:** Exécuter, vérifier assertions. Utiliser GTKWave pour tracer adresses mémoire, données échangées avec BRAM, signaux `mem_read/write_en`, `alignment_error`, état FSM, mise à jour `Rd` pour Load.
*   **[6.9] Documentation:** Rédiger/Mettre à jour les documents.

**Risks & Mitigation:**
*   **Risque :** Interface BRAM complexe (primitives FPGA, accès par tryte). -> **Mitigation :** Commencer par un accès mot entier aligné. Utiliser les wizards/IP fournis par Lattice Diamond si possible (mais peut être moins portable pour Yosys). Bien tester le `bram_controller` isolément.
*   **Risque :** Logique Little-Endian + extraction/extension tryte sujette aux erreurs. -> **Mitigation :** Dessiner le mapping mémoire. Écrire des tests très spécifiques pour lire/écrire chaque tryte d'un mot. Valider soigneusement l'extension de signe ternaire.
*   **Risque :** Gestion de l'alignement et déclenchement du trap incorrect. -> **Mitigation :** Bien définir la condition d'alignement sur l'adresse *binaire* utilisée pour la BRAM. Tester spécifiquement les adresses limites alignées/non alignées.
*   **Risque :** Timing mémoire BRAM (cycles de lecture/écriture). -> **Mitigation :** Supposer 1 cycle de lecture/écriture pour la BRAM interne dans la FSM pour commencer. Adapter si les spécifications BRAM ou la synthèse indiquent plus.

**Notes:**
*   Ce sprint rend le CPU capable d'interagir avec son état principal : la mémoire. C'est une étape majeure.
*   La gestion correcte de l'endianness et de l'extension signe/zéro est cruciale pour la compatibilité future avec un éventuel compilateur ou des bibliothèques.
*   La gestion des traps d'alignement introduit une première forme de gestion d'exception matérielle.

**AIDEX Integration Potential:**
*   Aide à la conception de l'interface BRAM et à l'utilisation des primitives FPGA spécifiques (si infos dispo).
*   Génération du code VHDL pour la logique d'alignement et d'extraction/extension ternaire.
*   Aide à l'extension de la FSM (nouveaux états, transitions, signaux de contrôle mémoire).
*   Génération de scénarios de test VHDL pour couvrir les cas Load/Store (aligné/non aligné, signe/zéro extend, endianness).
*   Débogage assisté des simulations liées aux accès mémoire et aux traps d'alignement.
