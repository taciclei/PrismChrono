# Sprint 7 VHDL (PrismChrono): Interface Série (UART via MMIO) & Instructions Système Base

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Doter le cœur CPU VHDL `prismchrono_core` d'une **interface de communication série (UART)** accessible via des **registres mappés en mémoire (MMIO)**. Implémenter le support pour les instructions système fondamentales **`ECALL`** et **`EBREAK`** en les faisant déclencher le **mécanisme de trap** (défini conceptuellement au Sprint Ω / 14, ou à implémenter ici si non fait). L'objectif est de permettre au CPU, exécutant du code depuis la BRAM, d'envoyer/recevoir des caractères via UART et de signaler des appels système ou des points d'arrêt au simulateur/environnement externe.

**State:** Not Started

**Priority:** Élevée (Permet l'interaction I/O externe de base et la signalisation système logicielle)

**Estimated Effort:** Medium/Large (ex: 10-15 points, T-shirt L - Implémentation/Intégration UART, logique MMIO, modification FSM/Trap)

**Dependencies:**
*   **Sprint 6 VHDL Terminé :** Cœur CPU (`prismchrono_core`) fonctionnel avec Load/Store vers BRAM, incluant la gestion des traps d'alignement. Datapath et Control Unit de base.
*   **Sprint Ω / 14 Conceptuel (ou Implémentation VHDL Partielle) :** Le **mécanisme de trap** (sauvegarde PC/Cause/Priv, saut vers handler via mtvec/stvec) doit être implémenté dans la Control Unit et les CSRs de base (`mepc`, `mcause`, `mtvec`, etc.) doivent exister, même si le système de privilèges M/S/U complet n'est pas encore totalement géré.
*   **ISA PrismChrono / Phase 3 Simu :** Encodage 12 trits pour `ECALL`, `EBREAK`. Définition des codes `mcause` pour `ECALL_U/S/M` et `Breakpoint`.
*   **Carte FPGA (ULX3S/OrangeCrab) :** Identification des pins GPIO à utiliser pour UART TX/RX et connexion à un pont USB-Série (ex: FTDI intégré ULX3S) ou configuration du Soft USB Core pour CDC-ACM (si OrangeCrab et Soft Core déjà prévu/avancé - sinon, UART simple via FTDI/externe est plus sûr pour ce sprint).

**Core Concepts:**
1.  **Contrôleur UART VHDL (`uart_controller.vhd`) :** Un module simple réalisant la sérialisation/désérialisation 8-N-1. Expose une interface MMIO via des registres (ex: `TX_DATA`, `RX_DATA`, `STATUS`).
2.  **Memory-Mapped I/O (MMIO) :** Définir une plage d'adresses mémoire physique *hors BRAM* pour les registres UART. Le décodeur d'adresse du datapath doit router les `LOAD`/`STORE` vers cette plage vers le `uart_controller`.
3.  **Conversion Ternaire <-> Binaire (Interface) :** La communication entre le CPU PrismChrono (ternaire via `EncodedWord`/`EncodedTryte`) et l'UART (binaire 8 bits) nécessite une conversion au niveau de l'interface MMIO dans le VHDL. Pour `STORET` vers `TX_DATA`, on convertit le tryte ternaire en octet. Pour `LOADT[U]` depuis `RX_DATA`, on convertit l'octet reçu en tryte ternaire (avec extension signe/zéro).
4.  **Gestion des Traps Système :** L'unité de contrôle doit reconnaître les opcodes `ECALL`/`EBREAK` et déclencher le mécanisme de trap avec la cause appropriée (`ECALL_U/S/M`, `Breakpoint`).
5.  **Intégration Top-Level & Test Matériel Initial :** Connecter les pins TX/RX du contrôleur UART aux broches physiques du FPGA via le fichier de contraintes. Effectuer un premier test matériel envoyant un caractère.

**Visualisation de l'Intégration UART (MMIO) :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Mise à Jour]
        %% Datapath
        AddrCalcLogic -- Eff Addr Phys --> ADDR_DECODER(Décodeur d'Adresse);
        ADDR_DECODER -- Select BRAM --> MEM_IF_BRAM(Interface BRAM);
        ADDR_DECODER -- Select UART --> MEM_IF_UART(Interface MMIO UART);

        MEM_IF_BRAM -- BRAM Read Data --> MUX_MEM_READ_DATA;
        MEM_IF_UART -- UART Read Data (post-conversion) --> MUX_MEM_READ_DATA;
        MUX_MEM_READ_DATA --> LOAD_EXTEND;

        REG_FILE -- Store Data (Word/Tryte) --> DATA_CONVERT_TX(Convert Tern->Bin);
        DATA_CONVERT_TX -- Octet Binaire --> MEM_IF_UART;
        REG_FILE -- Store Data (Word/Tryte) --> MEM_IF_BRAM;

        CU -- Mem Write --> ADDR_DECODER;
        CU -- Mem Read --> ADDR_DECODER;
        CU -- UART Access Signals --> MEM_IF_UART;

        %% UART Controller Integration
        UART_CTRL(uart_controller.vhd<br/>(Interface MMIO 8-bit)) <-- Connecté --> MEM_IF_UART;
        UART_CTRL -- uart_tx_serial --> FPGA_IO(FPGA Pins);
        FPGA_IO -- uart_rx_serial --> UART_CTRL;

        %% Trap Handling
        CU -- ECALL/EBREAK detected --> Trap_Handling_Logic;
    end

    FPGA_IO --> USB_UART_BRIDGE(Pont USB-Série<br/>Intégré ou Externe);
    USB_UART_BRIDGE --> HOST_PC(PC Hôte / Terminal);

    style UART_CTRL fill:#fec,stroke:#333,stroke-width:1px
    style ADDR_DECODER fill:#ffc,stroke:#333,stroke-width:1px
    style DATA_CONVERT_TX fill:#ffe,stroke:#333,stroke-width:1px
    style MEM_IF_UART fill:#fdc,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL :**
    *   `rtl/io/uart_tx.vhd` / `rtl/io/uart_rx.vhd` / `rtl/io/uart_controller.vhd` : Modules UART avec interface MMIO 8 bits (ou adaptation d'un core existant).
    *   Mise à jour `rtl/core/datapath.vhd` : Ajout décodeur d'adresse, interface MMIO UART, logique de conversion Ternaire<->Binaire pour l'accès MMIO UART.
    *   Mise à jour `rtl/core/control_unit.vhd` : Gestion des accès MMIO (potentiellement avec attente sur flags UART), déclenchement des traps ECALL/EBREAK.
    *   Mise à jour `rtl/top/prismchrono_top.vhd` : Instanciation UART et connexion aux I/O.
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Adresses MMIO UART, causes de trap.
*   **Fichier de Contraintes :** Fichier `.lpf` (ULX3S) ou `.xdc` (Arty) mis à jour pour mapper `uart_tx_serial` et `uart_rx_serial` aux pins physiques correctes (connectées au pont USB-Série).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_uart_controller_mmio.vhd` : Testbench validant l'interface MMIO de l'UART (écrire dans TX_DATA, lire STATUS, lire RX_DATA).
    *   `sim/testbenches/tb_prismchrono_core_io.vhd` : Testbench CPU complet simulant :
        *   Écriture d'une chaîne "Hello" via accès MMIO UART (`STORET` répétées).
        *   (Optionnel) Lecture d'un caractère via accès MMIO UART (attente sur flag RX_READY).
        *   Exécution de `ECALL` et `EBREAK` et vérification du déclenchement du trap avec la bonne cause via des signaux de debug ou l'état final des CSRs.
*   **Simulation & Test Matériel :**
    *   Scripts de simulation mis à jour. Fichiers VCD.
    *   **Bitstream** pour la carte FPGA (ULX3S ou autre).
    *   **Test Matériel Réussi :** Un programme simple chargé sur le FPGA envoie "Hello PrismChrono!" au terminal série du PC.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent et les testbenches s'exécutent sans erreur d'assertion.
*   Le testbench `tb_uart_controller_mmio` valide l'interface MMIO et la fonctionnalité série de base.
*   Le testbench `tb_prismchrono_core_io` démontre que le CPU peut :
    *   Écrire des données dans le registre TX UART via `STORET` à l'adresse MMIO correcte.
    *   Lire le registre de statut UART via `LOADT[U]` à l'adresse MMIO correcte.
    *   (Optionnel) Lire des données depuis le registre RX UART.
    *   Déclencher un trap avec `mcause = ECALL_U/S/M` lors de l'exécution de `ECALL`.
    *   Déclencher un trap avec `mcause = Breakpoint` lors de l'exécution de `EBREAK`.
*   Le décodeur d'adresse route correctement les accès vers BRAM ou UART MMIO.
*   La logique de conversion Tryte <-> Octet pour l'interface UART MMIO fonctionne.
*   Le design est synthétisé et un bitstream est généré sans erreurs critiques pour la carte cible.
*   Le **test matériel minimal réussit :** Le message "Hello PrismChrono!" envoyé par le programme VHDL s'affiche correctement sur le terminal série du PC.

**Tasks:**

*   **[7.1] Conception UART & MMIO:**
    *   Choisir/Implémenter les modules VHDL `uart_tx`, `uart_rx`.
    *   Concevoir `uart_controller` avec les registres MMIO (`TX_DATA`, `RX_DATA`, `STATUS` avec bits `TX_BUSY`/`TX_READY` et `RX_VALID`/`RX_READY`). Définir les adresses MMIO dans `prismchrono_types_pkg`.
    *   Définir la logique de conversion Ternaire(Tryte) <-> Binaire(Octet) pour l'interface MMIO.
*   **[7.2] Testbench `tb_uart_controller_mmio`:** Valider les écritures/lectures MMIO et leur effet sur les signaux série TX/RX et les flags de statut.
*   **[7.3] Mise à Jour Datapath (`datapath.vhd`):**
    *   Intégrer le décodeur d'adresse (ex: `if address >= UART_BASE_ADDR and address < UART_END_ADDR then uart_access <= '1'; else bram_access <= '1'; end if;`).
    *   Router les signaux (adresse relative UART, write_en, read_en, write_data convertie) vers `uart_controller`.
    *   Router les données lues de `uart_controller` (converties en ternaire) vers le MUX de lecture mémoire.
*   **[7.4] Mise à Jour Control Unit (`control_unit.vhd`):**
    *   Modifier l'état `DECODE` pour reconnaître `ECALL`, `EBREAK` et déclencher un trap (`trigger_trap <= '1'; trap_cause <= CAUSE_ECALL_U;`).
    *   Gérer les accès MMIO dans l'état `MEMORY_ACCESS` (peuvent prendre 1 cycle). *Optionnel :* Ajouter une logique de stall simple si `TX_READY` est bas lors d'un Store ou `RX_READY` bas lors d'un Load (polling).
*   **[7.5] Intégration Trap ECALL/EBREAK:** Connecter les signaux `trigger_trap` et `trap_cause` de la CU au mécanisme de trap existant.
*   **[7.6] Mise à Jour Top-Level & Contraintes:** Instancier `uart_controller`. Connecter `uart_tx_serial`/`uart_rx_serial` aux ports top-level. Mettre à jour le fichier `.lpf`/`.xdc` avec les bonnes assignations de pins physiques (celles connectées au pont USB-Série de la carte).
*   **[7.7] Testbench CPU Core IO (`tb_prismchrono_core_io.vhd`):**
    *   Créer ROM simulée avec un programme envoyant "Hello" via `STORET`s répétées à l'adresse MMIO `TX_DATA`, et incluant `ECALL`/`EBREAK`.
    *   Simuler le comportement de l'UART dans le testbench (pour la lecture ou le statut) ou juste vérifier la sortie TX.
    *   Ajouter assertions sur les traps et potentiellement la sortie série simulée.
*   **[7.8] Simulation & Débogage:** Exécuter, vérifier assertions. Utiliser GTKWave pour tracer les accès MMIO, les données sur le bus, les signaux de contrôle UART, les états FSM, et le déclenchement des traps.
*   **[7.9] Synthèse & Test Matériel UART TX:**
    *   Générer le bitstream.
    *   Préparer un programme binaire minimal "Hello" (peut être encodé à la main en attendant l'assembleur).
    *   Utiliser `ujprog` (ou autre) pour charger le bitstream et le programme en BRAM (ou l'inclure dans l'init BRAM du bitstream).
    *   Connecter un terminal série sur PC, appuyer sur Reset, vérifier la sortie.
*   **[7.10] Documentation:** Rédiger `doc/memory_map.md`, `doc/uart_interface.md`. Mettre à jour les autres docs.

**Risks & Mitigation:**
*   **(Identique)** Erreurs de timing UART. -> Calcul diviseur, tests VCD.
*   **(Identique)** Problèmes d'interfaçage MMIO. -> Débogage VCD des cycles d'accès.
*   **Risque :** Intégration Trap (ECALL/EBREAK) incorrecte avec FSM/CSRs. -> **Mitigation :** Bien définir les causes, tester le flux de trap spécifiquement dans le testbench core.
*   **(Identique)** Problèmes test matériel (pins, config terminal). -> Vérifier contraintes, config terminal. Oscilloscope si possible.

**Notes:**
*   Ce sprint établit le **canal de communication vital** pour le débogage, le chargement de code (futur), et l'interaction OS.
*   L'implémentation de l'UART est standard, mais son intégration via MMIO et la conversion Ternaire<->Binaire sont les points spécifiques ici.
*   La gestion des traps pour ECALL/EBREAK pose les bases pour les appels système et le débogage.

**AIDEX Integration Potential:**
*   Aide à la conception/implémentation du contrôleur UART et de son interface MMIO.
*   Génération de la logique VHDL de conversion Ternaire<->Binaire pour l'interface.
*   Assistance pour l'extension de la FSM (états MMIO, détection/déclenchement traps ECALL/EBREAK).
*   Aide à la création du testbench `tb_prismchrono_core_io` et des assertions.
*   Aide à la configuration du fichier de contraintes FPGA.
*   Débogage assisté des simulations et potentiellement des problèmes matériels initiaux.
