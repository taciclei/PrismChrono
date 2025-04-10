# Sprint 18 VHDL (PrismChrono): Stabilisation, Contrôleur d'Interruptions (PLIC Simulé) & Débogage Amélioré

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Consolider et améliorer l'implémentation VHDL de PrismChrono en vue de l'exécution de logiciels plus complexes (noyau d'OS minimaliste). Ce sprint se focalise sur :
1.  La **stabilisation et l'optimisation finale** du design post-Sprint 17, en corrigeant les bugs résiduels et en tentant d'améliorer la fréquence maximale (FMax) ou de réduire l'utilisation des ressources.
2.  L'implémentation d'un **contrôleur d'interruptions externe programmable simplifié** (analogue à un PLIC - Platform-Level Interrupt Controller très basique) pour permettre une gestion plus fine des interruptions matérielles par le logiciel.
3.  L'**amélioration du module de débogage matériel** (si introduit au S14) pour offrir plus de capacités (ex: points d'arrêt sur adresse, accès mémoire plus facile via le débogueur).

**State:** Not Started

**Priority:** Élevée (Améliore la robustesse, la performance potentielle, et la capacité à supporter un OS et son débogage)

**Estimated Effort:** Large (ex: 15-25 points, T-shirt L/XL - Optimisation timing est itérative, PLIC même simple est non trivial, module debug avancé est complexe)

**Dependencies:**
*   **Sprint 17 VHDL Terminé :** Cœur CPU VHDL avec pipeline, cache, MMU, DDR, interruptions de base, atomiques, et instructions spécialisées fonctionnels (même si potentiellement lents ou gourmands).
*   **Sprint 14 VHDL (Debug Module Initial) :** Si un module de debug a été introduit, ce sprint l'améliore. Sinon, il implémente une version plus complète que celle envisagée initialement.
*   **Outils FPGA & Analyse Timing :** Capacité à analyser finement les rapports de timing et de ressources.

**Core Concepts:**
1.  **Optimisation Post-Implémentation :**
    *   **Analyse Finale :** Revoir les rapports de timing et d'utilisation des ressources du design complet. Identifier les derniers goulots d'étranglement.
    *   **Micro-Optimisations VHDL :** Appliquer des techniques ciblées (pipelining fin de chemins longs, réécriture de logique critique, utilisation optimisée des primitives FPGA comme les DSPs ou BRAMs) pour gagner quelques MHz ou réduire les LUTs/FFs. *Attention à ne pas introduire de nouveaux bugs fonctionnels.*
    *   **Nettoyage & Refactoring :** Améliorer la lisibilité, supprimer le code mort, factoriser la logique redondante.
2.  **Contrôleur d'Interruptions Type PLIC Simplifié (`plic_simple.vhd`) :**
    *   **Objectif :** Permettre à plusieurs sources externes (GPIOs, potentiellement timers ou autres périphériques internes au FPGA) de générer des interruptions, de définir leur priorité (très simple), de les masquer individuellement, et de signaler l'interruption la plus prioritaire au(x) cœur(s) CPU. Permettre au handler CPU d'acquitter l'interruption.
    *   **Interface MMIO/CSR :** Exposer des registres pour :
        *   `Interrupt Enable (par source)`
        *   `Interrupt Pending (par source)`
        *   `Interrupt Priority (par source - optionnel, très simple)`
        *   `Interrupt Claim/Acknowledge` (Le CPU lit ce registre pour savoir quelle interruption traiter et l'acquitter).
    *   **Logique Interne :** Logique combinatoire/séquentielle pour enregistrer les requêtes d'interruption, appliquer les masques et priorités, et générer le signal d'interruption final (`MEIP`/`SEIP`) vers le(s) cœur(s).
3.  **Module de Débogage Matériel Amélioré (`debug_module.vhd`) :**
    *   **Points d'Arrêt sur Adresse :** Ajouter des registres (accessibles via le débogueur externe) pour stocker une ou plusieurs adresses de points d'arrêt. Le module surveille le PC du CPU et déclenche un trap `DebugRequest` si le PC correspond à une adresse de breakpoint active.
    *   **Accès Mémoire Facilité :** Améliorer l'interface RSP (ou autre protocole de debug) pour permettre au débogueur externe de lire/écrire plus facilement dans la mémoire *physique* (ou *virtuelle* si la MMU peut être contournée/utilisée par le module de debug) pendant que le CPU est arrêté. Peut nécessiter un accès direct au bus mémoire via l'arbitre.
    *   **(Optionnel) Watchpoints :** Points d'arrêt sur accès (lecture/écriture) à une adresse mémoire spécifique. Très complexe à implémenter efficacement.
    *   **(Optionnel) Compteurs de Performance Simples :** Ajouter quelques compteurs matériels basiques (cycles, instructions retirées, cache misses - si les signaux sont disponibles) lisibles via le module de debug.

**Visualisation des Nouveaux Blocs :**

```mermaid
graph TD
    subgraph System_Top [prismchrono_top.vhd - Améliorations]
        %% Coeurs CPU (potentiellement optimisés)
        Core_0(PrismChrono Core 0)
        Core_1(PrismChrono Core 1)
        %% ...

        %% Nouveau Contrôleur d'Interruptions
        subgraph PLIC_Simple [plic_simple.vhd]
            PLIC_Regs[(Enable, Pending, Prio?, Claim Regs)];
            PLIC_Logic{Interrupt Prioritization & Masking Logic};
            PLIC_Regs <--> PLIC_Logic;
        end
        External_Pins(FPGA GPIOs) --> PLIC_Logic;
        Internal_Periph(Timers, UART?) -- Interrupt Req? --> PLIC_Logic;
        PLIC_Logic -- MEIP/SEIP --> Core_0;
        PLIC_Logic -- MEIP/SEIP --> Core_1;
        CPU_Access_Bus -- MMIO Access --> PLIC_Regs; %% CPU configure/claim

        %% Module Debug Amélioré
        subgraph Debug_Module [debug_module.vhd - Amélioré]
            Debug_Regs[(Breakpoint Addr, Control, Status Regs)];
            Debug_Logic{Debug Control Logic & RSP Handler};
            Debug_Regs <--> Debug_Logic;
            Debug_Logic -- Halt/Resume/Step --> Core_0; %% Contrôle CPU 0
            Debug_Logic -- Halt/Resume/Step --> Core_1; %% Contrôle CPU 1
            Core_0 -- PC, Status --> Debug_Logic; %% Surveillance
            Core_1 -- PC, Status --> Debug_Logic;
            Debug_Logic -- Direct Mem Access? --> MEM_BUS_ARBITER(Memory Bus Arbiter); %% Accès mémoire en mode debug
            Debug_Logic -- RSP via UART/JTAG --> HOST_PC(Debugger Host);
        end

        %% Reste du système
        Core_0 -- Mem Access --> MEM_BUS_ARBITER;
        Core_1 -- Mem Access --> MEM_BUS_ARBITER;
        MEM_BUS_ARBITER --> L1_Caches / MEM_CTRL;

    end

    style PLIC_Simple fill:#fec,stroke:#333
    style Debug_Module fill:#ffc,stroke:#333
```

**Deliverables:**
*   **Code VHDL Optimisé et Étendu :**
    *   Code VHDL du cœur CPU, cache, MMU, etc., avec micro-optimisations de timing/ressources appliquées.
    *   `rtl/intc/plic_simple.vhd` (Nouveau) : Contrôleur d'interruptions programmable.
    *   `rtl/debug/debug_module.vhd` (MàJ/Nouveau) : Module de débogage avec breakpoints adresse et accès mémoire amélioré.
    *   Mise à jour des autres modules (Core, Top-Level) pour intégrer le PLIC et le DM amélioré.
    *   Mise à jour `rtl/pkg/` : Adresses MMIO pour PLIC, nouvelles causes de trap debug.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** (Peu probable, sauf si de nouvelles pseudo-instructions de debug sont ajoutées).
*   **Fichier de Contraintes :** Mappage des pins GPIO utilisées pour les interruptions externes.
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_plic_simple.vhd` : Valide la logique du PLIC (priorité, masquage, claim/ack via interface MMIO).
    *   `sim/testbenches/tb_debug_module_advanced.vhd` : Valide les nouvelles fonctionnalités du DM (breakpoints, accès mémoire via RSP simulé).
    *   Mise à jour `tb_interrupts.vhd` / `tb_prismchrono_core_full_system.vhd` : Tester le déclenchement et la gestion des interruptions via le PLIC. Tester l'arrêt sur breakpoint via le DM.
*   **Simulation & Synthèse :**
    *   Validation en simulation des nouvelles fonctionnalités.
    *   **Rapport de Synthèse/Timing FINAL :** État final des ressources utilisées et de la FMax après optimisations.
*   **Documentation :**
    *   `doc/interrupt_system.md` : Description du PLIC simulé et de son utilisation.
    *   `doc/debug_interface.md` (MàJ) : Description complète du module de debug et du protocole RSP supporté.
    *   Rapport sur les optimisations effectuées et la performance finale.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent. Tous les testbenches (y compris les nouveaux/mis à jour) passent sans erreur d'assertion.
*   Les **optimisations** appliquées sont validées (pas de régression fonctionnelle) et leur impact sur la FMax/ressources est mesuré et documenté.
*   Le **contrôleur PLIC simulé** fonctionne :
    *   Les interruptions externes (via GPIO simulé) et internes (timer) peuvent être activées/désactivées individuellement via MMIO/CSR.
    *   Le PLIC signale correctement une interruption au(x) CPU(s) en fonction des priorités/masques.
    *   Le CPU peut lire le registre "Claim" pour identifier et acquitter l'interruption via MMIO/CSR.
*   Le **module de débogage amélioré** fonctionne :
    *   Un débogueur externe (simulé via le testbench ou via un script RSP sur UART) peut arrêter le CPU sur une adresse de **breakpoint** définie.
    *   Le débogueur externe peut lire et écrire dans les **GPRs et CSRs** du CPU arrêté.
    *   Le débogueur externe peut lire et écrire dans la **mémoire physique** via le DM pendant que le CPU est arrêté.
*   Le design complet final est **synthétisé et implémenté avec succès** sur le FPGA cible, respectant les contraintes de timing pour la FMax finale visée (ou la meilleure atteignable).
*   La documentation pour les interruptions et le débogage est complète.

**Tasks:**

*   **[18.1] Optimisation Timing/Ressources:** Analyser les rapports du Sprint précédent. Identifier les chemins/modules critiques. Appliquer des techniques d'optimisation VHDL (retiming, réécriture logique, etc.). **Itérer avec la synthèse/implémentation** pour mesurer l'impact.
*   **[18.2] Conception PLIC Simplifié:** Définir le nombre de sources d'interruption externes, le schéma de priorité (si existant), le format des registres MMIO/CSR (Enable, Pending, Claim).
*   **[18.3] Implémentation `plic_simple.vhd`:** Écrire le module VHDL pour le PLIC.
*   **[18.4] Intégration PLIC:** Connecter les sources d'interruption (GPIOs, Timer...) au PLIC. Connecter la sortie d'interruption du PLIC à l'entrée d'interruption externe du (des) CPU core(s). Intégrer l'accès MMIO/CSR au PLIC dans le bus système.
*   **[18.5] Testbench `tb_plic_simple.vhd`:** Valider le PLIC isolément.
*   **[18.6] Conception Debug Module Amélioré:** Définir les registres pour les breakpoints. Concevoir la logique de surveillance du PC. Définir comment le DM accède à la mémoire (via le bus principal? port séparé?). Étendre le support du protocole RSP (commandes `m`/`M`).
*   **[18.7] Implémentation `debug_module.vhd` (MàJ):** Ajouter la logique de breakpoint et l'accès mémoire amélioré. Affiner le handler RSP.
*   **[18.8] Intégration Debug Module:** Connecter le PC du (des) CPU(s) au DM. Donner au DM un accès au bus mémoire (via l'arbitre). Connecter l'interface de communication externe (UART).
*   **[18.9] Testbench `tb_debug_module_advanced.vhd`:** Valider les breakpoints et l'accès mémoire via RSP simulé.
*   **[18.10] Mise à Jour Testbenches Système:** Intégrer les tests pour le PLIC (déclencher une interruption externe via le testbench) et le Debug Module (arrêter sur breakpoint) dans le testbench complet.
*   **[18.11] Simulation & Débogage Final:** Exécuter tous les tests. Déboguer les dernières interactions complexes.
*   **[18.12] Synthèse Finale & Validation Timing:** Lancer la chaîne FPGA complète. **Valider que le design respecte le timing** pour la FMax cible (ou documenter la FMax finale atteinte). Générer le bitstream final pour cette version.
*   **[18.13] Documentation Finale:** Compléter toute la documentation de conception matérielle.

**Risks & Mitigation:**
*   **Risque :** Les optimisations de timing n'apportent pas le gain espéré ou introduisent des bugs. -> **Mitigation :** Optimisations prudentes et ciblées. Re-validation fonctionnelle systématique. Accepter une FMax finale réaliste.
*   **Risque :** La logique du PLIC ou du Debug Module est complexe à implémenter et à intégrer correctement (arbitrage bus, interactions CPU). -> **Mitigation :** Commencer par des versions très simples. Tests unitaires poussés. Débogage VCD.
*   **Risque :** Le design final dépasse les ressources de l'ECP5-85F ou ne respecte pas le timing même après optimisation. -> **Mitigation :** Identifier les modules les plus gourmands. Envisager de désactiver/simplifier certaines fonctionnalités (ex: complexité du cache, nombre d'unités spécialisées ternaires) pour cette version matérielle cible. Documenter les limitations.

**Notes:**
*   Ce sprint vise à produire une version VHDL **stable, optimisée et plus complète** du système PrismChrono, prête pour le développement logiciel sérieux.
*   L'accent sur le **débogage matériel** est crucial pour faciliter l'écriture et le test du futur OS ternaire.
*   La **performance (FMax)** atteinte à la fin de ce sprint est un indicateur important de la viabilité pratique de l'implémentation VHDL.

**AIDEX Integration Potential:**
*   Analyse assistée des rapports de timing et suggestions d'optimisation VHDL.
*   Aide à la conception et à l'implémentation VHDL du PLIC simplifié et du Debug Module amélioré.
*   Génération de code pour l'interface RSP minimale.
*   Assistance pour la création de testbenches complexes validant les interruptions via PLIC et les fonctionnalités de debug avancées.
*   Débogage collaboratif des problèmes de timing ou des bugs fonctionnels découverts lors de l'optimisation ou de l'ajout des modules système.