# Sprint 4 VHDL (PrismChrono): Extension ALU & Instructions CSR

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Étendre significativement les capacités de calcul du cœur `prismchrono_core` en implémentant la gestion complète (Fetch, Decode, Execute, Writeback) pour la **majorité des instructions ALU des Formats R et I** définies dans l'ISA PrismChrono. Cela inclut les opérations arithmétiques (ADD, SUB), les opérations logiques ternaires spécialisées (TMIN, TMAX, TINV), et les opérations avec immédiat (ADDI, SUBI?, TMINI, TMAXI). De plus, ce sprint intègre les **instructions CSR de base** (CSRRW_T, CSRRS_T) définies dans le cadre du système de privilèges simplifié (Sprint Ω / 14 Conceptuel), permettant au CPU de lire et modifier son propre état interne minimal.

**State:** Not Started

**Priority:** Élevée (Ajoute la capacité de calcul principale du CPU)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - Extension majeure de la FSM, gestion des formats R/I, intégration ALU complète, ajout logique CSR)

**Dependencies:**
*   **Sprint 3 VHDL Terminé :** Cœur CPU minimal fonctionnel (`prismchrono_core`) avec datapath de base, FSM simple, et exécution ADDI/NOP/HALT validée en simulation.
*   **Sprint 2 VHDL Terminé :** Module `alu_24t` fonctionnel avec toutes les opérations de base (ADD, SUB, TMIN, TMAX, TINV) et calcul des flags. Module `register_file` fonctionnel.
*   **Sprint Ω / 14 Conceptuel (Simulation):** Définition des CSRs minimalistes (`mstatus_t`, etc.) et des instructions `CSRRW_T`/`CSRRS_T` (même si implémentées simplement dans le simulateur Rust, leur *fonctionnalité* et *encodage* doivent être connus pour l'implémentation VHDL).
*   **ISA PrismChrono / Sprint 5 Simu :** Encodage 12 trits précis pour toutes les instructions ALU (R/I) et CSR ciblées.

**Core Concepts:**
1.  **Extension de la FSM (Control Unit) :** Ajouter de nouveaux états et transitions pour décoder et exécuter chaque nouvelle instruction ALU (R et I) et CSR.
2.  **Décodage des Formats R et I :** Extraire les champs `Rd`, `Rs1`, `Rs2`, `Imm5` de l'instruction (`IR`) et les utiliser pour piloter le datapath (adresses RegFile, entrée ALU via MUX).
3.  **Génération des Signaux de Contrôle ALU :** L'unité de contrôle doit envoyer le bon `alu_op` à l'ALU en fonction de l'instruction décodée.
4.  **Extension du Datapath :** Potentiellement ajouter des MUX ou des chemins si nécessaire pour les nouvelles opérations (ex: chemin pour l'immédiat étendu vers l'ALU).
5.  **Logique CSR :** Ajouter un petit module ou une logique dans le datapath/contrôle pour gérer la lecture/écriture des registres CSRs (qui seraient implémentés comme des registres séparés ou un bloc de mémoire interne au CPU core).

**Visualisation des Changements Principaux :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Mise à Jour]
        IR -- Champs étendus (Rs2, Imm5, CSR idx) --> CU;
        CU -- Signaux de contrôle étendus --> DP(Datapath);
        DP -- Adresses étendues (Rs1, Rs2, Rd) --> REG_FILE;
        IMM_EXT -- Imm5 étendu --> MUX_ALU_B;
        REG_FILE -- Read Data 2 --> MUX_ALU_A; %% Correction: Rs2 souvent utilisé pour ALU A ou B selon l'op

        subgraph CU [Control Unit - FSM Étendue]
            direction TB
            Decode_State{DECODE} --> Select_Exec{Select Execution Path};
            Select_Exec -- ADD/SUB/TMIN/TMAX... (R-Type) --> Exec_ALU_R[EXEC_ALU_R];
            Select_Exec -- ADDI/TMINI/TMAXI... (I-Type) --> Exec_ALU_I[EXEC_ALU_I];
            Select_Exec -- CSRRW_T/CSRRS_T --> Exec_CSR[EXEC_CSR];
            Exec_ALU_R --> WB_Reg[WRITEBACK_REG];
            Exec_ALU_I --> WB_Reg;
            Exec_CSR --> WB_Reg; %% Si CSR instruction écrit un registre (Rd)
            WB_Reg --> Fetch_State[FETCH];
        end

        subgraph DP [Datapath - Mise à Jour]
            direction LR
            ALU(ALU 24t) <--> CSR_LOGIC(CSR Logic/Registers); %% Accès aux CSRs
            REG_FILE <--> CSR_LOGIC; %% Lecture Rs1 pour CSRRW/S
            CU -- Contrôle CSR --> CSR_LOGIC;
            IR -- CSR Index Field --> CSR_LOGIC;
            CSR_LOGIC -- CSR Read Data --> MUX_WR_DATA; %% Pour lecture CSR dans Rd
        end
    end

    style CU fill:#f9f,stroke:#333,stroke-width:2px
    style DP fill:#ccf,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL Mis à Jour :**
    *   `rtl/core/control_unit.vhd` : FSM étendue avec états et logique pour toutes les instructions ALU (R/I) et CSR ciblées.
    *   `rtl/core/datapath.vhd` : Mise à jour avec les chemins/MUX nécessaires, intégration de la logique CSR.
    *   `rtl/core/csr_registers.vhd` (Nouveau?) : Module pour stocker et gérer l'accès aux CSRs (`mstatus_t`, etc.) de manière synchrone.
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Ajouter tous les opcodes ALU/CSR, potentiellement type pour index CSR.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_prismchrono_core_alu_csr.vhd` (Nouveau ou extension du précédent) : Testbench pour le CPU complet simulant des séquences d'instructions incluant :
        *   Opérations R-Type (ADD, SUB, TMIN, TMAX, TINV).
        *   Opérations I-Type (ADDI, TMINI, TMAXI - et SUBI si ISA le définit).
        *   Opérations CSR (lire `mstatus_t`, écrire `mscratch_t` (si ajouté), lire/modifier `mstatus_t` avec CSRRS).
    *   Vérification des résultats dans les registres et potentiellement l'état des CSRs après exécution.
*   **Simulation :**
    *   Mise à jour des scripts (`sim/scripts/`) pour le nouveau testbench.
    *   Fichier VCD généré pour `tb_prismchrono_core_alu_csr`.
*   **Documentation :**
    *   Mise à jour `doc/control_unit_fsm.md` avec les nouveaux états/transitions.
    *   Mise à jour `doc/datapath_design.md`.
    *   `doc/csr_implementation.md` (Nouveau) : Description de l'implémentation des CSRs ternaires simulés.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL mis à jour et nouveaux compilent sans erreur.
*   Le testbench `tb_prismchrono_core_alu_csr` s'exécute **sans erreur d'assertion**.
*   La simulation démontre l'exécution correcte (Fetch->Decode->Execute->Writeback) pour :
    *   Au moins une instruction de chaque type ALU-R (ex: `ADD R3,R1,R2`, `TMIN R4,R1,R2`).
    *   Au moins une instruction de chaque type ALU-I (ex: `ADDI R1,R0,10`, `TMINI R5,R1,-1`).
    *   L'instruction `CSRRW_T` : Lecture de la valeur précédente d'un CSR dans Rd, écriture de la valeur de Rs1 dans le CSR.
    *   L'instruction `CSRRS_T` : Lecture de la valeur précédente dans Rd, mise à 1 des bits correspondants dans le CSR (simulation ternaire : opération `MAX` sur les trits/bits encodés?). *La sémantique exacte de RS/RC sur le ternaire doit être définie*.
*   Le décodage des formats R et I extrait correctement `Rd`, `Rs1`, `Rs2`, `Imm5`, `CSR index`.
*   L'unité de contrôle génère les bons signaux (`alu_op`, sélection MUX, `reg_write_enable`, contrôle CSR) pour chaque instruction.
*   Les valeurs lues/écrites dans les CSRs via les instructions dédiées sont correctes (vérifiables via lecture CSR ou signaux de debug).
*   Le fichier VCD permet de suivre l'exécution de ces différentes instructions à travers le pipeline (simplifié) et de valider les signaux de contrôle et les flux de données.
*   La documentation est mise à jour.

**Tasks:**

*   **[4.1] Conception Logique CSR:**
    *   Décider de l'implémentation des CSRs : registres VHDL séparés dans `prismchrono_core` ou module dédié `csr_registers.vhd`?
    *   Définir l'interface d'accès (adresse CSR, donnée écrite, donnée lue, enable lecture/écriture).
    *   Définir la sémantique *ternaire* exacte pour `CSRRS_T` (et `CSRRC_T` si implémenté plus tard). Est-ce un OR/MAX bit-à-bit sur l'encodage ? Ou une opération ternaire spécifique ? **Décision importante.**
*   **[4.2] Implémentation Module CSR (`csr_registers.vhd` ou logique intégrée):** Écrire le VHDL pour stocker les CSRs (ex: signaux internes de type `EncodedWord`) et gérer les lectures/écritures synchrones contrôlées. Gérer l'accès en fonction du privilège (ajout d'une entrée `current_privilege`).
*   **[4.3] Extension Datapath (`datapath.vhd`):**
    *   Ajouter les connexions vers/depuis le module/logique CSR.
    *   S'assurer que l'Imm5 est correctement extrait, étendu (signe), et muxé vers l'entrée B de l'ALU.
    *   S'assurer que Rs2 peut être correctement sélectionné pour l'entrée A ou B de l'ALU (à vérifier selon l'ISA exacte).
    *   Ajouter le chemin pour que la donnée lue depuis CSR puisse être écrite dans le RegFile (via `MUX_WR_DATA`).
*   **[4.4] Extension Unité Contrôle (`control_unit.vhd`):**
    *   **Décodage :** Étendre la logique de l'état `DECODE` pour reconnaître les OpCodes de toutes les nouvelles instructions ALU (R/I) et CSR. Extraire les champs nécessaires (Rs2, Imm5, CSR index).
    *   **Nouveaux États FSM :** Ajouter des états d'exécution spécifiques si nécessaire (ex: `EXEC_ALU_R`, `EXEC_ALU_I`, `EXEC_CSR`, `WB_CSR`, `WB_REG`).
    *   **Logique de Contrôle :** Générer les signaux de contrôle corrects pour chaque nouvel état/instruction :
        *   Sélection MUX ALU A/B (Reg vs PC vs Imm).
        *   Opcode ALU (`alu_op`).
        *   Enable écriture RegFile (`reg_write_enable`).
        *   Sélection source Writeback (`writeback_sel`: ALU vs Mem vs CSR).
        *   Contrôle CSR (`csr_read_en`, `csr_write_en`, `csr_addr`).
*   **[4.5] Mise à Jour `prismchrono_core.vhd`:** Instancier/connecter le module CSR si créé séparément.
*   **[4.6] Testbench CPU Core Étendu (`tb_prismchrono_core_alu_csr.vhd`):**
    *   Créer une séquence de test dans la ROM simulée incluant des exemples de chaque nouvelle instruction (ex: `ADDI R1,R0,5; ADD R2,R1,R1; TMIN R3,R1,R2; CSRRS_T R4, mstatus_t, R0; ... HALT`).
    *   Ajouter des assertions pour vérifier les valeurs finales de R1, R2, R3, R4, et potentiellement l'état final de `mstatus_t` (via un signal de debug).
*   **[4.7] Simulation & Débogage Itératif:** Exécuter la simulation, utiliser GTKWave pour tracer l'exécution des nouvelles instructions, vérifier les signaux de contrôle, les données sur les bus, les écritures registres/CSRs. Corriger les bugs dans la FSM, le datapath, ou les modules de base.
*   **[4.8] Documentation:** Mettre à jour les documents FSM, Datapath, et créer `csr_implementation.md`.

**Risks & Mitigation:**
*   **Risque :** Complexité croissante de la FSM (Control Unit). -> **Mitigation :** Utiliser des noms d'états clairs, bien commenter les transitions et la génération des contrôles. Envisager une FSM décomposée (ex: FSM principale + sous-FSM pour l'exécution).
*   **Risque :** Erreurs dans le décodage des formats R/I/CSR et l'extraction des champs. -> **Mitigation :** Tests unitaires spécifiques pour la logique de décodage si possible, validation minutieuse dans GTKWave.
*   **Risque :** Sémantique floue ou incorrecte des opérations CSR ternaires (CSRRS). -> **Mitigation :** Définir **clairement** la sémantique souhaitée *avant* l'implémentation VHDL. Documenter.
*   **Risque :** Erreurs d'interconnexion dans le datapath étendu. -> **Mitigation :** Débogage VCD attentif, vérifier que les bonnes données arrivent aux bonnes entrées (ALU, RegFile, CSRs).

**Notes:**
*   Ce sprint rend le CPU capable d'effectuer la plupart des calculs de base.
*   La gestion correcte des flags par l'ALU (Sprint 2) est essentielle et son résultat est maintenant utilisé (implicitement par les futures instructions de branchement, explicitement si des instructions lisent les flags).
*   La logique CSR introduite ici est minimale mais établit le mécanisme pour les interactions système futures (traps, MMU).

**AIDEX Integration Potential:**
*   Aide à l'écriture de la logique FSM étendue (transitions, signaux de contrôle).
*   Génération du code VHDL pour la logique d'accès CSR et le module CSR lui-même.
*   Aide à l'écriture des testbenches avec des séquences d'instructions ALU/CSR variées.
*   Suggestions pour définir la sémantique ternaire des opérations CSR bitwise (RS/RC).
*   Débogage assisté des simulations VHDL complexes.
