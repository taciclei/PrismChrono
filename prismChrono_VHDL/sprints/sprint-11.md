# Sprint 11 VHDL (PrismChrono): Caches L1 Séparés & MMU Ternaire de Base

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Améliorer significativement les performances mémoire et jeter les bases d'un système d'exploitation moderne en implémentant :
1.  Un **système de cache L1 avec des caches séparés pour les Instructions (I-Cache) et les Données (D-Cache)**, réduisant les aléas structurels et augmentant la bande passante mémoire vue par le pipeline.
2.  Une première version fonctionnelle de l'**Unité de Gestion Mémoire (MMU) ternaire simplifiée (`MMU_T`)**, capable d'effectuer la translation d'adresse virtuelle vers physique et de générer des fautes de page, contrôlée par le CSR `satp_t`.

**State:** Not Started

**Priority:** Très Élevée (Performances mémoire cruciales pour le pipeline, MMU essentielle pour OS)

**Estimated Effort:** Très Large (ex: 20-35 points, T-shirt XL - Logique de cache x2, Contrôleur MMU/TLB, intégration complexe avec pipeline/mémoire externe)

**Dependencies:**
*   **Sprint 10 VHDL Terminé :** Cœur CPU pipeliné (5 étages) fonctionnel avec gestion des aléas de base et forwarding.
*   **Sprint 8 VHDL (ou équivalent) :** Intégration fonctionnelle du **contrôleur mémoire externe (DDR3L/SDRAM)** et de son interface.
*   **Conception MMU_T (Sprint 14 Conceptuel / Docs) :** Spécification du format `satp_t`, `PTE_T`, schéma de translation, et codes de faute de page ternaires.
*   **Système de Privilèges/Traps (Sprint 9/Omega) :** CSRs `satp_t`, `m/sepc`, `m/scause`, `m/stvec` implémentés. Mécanisme de trap fonctionnel pour gérer les futures fautes de page.

**Core Concepts:**
1.  **Caches L1 Séparés (Harvard Modifié) :**
    *   `I-Cache`: Cache dédié aux instructions, lu par l'étage IF. Typiquement Read-Only (du point de vue CPU), plus simple (pas de politique d'écriture/dirty bits).
    *   `D-Cache`: Cache dédié aux données, accédé par l'étage MEM pour les Load/Store. Doit gérer la lecture ET l'écriture (ex: Write-Back avec bit Dirty).
    *   **Avantage :** Permet à l'étage IF et MEM d'accéder à leurs caches respectifs *en parallèle* dans le même cycle d'horloge (si les caches sont implémentés sur des BRAM séparées), augmentant la bande passante. Réduit les conflits structurels.
2.  **Logique de Cache :** Similaire au Sprint 8, mais dupliquée et adaptée pour I$ et D$. Implémentation des BRAMs pour Tags, Data, Valid (pour I$), Valid+Dirty (pour D$). Logique Hit/Miss, LRU, Write-Back (pour D$).
3.  **MMU Ternaire (`MMU_T`) :**
    *   **Translation :** Le module MMU prend une adresse virtuelle (du PC pour IF, de l'ALU pour MEM) et le mode courant (S/U), lit `satp_t`, effectue le Page Table Walk (en lisant les `PTE_T` depuis la mémoire physique *via le D-Cache/contrôleur DDR*), et retourne l'adresse physique ou une cause de faute de page.
    *   **TLB (Translation Lookaside Buffer) :** Un petit cache (associatif) *essentiel* pour stocker les traductions récentes (Virtuel -> Physique + Permissions). Implémenté en BRAM ou registres rapides. La MMU consulte le TLB avant de faire un Page Table Walk (qui est lent car nécessite plusieurs accès mémoire).
    *   **Gestion Fautes de Page :** Si la translation échoue (page non valide, violation de permission), la MMU signale un trap à l'unité de contrôle avec la cause appropriée.
4.  **Intégration Pipeline-Cache-MMU :** C'est la partie la plus complexe.
    *   **IF Stage :** PC (Virtuel) -> MMU(TLB/Walk via D$) -> Addr Physique -> I-Cache -> Instruction.
    *   **MEM Stage :** Addr Effective (Virtuelle, calculée en EX) -> MMU(TLB/Walk via D$) -> Addr Physique -> D-Cache -> Load Data / Store Data.
    *   **Stalls :** Le pipeline doit attendre (`stall`) en cas de :
        *   I-Cache Miss.
        *   D-Cache Miss.
        *   TLB Miss (pendant le Page Table Walk).
        *   Aléa Load-Use (si la donnée n'est pas encore prête depuis le D-Cache/MEM).
    *   **SFENCE.VMA :** Doit invalider tout ou partie du TLB simulé.

**Visualisation de la Nouvelle Architecture Mémoire :**

```mermaid
graph TD
    subgraph CPU_Pipeline [CPU Core Pipelined (5 Stages)]
        IF_Stage -- VA_Instr --> MMU_I(MMU/TLB Interface - IF);
        MEM_Stage -- VA_Data, Data_WR, R/W --> MMU_D(MMU/TLB Interface - MEM);

        MMU_I -- PA_Instr / Stall --> I_CACHE(I-Cache L1);
        MMU_D -- PA_Data / Stall --> D_CACHE(D-Cache L1);

        I_CACHE -- Instruction / Stall --> IF_Stage;
        D_CACHE -- Data_RD / Stall --> MEM_Stage;

        MMU_I -- Page Fault --> CU(Control Unit);
        MMU_D -- Page Fault --> CU;
    end

    subgraph MMU_TLB [MMU_T + TLB Simple]
        MMU_Logic{MMU Logic<br/>(Page Table Walker Ternaire)};
        TLB_Cache[(TLB Cache)];
        MMU_Logic <--> TLB_Cache;
        MMU_Logic -- Mem Access for Walk --> D_CACHE; %% !! Walk passe par D-Cache !!
    end

    I_CACHE -- Mem Req (Miss) --> MEM_HIERARCHY;
    D_CACHE -- Mem Req (Miss/WB) --> MEM_HIERARCHY;

    subgraph MEM_HIERARCHY [Hiérarchie Mémoire Externe]
        MEM_CTRL(Contrôleur DDR3L/SDRAM) --> DDR_SDRAM[(RAM Externe)];
    end

    CPU_Pipeline --> MMU_TLB; %% Connections logiques via interfaces

    style CPU_Pipeline fill:#eef,stroke:#333
    style I_CACHE fill:#ccf,stroke:#333
    style D_CACHE fill:#cfc,stroke:#333
    style MMU_TLB fill:#fdf,stroke:#333
    style MEM_HIERARCHY fill:#eee,stroke:#333

```

**Deliverables:**
*   **Code VHDL Mis à Jour/Nouveaux :**
    *   `rtl/cache/l1_icache.vhd` (Nouveau) : Module I-Cache (Tags, Data, Valid, Contrôleur).
    *   `rtl/cache/l1_dcache.vhd` (Nouveau) : Module D-Cache (Tags, Data, Valid, Dirty, Contrôleur, Write-Back).
    *   `rtl/mmu/mmu_t.vhd` (Nouveau) : Module MMU avec logique de translation, TLB simple, gestion des fautes.
    *   Mise à jour `rtl/core/` (Pipeline, Control Unit, Datapath) : Intégration des interfaces Cache/MMU, gestion des stalls étendus, gestion des traps de faute de page.
    *   Mise à jour `rtl/pkg/prismchrono_types_pkg.vhd` : Ajouter causes de trap Page Fault.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_l1_cache_separate.vhd` : Testbenches pour valider I-Cache et D-Cache isolément (ou ensemble si interface commune vers mémoire).
    *   `sim/testbenches/tb_mmu_t.vhd` : Testbench pour valider la MMU isolément (simuler TLB hits/misses, page table walk, fautes de permission).
    *   `sim/testbenches/tb_prismchrono_core_cached_mmu.vhd` (Nouveau/Final pour ce sprint) : Testbench système complet (CPU Pipeliné + Caches + MMU + Modèle DDR). Exécuter un code qui :
        *   Tourne avec adresses virtuelles.
        *   Active la MMU via `satp_t`.
        *   Génère des accès qui provoquent des cache hits et misses (I$ & D$).
        *   Génère une faute de page (ex: accès adresse non mappée) et la gère dans un handler de trap simple (ex: affiche message via UART MMIO, puis HALT).
*   **Simulation & Synthèse :**
    *   Scripts de simulation mis à jour. VCD pour les nouveaux testbenches.
    *   **Rapport de Synthèse et Timing :** Analyse post-synthèse/implémentation pour évaluer l'utilisation des ressources (LUTs, BRAM pour caches/TLB) et la fréquence maximale atteignable (FMax) avec cette complexité accrue.
*   **Documentation :**
    *   `doc/cache_design.md` : Description des caches L1 I/D (taille, asso, politique).
    *   Mise à jour `doc/prismchrono_mmu_t_v1.0.md`.
    *   Mise à jour `doc/pipeline_design.md` (interactions avec cache/MMU).

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL (caches, MMU, core modifié) compilent.
*   Les testbenches isolés pour les caches et la MMU passent.
*   Le testbench système complet `tb_prismchrono_core_cached_mmu` s'exécute **sans erreur d'assertion** et démontre :
    *   Le CPU exécute des instructions depuis l'I-Cache et des données depuis le D-Cache (vérifiable via signaux internes ou comportement).
    *   La MMU traduit correctement les adresses virtuelles en physiques pour les accès aux caches/mémoire.
    *   Le TLB (si implémenté) réduit les page table walks pour des accès répétés à la même page.
    *   Une **faute de page** (ex: accès non mappé ou violation de permission) déclenche un trap avec la bonne cause (`Load/Store/InstructionPageFault`) et saute au handler approprié.
    *   L'instruction `SFENCE.VMA` invalide les entrées TLB (vérifiable si TLB est observable).
*   Le design complet est **synthétisé et implémenté sur le FPGA cible (OrangeCrab 85F)** avec succès, même si la FMax est plus basse qu'au sprint précédent. Un rapport de ressources/timing est généré.
*   (Bonus) Un test matériel simple montre l'exécution d'un code utilisant la MMU (difficile à prouver sans OS/debug avancé).
*   La documentation pour les caches et la MMU est créée/mise à jour.

**Tasks:**

*   **[11.1] Conception Caches L1 I/D:** Choisir taille, associativité (Direct-Mapped est plus simple), taille de ligne, politique (LRU ou FIFO, Write-Back pour D$). Documenter.
*   **[11.2] Implémentation `l1_icache.vhd`:** Logique I-Cache (Tag, Data, Valid, Hit/Miss). Interface vers CPU (IF) et vers Mémoire Externe.
*   **[11.3] Implémentation `l1_dcache.vhd`:** Logique D-Cache (Tag, Data, Valid, Dirty, Hit/Miss, LRU?, Write-Back). Interface vers CPU (MEM) et vers Mémoire Externe. Gestion des écritures (byte/tryte enable si nécessaire).
*   **[11.4] Testbenches Caches Isolés:** Écrire et valider `tb_l1_cache_separate.vhd`.
*   **[11.5] Conception Finale MMU_T & TLB:** Finaliser format `PTE_T`, Page Walk ternaire. Concevoir la structure du TLB (taille, associativité).
*   **[11.6] Implémentation `mmu_t.vhd`:** Écrire le module MMU avec TLB et Page Table Walker (qui doit accéder au D-Cache pour lire les PTEs !). Génération des fautes.
*   **[11.7] Testbench MMU Isolé:** Écrire et valider `tb_mmu_t.vhd`.
*   **[11.8] Intégration Pipeline <-> Cache <-> MMU:**
    *   Modifier l'étage IF pour envoyer VA au MMU, recevoir PA/Stall/Fault, envoyer PA à I-Cache, recevoir Instruction/Stall.
    *   Modifier l'étage MEM pour envoyer VA au MMU, recevoir PA/Stall/Fault, envoyer PA/Data/RW à D-Cache, recevoir Data lue/Stall.
    *   Modifier la Control Unit pour gérer les nouveaux stalls et les traps Page Fault.
*   **[11.9] Implémentation `SFENCE.VMA_T`:** Ajouter l'instruction et la logique pour vider/invalider le TLB simulé.
*   **[11.10] Testbench Système Complet (`tb_prismchrono_core_cached_mmu.vhd`):**
    *   Créer ROM/DDR simulée avec "Noyau" (setup MMU, handler page fault) et "App" (code U-mode générant accès valides et fautes).
    *   Vérifier le bon déroulement, la gestion des fautes, l'état final.
*   **[11.11] Synthèse, Implémentation & Analyse Timing:** Lancer la chaîne FPGA complète. Analyser les résultats (ressources utilisées, FMax). Itérer si des problèmes majeurs de timing apparaissent.
*   **[11.12] Documentation:** Finaliser/Mettre à jour toute la documentation de conception.

**Risks & Mitigation:**
*   **(Risque MAJEUR) Complexité d'Intégration Pipeline-Cache-MMU:** Les interactions sont nombreuses et subtiles (stalls multiples, gestion des fautes pendant un miss cache, page walk via D-Cache...). -> **Mitigation :** Conception très modulaire. Simulation intensive étape par étape. Débogage VCD extrêmement détaillé. Commencer avec les caches/MMU les plus simples possibles.
*   **(Risque Élevé) Timing / FMax :** L'ajout du cache et surtout de la MMU (Page Table Walk) peut créer des chemins critiques longs et réduire la fréquence maximale. -> **Mitigation :** Utiliser les BRAM de manière efficace. Optimiser la logique critique (comparaison tags, TLB lookup). Accepter une FMax plus basse initialement. Reporter les optimisations de timing poussées.
*   **(Risque Élevé) Utilisation Ressources FPGA :** Caches + MMU + Contrôleur DDR + CPU consomment beaucoup de LUTs et surtout de BRAM. -> **Mitigation :** Choisir des tailles de cache/TLB raisonnables pour commencer. Surveiller les rapports d'utilisation après synthèse.

**Notes:**
*   Ce sprint apporte les **deux améliorations matérielles les plus significatives** pour la performance et les capacités système après le pipeline initial.
*   Avoir une MMU fonctionnelle, même simple, ouvre la voie à des OS ternaires beaucoup plus sophistiqués.
*   La complexité du débogage HDL atteint ici un niveau très élevé.

**AIDEX Integration Potential:**
*   Aide à la conception de la logique de cache VHDL (LRU, Write-Back).
*   Assistance pour la conception et l'implémentation VHDL de la MMU ternaire (Page Table Walk, TLB).
*   Suggestions pour l'intégration complexe Pipeline-Cache-MMU et la gestion des stalls/fautes.
*   Génération de code pour les testbenches systèmes complexes testant cache et MMU.
*   Aide à l'interprétation des rapports de synthèse et de timing des outils FPGA.
*   Analyse assistée des traces VCD pour déboguer les interactions subtiles entre les composants.
