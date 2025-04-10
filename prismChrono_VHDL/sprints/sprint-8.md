# Sprint 8 VHDL (PrismChrono): Intégration Mémoire Externe (SDRAM/DDR3L) & Cache L1 Simple

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Intégrer le support pour la **mémoire RAM externe (SDRAM ou DDR3L)** présente sur la carte FPGA (ULX3S ou OrangeCrab) et implémenter un **système de cache L1 unifié simple** (ou caches I/D séparés si préféré) pour améliorer les performances d'accès mémoire. Cela implique d'intégrer ou de développer un **contrôleur mémoire externe** en VHDL, d'adapter l'interface mémoire du CPU, et d'ajouter la logique de cache (gestion des tags, données, validité, politique de remplacement/écriture).

**State:** Not Started

**Priority:** Très Élevée (Lève la limitation majeure de taille mémoire et introduit l'optimisation de performance essentielle du cache)

**Estimated Effort:** Très Large (ex: 20-30 points, T-shirt XL - Contrôleur mémoire externe est complexe, logique de cache aussi)

**Dependencies:**
*   **Sprint 7 VHDL Terminé :** Cœur CPU (`prismchrono_core`) fonctionnel avec accès BRAM/MMIO UART et gestion des traps de base.
*   **Carte FPGA (ULX3S/OrangeCrab) :** Doit posséder de la RAM externe (SDRAM/DDR3L) fonctionnelle. Identification des pins connectées à la RAM.
*   **Contrôleur Mémoire Externe :** Soit utilisation d'un IP Core open source (ex: **LiteDRAM** pour DDR3 sur ECP5), soit développement/adaptation d'un contrôleur SDRAM/DDR3L plus simple (très complexe). **Le choix de l'approche pour le contrôleur est une décision de conception clé.**
*   **Conception Cache L1 :** Définir les paramètres du cache (taille totale, taille de ligne/bloc, associativité, politique remplacement - LRU ?, politique écriture - Write-Back/Write-Through?).

**Core Concepts:**
1.  **Contrôleur Mémoire Externe (DDR3L/SDRAM) :** Un module VHDL complexe qui gère le protocole de communication spécifique (timings, commandes REFRESH, READ, WRITE, etc.) avec la puce de RAM externe. Il expose une interface plus simple (ex: AXI, Avalon, ou custom) au reste du système FPGA. L'utilisation d'un générateur de core comme **LiteDRAM** est **fortement recommandée** pour la DDR3L sur ECP5.
2.  **Système de Cache L1 :**
    *   **Structure :** Mémoire interne au FPGA (BRAM) pour stocker les tags (partie haute de l'adresse), les données des lignes de cache, et les bits d'état (Valid, Dirty).
    *   **Logique :** Vérifie si l'adresse demandée par le CPU est dans le cache (hit/miss).
        *   **Hit :** Fournit/reçoit les données directement depuis/vers le cache (rapide).
        *   **Miss :** Déclenche une lecture depuis la mémoire externe (via le contrôleur DDR/SDRAM), charge la ligne correspondante dans le cache (en remplaçant potentiellement une ligne existante selon la politique LRU), puis sert le CPU. Si remplacement d'une ligne "dirty" (modifiée), il faut d'abord l'écrire en mémoire externe (Write-Back).
3.  **Interface CPU <-> Cache <-> Mémoire Externe :** Le CPU communique maintenant avec le Cache L1. C'est le cache qui décide d'accéder (ou non) à la mémoire externe via le contrôleur DDR/SDRAM.
4.  **Politique d'Écriture :**
    *   **Write-Through :** Chaque écriture CPU va *à la fois* dans le cache et en mémoire externe. Simple mais plus lent.
    *   **Write-Back :** L'écriture se fait *seulement* dans le cache, marquant la ligne comme "dirty". L'écriture en mémoire externe n'a lieu que lorsque la ligne dirty est remplacée. Plus rapide mais plus complexe (gestion du bit Dirty). **Recommandé pour la performance.**
5.  **Cohérence (Mono-Cœur) :** Pour l'instant, on ne se préoccupe pas de la cohérence entre plusieurs caches (multi-cœur).

**Visualisation de la Nouvelle Hiérarchie Mémoire :**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [CPU Core]
        CPU_IF(IF Stage) -- Addr Virt/Phys --> L1_CACHE;
        CPU_MEM(MEM Stage) -- Addr Virt/Phys, Data, R/W --> L1_CACHE;
        L1_CACHE -- Data / Stall --> CPU_IF;
        L1_CACHE -- Data / Stall --> CPU_MEM;
    end

    subgraph L1_CACHE [Cache L1 (BRAM FPGA)]
        direction LR
        Cache_Logic{Cache Controller Logic<br/>(Hit/Miss, LRU, WB)};
        Cache_Tags[(Tag RAM)];
        Cache_Data[(Data RAM)];
        Cache_Logic -- Access --> Cache_Tags;
        Cache_Logic -- Access --> Cache_Data;
    end

    subgraph MEM_CTRL [Contrôleur Mémoire Externe (HDL/LiteDRAM)]
         Mem_IF{Interface Simple<br/>(AXI or Custom)};
         Mem_Logic{DDR3L/SDRAM Protocol Logic};
         Mem_IF <--> Mem_Logic;
    end

    subgraph DDR3L_SDRAM [RAM Externe (Puce sur Carte)]
        DDR_Chip[(DDR3L/SDRAM Chip)];
    end

    CPU_Core -- Cache Requests --> L1_CACHE;
    L1_CACHE -- Memory Requests (on Miss/Writeback) --> MEM_CTRL;
    MEM_CTRL -- DDR/SDRAM Signals --> DDR3L_SDRAM;
    DDR3L_SDRAM -- DDR/SDRAM Signals --> MEM_CTRL;

    style L1_CACHE fill:#ccf,stroke:#333,stroke-width:1px
    style MEM_CTRL fill:#cfc,stroke:#333,stroke-width:1px
    style DDR3L_SDRAM fill:#eee,stroke:#333,stroke-width:1px

```

**Deliverables:**
*   **Code VHDL :**
    *   Intégration de l'**IP Core du contrôleur mémoire externe** (ex: LiteDRAM généré ou autre core VHDL) dans le projet top-level.
    *   `rtl/cache/l1_cache.vhd` (Nouveau) : Module implémentant la logique du cache L1 (Tags, Data, Contrôleur Hit/Miss/LRU/Write-Back).
    *   Mise à jour `rtl/core/prismchrono_core.vhd` (ou `top`) : Remplacer l'accès direct à l'interface BRAM/MMIO par un accès à l'interface du `l1_cache`. Gérer les signaux de `stall` si le cache ou la mémoire externe ne répond pas immédiatement.
    *   Mise à jour `rtl/mem/` pour inclure le contrôleur mémoire externe.
*   **Fichier de Contraintes :** Mise à jour majeure du `.lpf`/`.xdc` pour ajouter **toutes les contraintes de timing et de mapping de pins** pour l'interface DDR3L/SDRAM. C'est une étape critique et complexe.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_l1_cache.vhd` : Testbench pour valider le cache isolément. Simuler un contrôleur mémoire simple (avec latence) et vérifier les hits, misses, remplacements LRU, écritures write-back.
    *   `sim/testbenches/tb_prismchrono_top_ddr.vhd` (Nouveau ou extension majeure) : Testbench pour le système complet CPU + Cache + Contrôleur DDR + **Modèle de simulation de la RAM DDR/SDRAM externe**. Exécuter un programme nécessitant plus de mémoire que la BRAM, ou effectuant des accès répétitifs pour tester le cache.
*   **Simulation & Test Matériel :**
    *   Scripts de simulation mis à jour. Fichiers VCD.
    *   **Bitstream** pour la carte FPGA incluant le contrôleur mémoire externe et le cache.
    *   **Test Matériel Réussi :** Un programme exécuté sur le FPGA peut lire/écrire avec succès dans la **mémoire externe DDR3L/SDRAM** (vérifiable via UART ou debug JTAG). La présence du cache améliore (potentiellement) le temps d'exécution de boucles accédant aux mêmes données (difficile à mesurer précisément sans compteurs de cycles/performance).

**Acceptance Criteria (DoD - Definition of Done):**
*   Le contrôleur mémoire externe (ex: LiteDRAM) est correctement généré et/ou intégré.
*   Le module `l1_cache` compile et passe son testbench `tb_l1_cache` (validation hit/miss, LRU, write-back).
*   Le CPU (`prismchrono_core`) est modifié pour interagir avec le `l1_cache` et gérer les signaux de `stall`.
*   Le design complet (CPU + Cache + Contrôleur Mem) est **synthétisé, implémenté (P&R) et un bitstream est généré SANS ERREURS DE TIMING CRITIQUES** pour la carte cible, en utilisant le fichier de contraintes DDR/SDRAM. (C'est un critère difficile à atteindre).
*   Le testbench complet `tb_prismchrono_top_ddr` s'exécute sans erreur et montre que le CPU accède correctement aux données via le cache et la mémoire externe simulée.
*   Le **test matériel réussit :** Le CPU sur FPGA peut charger (via UART/JTAG) et exécuter un programme qui utilise la RAM externe DDR3L/SDRAM pour ses données/pile/code, au-delà de la capacité de la BRAM seule.

**Tasks:**

*   **[8.1] Choix & Intégration Contrôleur Mémoire Externe:**
    *   **Recherche/Décision :** Utiliser LiteDRAM (recommandé pour ECP5/DDR3) ou trouver/adapter un autre core VHDL ?
    *   **Génération/Intégration :** Suivre la documentation de LiteDRAM (ou autre) pour générer le core VHDL pour la carte cible (OrangeCrab/ULX3S) et l'intégrer dans le projet VHDL top-level. Définir l'interface (AXI, Wishbone, custom?) entre le cache et ce contrôleur.
*   **[8.2] Conception Cache L1:**
    *   Choisir les paramètres : Taille (ex: 8 kTrytes ? 16 kTrytes ? -> Utilisation BRAM), Taille de ligne (ex: 4 ou 8 Words ?), Associativité (Direct-Mapped simple ? 2-way ?), Politique (LRU, Write-Back). Documenter.
    *   Concevoir la structure des BRAMs pour Tags + Data + Valid/Dirty bits.
    *   Concevoir la logique du contrôleur de cache (FSM ou combinatoire complexe).
*   **[8.3] Implémentation `l1_cache.vhd`:** Écrire le module VHDL pour le cache L1.
*   **[8.4] Testbench `tb_l1_cache.vhd`:** Écrire un testbench simulant le CPU et la mémoire externe pour valider la logique du cache isolément.
*   **[8.5] Mise à Jour CPU Core & Datapath:**
    *   Modifier l'interface mémoire du CPU pour parler au cache (signaux d'adresse, donnée, R/W, valid, ready/stall).
    *   Gérer le signal `stall` venant du cache dans la FSM de l'unité de contrôle (figer le pipeline ou répéter l'état si le cache n'est pas prêt).
*   **[8.6] Mise à Jour Top-Level:** Instancier `l1_cache` entre le `prismchrono_core` et le `mem_controller`. Connecter les interfaces.
*   **[8.7] Contraintes de Timing DDR/SDRAM:** Créer ou adapter le fichier de contraintes (`.lpf`/`.xdc`) pour spécifier les timings critiques de l'interface mémoire externe. **C'est une étape experte et cruciale.** Consulter la documentation de la carte et du contrôleur mémoire.
*   **[8.8] Testbench Complet (`tb_prismchrono_top_ddr.vhd`):**
    *   Instancier le design complet.
    *   Ajouter un **modèle de simulation VHDL pour la puce DDR3L/SDRAM externe**. Ces modèles sont souvent complexes mais parfois fournis par les fabricants ou existent en open source (peuvent ralentir la simulation).
    *   Pré-charger un programme en mémoire externe simulée qui dépasse la taille de la BRAM ou effectue des accès répétitifs.
    *   Vérifier le résultat final.
*   **[8.9] Synthèse, Implémentation & Génération Bitstream:**
    *   Lancer la chaîne complète (Yosys/nextpnr ou Vivado).
    *   **Analyser attentivement les rapports de timing.** Corriger les violations de timing si possible (optimisation HDL, ajustement contraintes). C'est souvent itératif.
*   **[8.10] Test Matériel:** Charger le bitstream. Charger un programme de test (via UART/JTAG) qui utilise la RAM externe. Vérifier son fonctionnement (via UART ou debug).

**Risks & Mitigation:**
*   **(Risque MAJEUR) Complexité Contrôleur DDR/SDRAM & Timing:** Faire fonctionner une interface mémoire externe à haute vitesse est le défi le plus courant et le plus difficile en conception FPGA. -> **Mitigation :** Utiliser un générateur de core éprouvé comme **LiteDRAM**. Suivre *très attentivement* la documentation et les exemples pour la carte cible. Commencer avec une fréquence d'horloge basse. Allouer beaucoup de temps au débogage du timing.
*   **Risque :** Logique de Cache complexe et sujette aux bugs (LRU, Write-Back). -> **Mitigation :** Commencer par un cache très simple (Direct-Mapped, Write-Through). Valider intensivement avec `tb_l1_cache`.
*   **Risque :** Consommation Ressources FPGA (Contrôleur + Cache + CPU). -> **Mitigation :** Surveiller l'utilisation des LUTs/BRAM/FFs après chaque étape de synthèse. Optimiser le code VHDL si nécessaire. Faire des compromis sur la taille/complexité du cache ou du CPU si besoin.
*   **Risque :** Simulation avec modèle DDR/SDRAM très lente. -> **Mitigation :** Utiliser le modèle DDR/SDRAM seulement pour les tests finaux. Valider le cache avec un modèle mémoire simple mais avec latence dans `tb_l1_cache`.

**Notes:**
*   Ce sprint représente un **grand pas en performance et capacité mémoire**.
*   L'intégration du contrôleur mémoire externe est souvent l'étape la plus difficile d'un projet SoC FPGA.
*   Un cache fonctionnel, même simple, est crucial pour masquer la latence de la RAM externe.

**AIDEX Integration Potential:**
*   Aide à la configuration et à l'intégration de LiteDRAM (si documentation/exemples fournis).
*   Génération du code VHDL pour la structure du cache L1 (logique de tag/data/état).
*   Aide à l'implémentation de la logique LRU et Write-Back.
*   Assistance pour la modification de la FSM du CPU pour gérer le stall du cache.
*   Aide à la création des fichiers de contraintes de timing DDR/SDRAM (basé sur la doc).
*   Génération de scénarios de test pour le cache et le système complet avec DDR.
*   Débogage assisté des violations de timing rapportées par les outils P&R.
*   Analyse des goulots d'étranglement potentiels (cache miss rate simulé, etc.).
