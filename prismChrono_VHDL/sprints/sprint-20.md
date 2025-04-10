# Sprint 20 VHDL (PrismChrono): Multi-Cœur Réaliste, Périphériques SPI/I²C & Intégration SoC

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Amener l'implémentation VHDL de PrismChrono à un niveau de **système sur puce (SoC) intégré et plus réaliste**, en améliorant significativement le **support multi-cœur** (modèle de cohérence/communication) et en ajoutant des **contrôleurs pour des périphériques standards essentiels (SPI, I²C)**, accessibles via MMIO. Ce sprint vise à créer une plateforme matérielle (sur FPGA) plus complète et polyvalente, prête à accueillir un noyau d'OS ternaire capable d'interagir avec du stockage (carte SD via SPI) et d'autres capteurs/périphériques (via I²C).

**State:** Not Started

**Priority:** Élevée (Augmente considérablement les capacités et l'utilité de la plateforme matérielle)

**Estimated Effort:** Très Large (ex: 25-40 points, T-shirt XL/XXL - Cohérence cache avancée est très complexe, contrôleurs SPI/I²C + intégration bus)

**Dependencies:**
*   **Sprint 19 VHDL Terminé :** Cœur CPU VHDL stable avec pipeline, cache L1, MMU, DDR, interruptions, atomiques, instructions spécialisées de base. Version multi-cœur (peut-être séquentielle) existante.
*   **Conception Cohérence Cache (Améliorée) :** Si le MSI simple du S16 est trop limitatif, envisager un protocole légèrement plus avancé (MESI ?) ou affiner l'implémentation MSI.
*   **Spécifications SPI & I²C :** Compréhension des protocoles pour implémenter les contrôleurs.
*   **Système de Bus Interne :** Un arbitre de bus mémoire existe (Sprint 14/16). Il faudra peut-être l'étendre ou utiliser un bus plus standardisé (Wishbone, AXI-Lite pour périphériques) pour connecter les nouveaux contrôleurs.

**Core Concepts:**
1.  **Cohérence de Cache Multi-Cœur (Améliorée) :**
    *   **Objectif :** Assurer que les données partagées entre les caches des différents cœurs restent cohérentes de manière plus robuste ou performante que le MSI simple (si celui-ci pose problème).
    *   **Approche :** Affiner le protocole MSI VHDL (gestion des write-backs, invalidations) OU explorer l'implémentation d'un protocole **MESI (Modified, Exclusive, Shared, Invalid)** simplifié. MESI peut optimiser les lectures/écritures sur des données non partagées (état Exclusive).
    *   **Défi :** La complexité augmente considérablement avec MESI (plus d'états, plus de transactions bus).
2.  **Contrôleur SPI VHDL (`spi_controller.vhd`) :**
    *   **Objectif :** Permettre la communication avec des périphériques SPI externes (typiquement carte SD, capteurs, mémoires Flash).
    *   **Fonctionnalité :** Gérer la génération de l'horloge SPI (SCLK), la transmission/réception de données sur MOSI/MISO, et le contrôle des lignes Chip Select (CS).
    *   **Interface :** Exposer des registres MMIO pour configurer le SPI (vitesse, mode CPOL/CPHA), envoyer/recevoir des données (registre de données ou FIFO), et lire l'état (ex: TX busy, RX data ready).
3.  **Contrôleur I²C VHDL (`i2c_controller.vhd`) :**
    *   **Objectif :** Communiquer avec des périphériques I²C (capteurs, EEPROMs, etc.).
    *   **Fonctionnalité :** Gérer le protocole I²C Maître (génération START/STOP, envoi adresse esclave + R/W bit, transmission/réception données, gestion ACK/NACK).
    *   **Interface :** Exposer des registres MMIO pour configurer (adresse esclave, vitesse?), démarrer une transaction, écrire/lire des données, lire l'état (ex: busy, ACK reçu?).
4.  **Intégration Système / Bus Périphériques :**
    *   **Décodeur d'Adresse :** Étendre le décodeur d'adresse MMIO pour inclure les plages des nouveaux contrôleurs SPI et I²C.
    *   **Bus Périphérique (Optionnel mais Recommandé) :** Si le nombre de périphériques MMIO augmente, introduire un bus périphérique dédié plus simple et plus lent que le bus mémoire principal (ex: AXI4-Lite ou Wishbone classique) pour connecter les cœurs CPU aux contrôleurs UART, SPI, I²C, PLIC, etc. Le bus principal reste pour Cache <-> Contrôleur DDR. Cela simplifie l'arbitrage et le timing.

**Visualisation de l'Intégration Système :**

```mermaid
graph TD
    subgraph System_Top [prismchrono_top.vhd - SoC Étendu]
        %% Coeurs et Mémoire
        Core_0(PrismChrono Core 0 + Cache L1 Cohérent)
        Core_1(PrismChrono Core 1 + Cache L1 Cohérent)
        BUS_MEM(Bus Mémoire Principal<br/>(Coherent))
        MEM_CTRL(Contrôleur DDR3L) --> DDR_SDRAM[(RAM Externe)];

        Core_0 -- Cache Access --> BUS_MEM;
        Core_1 -- Cache Access --> BUS_MEM;
        BUS_MEM --> MEM_CTRL;

        %% Bus Périphériques (Nouveau/Amélioré)
        BUS_PERIPH(Bus Périphériques<br/>(ex: AXI-Lite ou Wishbone));
        BRIDGE(Pont Bus Mem <-> Bus Périph); %% Pour accès CPU au bus périph

        Core_0 -- MMIO Access --> BRIDGE;
        Core_1 -- MMIO Access --> BRIDGE;
        BRIDGE --> BUS_PERIPH;

        %% Périphériques sur Bus Périphérique
        UART_CTRL(UART Controller) --> BUS_PERIPH;
        SPI_CTRL(SPI Controller - Nouveau) --> BUS_PERIPH;
        I2C_CTRL(I2C Controller - Nouveau) --> BUS_PERIPH;
        PLIC(PLIC Simplifié) --> BUS_PERIPH;
        TIMER(Timer Unit) --> BUS_PERIPH;
        DEBUG(Debug Module IF?) --> BUS_PERIPH;

        %% Connexions Externes
        FPGA_IO(FPGA Pins)
        UART_CTRL -- TX/RX --> FPGA_IO;
        SPI_CTRL -- MOSI/MISO/SCLK/CSn --> FPGA_IO;
        I2C_CTRL -- SDA/SCL --> FPGA_IO;
        PLIC -- External Int --> FPGA_IO;
    end

    style BUS_PERIPH fill:#eef,stroke:#333
    style SPI_CTRL fill:#fec,stroke:#333
    style I2C_CTRL fill:#fec,stroke:#333
    style BRIDGE fill:#ddd,stroke:#333
```

**Deliverables:**
*   **Code VHDL Mis à Jour/Nouveaux :**
    *   `rtl/cache/l1_cache.vhd` / `rtl/bus/memory_bus.vhd` : Modifiés pour implémenter le protocole de cohérence amélioré (ex: MESI simplifié).
    *   `rtl/io/spi_controller.vhd` (Nouveau) : Contrôleur SPI maître avec interface MMIO.
    *   `rtl/io/i2c_controller.vhd` (Nouveau) : Contrôleur I²C maître avec interface MMIO.
    *   `rtl/bus/peripheral_bus.vhd` (Nouveau?) : Implémentation du bus périphérique.
    *   `rtl/bus/bus_bridge.vhd` (Nouveau?) : Pont entre bus mémoire et bus périphérique.
    *   Mise à jour `rtl/core/datapath.vhd` / `rtl/top/` : Intégration du pont et accès aux nouveaux périphériques via MMIO.
    *   Mise à jour `rtl/pkg/` : Adresses MMIO pour SPI, I²C.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** Pas de nouvelles instructions, mais potentiellement des pseudo-instructions ou macros pour faciliter l'accès aux périphériques SPI/I²C.
*   **Fichier de Contraintes :** Mappage des pins GPIO pour SPI (MOSI, MISO, SCLK, CS) et I²C (SDA, SCL).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_cache_coherence_advanced.vhd` : Valide le protocole de cohérence amélioré (MESI?) avec des scénarios plus complexes (écritures concurrentes, etc.).
    *   `sim/testbenches/tb_spi_controller.vhd` : Valide le contrôleur SPI isolément (simuler un périphérique esclave SPI simple).
    *   `sim/testbenches/tb_i2c_controller.vhd` : Valide le contrôleur I²C isolément (simuler un périphérique esclave I²C simple).
    *   `sim/testbenches/tb_prismchrono_soc_final.vhd` (Nouveau/Final) : Testbench système complet (Multi-Cœurs + Caches Cohérents + MMU + DDR + PLIC + UART + SPI + I²C). Exécuter un code qui :
        *   Utilise LR/SC avec le nouveau protocole de cohérence.
        *   Communique via UART.
        *   Configure et effectue un transfert simple via SPI (ex: écrire/lire quelques octets vers un esclave simulé).
        *   Configure et effectue un transfert simple via I²C (ex: écrire/lire registre d'un esclave simulé).
        *   Gère une interruption externe via le PLIC.
*   **Simulation & Synthèse :**
    *   Validation en simulation de toutes les nouvelles fonctionnalités et interactions.
    *   Rapport de Synthèse/Timing FINAL : État final des ressources et FMax. **Attention : l'ajout de la cohérence cache et des périphériques peut encore impacter la FMax.**

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent. Tous les testbenches passent sans erreur d'assertion.
*   Le protocole de **cohérence de cache amélioré** (ex: MESI simplifié) est fonctionnel et validé en simulation multi-cœur.
*   Le **contrôleur SPI** est fonctionnel : le CPU peut configurer, envoyer et recevoir des données via SPI (validé en simulation via `tb_spi_controller` et `tb_prismchrono_soc_final`).
*   Le **contrôleur I²C** est fonctionnel : le CPU peut configurer, initier des transactions maître, envoyer et recevoir des données via I²C (validé en simulation via `tb_i2c_controller` et `tb_prismchrono_soc_final`).
*   Les nouveaux périphériques sont correctement intégrés via le **bus périphérique** et accessibles via **MMIO** par le CPU (décodage d'adresse fonctionnel).
*   Le design complet final est **synthétisé et implémenté avec succès** sur le FPGA cible. La FMax finale et l'utilisation des ressources sont documentées.
*   (Bonus) Un test matériel simple montre la communication SPI ou I²C avec un périphérique externe réel (ex: capteur I²C, mémoire Flash SPI) connecté à la carte FPGA.

**Tasks:**

*   **[20.1] Conception/Implémentation Cohérence Cache Améliorée:** Choisir/adapter le protocole (MSI affiné ou MESI simple). Modifier `l1_cache.vhd` et `memory_bus.vhd`. Documenter.
*   **[20.2] Testbench `tb_cache_coherence_advanced`:** Écrire et valider.
*   **[20.3] Conception/Implémentation `spi_controller.vhd`:** Logique SPI maître, interface MMIO.
*   **[20.4] Testbench `tb_spi_controller`:** Écrire et valider.
*   **[20.5] Conception/Implémentation `i2c_controller.vhd`:** Logique I²C maître, interface MMIO.
*   **[20.6] Testbench `tb_i2c_controller`:** Écrire et valider.
*   **[20.7] Conception/Implémentation Bus Périphérique & Pont:** Choisir un standard (AXI-Lite, Wishbone?) ou un bus custom simple. Implémenter `peripheral_bus.vhd` et `bus_bridge.vhd`.
*   **[20.8] Intégration Système:** Mettre à jour le Top-Level VHDL. Étendre le décodeur d'adresse MMIO. Connecter CPU, UART, SPI, I²C, PLIC, Timer... au bus périphérique via le pont.
*   **[20.9] Mise à Jour Contraintes FPGA:** Ajouter les assignations de pins pour SPI et I²C.
*   **[20.10] Testbench Système Final (`tb_prismchrono_soc_final`):** Écrire un scénario de test assembleur (manuel ou généré) complexe validant l'interaction avec tous les périphériques et la cohérence cache.
*   **[20.11] Simulation & Débogage Final:** Exécuter et déboguer le testbench système complet.
*   **[20.12] Synthèse Finale & Validation Timing:** Lancer la chaîne FPGA. Analyser et documenter les résultats finaux FMax/Ressources.
*   **[20.13] (Optionnel) Test Matériel SPI/I²C:** Connecter un périphérique simple et écrire un petit programme de test pour interagir avec.

**Risks & Mitigation:**
*   **(Risque MAJEUR) Complexité Cohérence Cache MESI:** Encore plus complexe que MSI. -> **Mitigation :** Rester sur un MSI robuste et bien testé si MESI s'avère trop difficile. Laisser les optimisations de cohérence avancées pour plus tard.
*   **Risque :** Erreurs subtiles dans les contrôleurs SPI/I²C (timing, protocole). -> **Mitigation :** Utiliser des cores open source existants et éprouvés pour SPI/I²C si possible (adaptés à l'interface bus choisie). Tester isolément de manière exhaustive.
*   **Risque :** Complexité de l'intégration du bus système (arbitrage, pont). -> **Mitigation :** Utiliser un standard de bus simple (Wishbone classique) si possible. Commencer avec un arbitrage simple.
*   **Risque :** Le design complet devient trop gros ou trop lent pour le FPGA. -> **Mitigation :** C'est une possibilité réelle. Prioriser les fonctionnalités. Optimiser le code VHDL. Documenter les limites atteintes sur la plateforme ECP5-85F.

**Notes:**
*   Ce sprint vise à créer une **plateforme SoC PrismChrono relativement complète** sur le FPGA, avec les capacités mémoire, système et E/S de base nécessaires pour un OS.
*   La **complexité de l'intégration** et la **validation du timing** sont les défis principaux.
*   Après ce sprint, le focus pourrait (devrait !) basculer massivement vers le **développement logiciel** (Noyau OS Ternaire, pilotes, applications) pour exploiter cette plateforme matérielle.

**AIDEX Integration Potential:**
*   Aide à la conception/implémentation du protocole de cohérence cache MESI simplifié.
*   Recherche et adaptation de cores VHDL open source pour SPI et I²C.
*   Assistance pour la conception et l'implémentation du bus périphérique et du pont.
*   Génération de code assembleur complexe pour le testbench système final, interagissant avec tous les périphériques.
*   Analyse assistée des traces VCD pour déboguer les interactions bus, cache, et périphériques.
*   Aide à l'interprétation finale des rapports de synthèse et de timing.
