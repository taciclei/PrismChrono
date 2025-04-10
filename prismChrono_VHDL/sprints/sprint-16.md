Okay, après avoir enrichi l'ISA avec des instructions ternaires spécialisées (Sprint 15), le **Sprint 16 VHDL** peut se concentrer sur l'intégration de **fonctionnalités système plus avancées** qui rapprochent PrismChrono d'une plateforme capable de supporter un OS plus complet. Deux axes principaux :

1.  **Support Multi-Cœur Amélioré :** Passer d'une simulation séquentielle simple à un modèle (toujours simulé en VHDL) qui gère la **cohérence de cache simplifiée** (si caches L1 présents) et/ou des **interruptions inter-processeurs (IPIs)**.
2.  **Gestion Fine des Exceptions/Interruptions :** Implémenter complètement la **délégation de trap** (si non finalisée au S13/S14), et potentiellement ajouter le support pour les **interruptions logicielles** (liées au CLINT dans RISC-V).

*(Note : Ce sprint est très avancé et la complexité augmente encore. Il faudra peut-être choisir l'un des deux axes ou simplifier drastiquement l'implémentation.)*

---

```markdown
# Sprint 16 VHDL (PrismChrono): Cohérence Cache Simplifiée, IPIs & Finalisation Traps

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Renforcer les capacités système et multi-cœur du design VHDL `prismchrono_core` en implémentant :
1.  Un mécanisme **minimaliste de cohérence de cache** (ex: protocole basé sur invalidation simple type MSI - Modified, Shared, Invalid) pour permettre aux caches L1 des différents cœurs simulés de maintenir une vue (relativement) cohérente de la mémoire partagée DDR/SDRAM.
2.  Un système d'**Interruptions Inter-Processeurs (IPIs)** permettant à un cœur simulé d'envoyer une interruption logicielle à un autre cœur (utile pour la synchronisation OS, invalidation TLB distante - "shootdown").
3.  La **finalisation de la gestion des traps**, incluant la **délégation complète** des exceptions et interruptions entre les modes M, S, et U via les CSRs `m/sideleg`.

**State:** Not Started

**Priority:** Élevée (Nécessaire pour une exécution multi-cœur correcte avec caches et pour une gestion fine des privilèges/interruptions par l'OS)

**Estimated Effort:** Très Large (ex: 25-40 points, T-shirt XL/XXL - Cohérence de cache et IPIs sont des sujets très complexes en HDL, même simplifiés)

**Dependencies:**
*   **Sprint 15 VHDL Terminé :** Cœur CPU VHDL stable avec pipeline, caches L1 séparés, MMU, accès DDR, atomiques de base (LR/SC), privilèges M/S/U, gestion traps synchrones et interruptions asynchrones de base (timer/externe).
*   **Sprint 14 VHDL (Multi-Cœur Initial) :** Le Top-Level VHDL instancie plusieurs cœurs partageant l'accès mémoire (via arbitre).
*   **Conception Cohérence Cache :** Définition d'un protocole **simple** (ex: MSI) adapté au contexte ternaire et à l'interface cache/bus existante.
*   **Conception IPIs & Interruptions Logicielles :** Définition du mécanisme (CSRs ou MMIO pour déclencher/acquitter IPIs/SW Interrupts), et des causes `mcause`/`scause` correspondantes.

**Core Concepts:**
1.  **Cohérence de Cache (MSI Simplifié) :**
    *   **États par Ligne de Cache :** Chaque ligne dans le D-Cache (et potentiellement I-Cache si écritures permises type self-modifying code - peu probable) a des bits d'état supplémentaires (ex: 1 trit ou 2 bits pour coder M/S/I).
    *   **Transactions sur le Bus :** Le contrôleur de cache doit écouter ("snoop") les transactions sur le bus mémoire (initiées par d'autres caches ou DMA).
    *   **Logique MSI :**
        *   **Read Miss :** Lit depuis la mémoire, passe en état **Shared (S)**.
        *   **Write Hit (sur ligne S ou M) :** Écrit dans le cache, passe/reste en état **Modified (M)**. Si était S, envoie potentiellement une "Invalidation" aux autres caches (via bus).
        *   **Write Miss :** Lit depuis la mémoire (avec intention d'écrire - "Read For Ownership"), écrit, passe en état **Modified (M)**. Envoie "Invalidation" aux autres.
        *   **Snoop Read Hit (par autre cache) sur ligne M :** Fournit la donnée au bus (Write-Back implicite ou explicite vers mémoire ?), passe en état **Shared (S)**.
        *   **Snoop Invalidate Hit (par autre cache) sur ligne S ou M :** Passe en état **Invalid (I)**.
    *   **Simplifications :** Pas de protocole MESI/MOESI complet au début. La gestion du Write-Back lors du Snoop Hit doit être claire. Nécessite un bus mémoire capable de diffuser les invalidations ou des requêtes de snoop.
2.  **Interruptions Inter-Processeurs (IPIs) & Logicielles :**
    *   **Mécanisme :** Typiquement, un registre mappé en mémoire (MMIO) ou un CSR spécial où un cœur peut écrire pour déclencher une interruption logicielle (`MSIP`/`SSIP`) sur un *autre* cœur spécifique ou sur tous les autres.
    *   **Contrôleur d'Interruptions :** La logique de détection d'interruption (Sprint 13) doit être étendue pour surveiller ces flags `MSIP`/`SSIP` (qui sont mis à jour par les écritures MMIO/CSR inter-cœurs).
    *   **Implémentation :** Ajouter les registres MMIO/CSRs nécessaires et la logique pour router les écritures d'un cœur vers les indicateurs d'interruption (`mip`/`sip`) des autres cœurs.
3.  **Finalisation Traps & Délégation :**
    *   **CSRs `mideleg`/`medeleg` :** Implémenter la lecture/écriture de ces CSRs (analogues ternaires).
    *   **Logique de Trap Modifiée :** Dans `handle_trap`, *avant* de sauvegarder l'état et de choisir le vecteur (M ou S), vérifier la cause du trap et les bits correspondants dans `mideleg` (pour interruptions) ou `medeleg` (pour exceptions synchrones). Si le bit est à 1 (ou P?), le trap est délégué au mode S (utiliser `stvec`, `sepc`, `scause`, `sstatus`). Sinon, il est géré en mode M (utiliser `mtvec`, etc.).

**Visualisation des Interactions :**

```mermaid
graph TD
    subgraph System_Top [prismchrono_top.vhd - Multi-Core]
        Core_0(PrismChrono Core 0) -- Cache Access --> Cache_IF0(Cache L1 I/D 0);
        Core_1(PrismChrono Core 1) -- Cache Access --> Cache_IF1(Cache L1 I/D 1);
        %% ... autres coeurs

        Cache_IF0 -- Bus Transactions / Snoop --> BUS(Bus Mémoire<br/>(avec Arbitre & Snoop Logic));
        Cache_IF1 -- Bus Transactions / Snoop --> BUS;

        BUS --> MEM_CTRL(Contrôleur DDR3L);
        MEM_CTRL --> DDR_SDRAM[(RAM Externe)];

        subgraph IPI_Logic [Logique IPI / SW Int]
            IPI_Regs[(CSRs / MMIO<br/>pour déclencher IPI/SW Int)];
            IPI_Logic{Routage IPI};
            IPI_Regs --> IPI_Logic;
        end

        Core_0 -- Write IPI Reg --> IPI_Regs;
        Core_1 -- Write IPI Reg --> IPI_Regs;

        IPI_Logic -- Set MSIP/SSIP --> INT_Ctrl_0(Int Ctrl Core 0);
        IPI_Logic -- Set MSIP/SSIP --> INT_Ctrl_1(Int Ctrl Core 1);

        Core_0 <--> INT_Ctrl_0; %% Lecture mip/sip, Contrôle mie/sie
        Core_1 <--> INT_Ctrl_1;
    end

    style BUS fill:#ffc,stroke:#333
    style Cache_IF0 fill:#ccf,stroke:#333
    style Cache_IF1 fill:#ccf,stroke:#333
    style IPI_Logic fill:#fec,stroke:#333
```

**Deliverables:**
*   **Code VHDL Mis à Jour/Nouveaux :**
    *   `rtl/cache/l1_cache.vhd` : Modifié pour inclure les bits d'état MSI et la logique de snoop/invalidation.
    *   `rtl/bus/memory_bus.vhd` (Nouveau?) : Module de bus gérant l'arbitrage (amélioré) et la diffusion des transactions pour le snooping.
    *   `rtl/intc/ipi_controller.vhd` (Nouveau?) : Logique pour gérer les IPIs/SW Interrupts via CSRs/MMIO.
    *   `rtl/core/trap.rs` / `rtl/core/control_unit.vhd` : Logique de délégation de trap finalisée basée sur `m/sideleg`. Gestion des nouvelles causes d'interruption (SW, IPI).
    *   `rtl/csr/csr_registers.vhd` : Ajout/Finalisation de `mideleg`, `medeleg`, CSRs timer/IPI.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** (Probablement pas de nouvelles instructions, mais potentiellement des directives pour configurer les tests multi-cœurs).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_cache_coherence.vhd` : Testbench spécifique simulant 2 caches et un bus pour valider le protocole MSI simplifié (transitions d'état, invalidations, write-backs sur snoop hit).
    *   `sim/testbenches/tb_ipi_sw_interrupts.vhd` : Testbench CPU complet où un cœur déclenche une interruption logicielle/IPI sur l'autre cœur, qui la gère via son handler de trap.
    *   `sim/testbenches/tb_trap_delegation.vhd` : Testbench CPU complet qui configure `mideleg`/`medeleg` et vérifie qu'une exception ou interruption U-mode est bien gérée en S-mode au lieu de M-mode.
    *   Mise à jour `tb_multicore_atomics.vhd` pour s'assurer que LR/SC fonctionne correctement *avec* le protocole de cohérence de cache.
*   **Simulation & Synthèse :**
    *   Résultats de simulation validant la cohérence de base, les IPIs, et la délégation.
    *   Rapport de Synthèse/Timing : Évaluer l'impact (probablement significatif) de la logique de cohérence et IPI sur les ressources et la FMax.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent. Les nouveaux testbenches passent sans erreur d'assertion.
*   **Cohérence Cache :** Le testbench `tb_cache_coherence` démontre que le protocole MSI simplifié maintient la cohérence pour des scénarios lecture/écriture simples entre 2 caches (ex: un cœur écrit, l'autre lit la nouvelle valeur après invalidation/write-back).
*   **IPIs / SW Interrupts :** Le testbench `tb_ipi_sw_interrupts` montre qu'un cœur peut déclencher une interruption logicielle (MSIP/SSIP) sur un autre, et que ce dernier la reçoit et la gère via son handler de trap.
*   **Délégation Trap :** Le testbench `tb_trap_delegation` montre qu'un trap (ex: ECALL U-mode) est correctement routé vers S-mode lorsque la délégation est activée dans `medeleg`, et vers M-mode sinon.
*   `LR.T`/`SC.T` fonctionnent toujours correctement dans l'environnement multi-cœur simulé avec cohérence de cache.
*   Le design complet est synthétisé et implémenté. L'utilisation des ressources et la FMax sont mesurées. (La FMax risque encore de baisser).

**Tasks:**

*   **[16.1] Conception Cohérence Cache MSI Ternaire:** Définir précisément les états (M/S/I ternaires?), les transitions, les messages sur le bus (Read, Read-For-Ownership, Invalidate, Write-Back-Data?). Documenter.
*   **[16.2] Modification Cache L1:** Ajouter les bits d'état MSI. Implémenter la logique de contrôleur de cache pour gérer les transitions MSI et le snooping sur le bus.
*   **[16.3] Conception/Implémentation Bus Mémoire Snoop:** Modifier/Créer `memory_bus.vhd` pour supporter l'arbitrage et la diffusion des transactions nécessaires au snooping et aux invalidations.
*   **[16.4] Testbench `tb_cache_coherence`:** Écrire et valider ce testbench crucial.
*   **[16.5] Conception IPIs & SW Interrupts:** Définir le mécanisme exact (CSRs? MMIO?). Définir les nouvelles causes `mcause`.
*   **[16.6] Implémentation Logique IPI/SW:** Créer `ipi_controller.vhd` (ou intégrer). Mettre à jour les CSRs et la logique de détection d'interruption dans la Control Unit / `trap.rs`.
*   **[16.7] Testbench `tb_ipi_sw_interrupts`:** Écrire et valider.
*   **[16.8] Finalisation Délégation Trap:** Implémenter la lecture de `mideleg`/`medeleg` dans `handle_trap` et router le trap vers M ou S en conséquence (ajuster les CSRs sauvegardés/restaurés et le vecteur utilisé).
*   **[16.9] Testbench `tb_trap_delegation`:** Écrire et valider.
*   **[16.10] Mise à Jour Testbench Multi-Cœur:** S'assurer que `tb_multicore_atomics` fonctionne avec la nouvelle logique de cache/bus.
*   **[16.11] Intégration Complète & Simulation Système:** Mettre à jour le top-level. Simuler le système complet avec tous les tests.
*   **[16.12] Synthèse & Analyse Timing/Ressources:** Lancer la chaîne FPGA. Analyser l'impact final sur FMax et utilisation LUTs/BRAM.
*   **[16.13] Documentation:** Mettre à jour tous les documents (Cache, Interruptions, Privilèges, Multi-Cœur).

**Risks & Mitigation:**
*   **(Risque MAJEUR) Complexité Cohérence Cache:** Implémenter un protocole de cohérence, même simple (MSI), est très difficile à faire correctement et sans deadlocks/races conditions. -> **Mitigation :** Commencer par MSI le plus simple possible. Valider exhaustivement avec `tb_cache_coherence`. Beaucoup de débogage VCD. Peut-être reporter si trop complexe.
*   **(Risque Élevé) Interactions Multiples:** Les interactions entre cache, cohérence, MMU, traps, interruptions, multi-cœur sont extrêmement complexes. -> **Mitigation :** Tests d'intégration très ciblés. Débogage systématique. Simplifier les mécanismes si nécessaire.
*   **(Risque Élevé) Timing & Ressources:** La logique de cohérence et les interconnexions multi-cœurs vont consommer beaucoup de ressources et probablement réduire encore la FMax. -> **Mitigation :** Optimisations VHDL ciblées. Accepter une FMax plus faible. Vérifier si on tient toujours sur l'ECP5-85F.

**Notes:**
*   Ce sprint amène le design VHDL à un niveau de complexité système très élevé, se rapprochant (conceptuellement) des bases nécessaires pour un OS multi-cœur symétrique (SMP) avec mémoire virtuelle.
*   La **cohérence de cache** est souvent LE défi majeur dans les designs multi-cœurs. Une version très simplifiée est visée ici.
*   Atteindre la fin de ce sprint avec un design fonctionnel (même à basse fréquence) serait une **réalisation VHDL majeure**.

**AIDEX Integration Potential:**
*   Aide à la conception du protocole de cohérence MSI ternaire simplifié et de la logique VHDL associée.
*   Assistance pour la conception et l'implémentation du mécanisme d'IPI/SW Interrupts.
*   Génération de code VHDL pour la logique de délégation de trap.
*   Aide à la création des testbenches complexes pour la cohérence, les IPIs, et la délégation.
*   Débogage assisté des simulations, en particulier pour les problèmes de cohérence ou de timing des interruptions/traps dans le contexte multi-cœur.
*   Analyse des rapports de synthèse pour identifier les goulots d'étranglement en ressources ou en timing liés aux nouvelles fonctionnalités.
