# Sprint 14 VHDL (PrismChrono): Implémentation MMU Ternaire & Support Multi-Cœur Initial

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Intégrer le support matériel simulé pour la **gestion de la mémoire virtuelle** via l'implémentation de l'**Unité de Gestion Mémoire (MMU) ternaire (`MMU_T`)** conçue précédemment. Parallèlement, mettre en place les fondations pour le **support multi-cœur** en permettant l'instanciation de plusieurs cœurs `prismchrono_core` partageant la mémoire externe et en validant la fonctionnalité des instructions atomiques (`LR.T`/`SC.T`) dans ce contexte simulé.

**State:** Not Started

**Priority:** Critique (MMU indispensable pour OS moderne, Multi-cœur ouvre la voie au parallélisme)

**Estimated EffortOkay:** Exceptionnellement Grand (ex: 25-40 points, T-shirt XL/XXL - MMU + Multi-cœur est une étape très complexe en, reprenons le fil avec le **Sprint 14 VHDL**. Après avoir HDL)

**Dependencies:**
*   **Sprint 13 VHDL Terminé :** Cœur CPU pipeliné avec Cache L1, accès DDR, interruptions asynchrones de potentiellement ajouté les interruptions, les atomiques et peut-être les instructions compress base (Timer/Externe simple), atomiques `LR.T`/`SCées au Sprint 13, le Sprint 14 devient un moment où l'on peut choisir de :

*   **Option A : Optimisation.T` fonctionnels. Système de privilèges M/S/U et gestion et Stabilisation Approfondies :** Se concentrer sur l'amélioration de la fréquence (FMax), la réduction de l'utilisation des ressources, la des traps/CSRs associés implémentés.
*   **Conception MMU_ correction de bugs subtils découverts lors des tests des sprints précédents, et lT (`docs/prismchrono_mmu_t_v1.0'amélioration des outils de débogage HDL/matériel.
*   **Option.md`) :** Spécification complète du format `satp_t`, `P B : Fonctionnalités Système Avancées :** Commencer à implémenter des mécanismesTE_T`, algorithme de Page Table Walk ternaire, fautes de page plus avancés nécessaires pour un OS complet, comme un **contrôleur DMA.
*   **Conception Multi-Cœur & Synchro (`docs/prismchrono_sync_v1.0.md`) :** Modèle de simulation multi-cœur (prob** ou un **support plus fin pour la gestion d'énergie**.
*   **Optionablement séquentiel au début), sémantique `LR.T`/`SC.T C : Instructions Spécialisées Ternaires (Suite) :** Implémenter un`.
*   **Contrôleur Mémoire Externe (Sprint 8) :** Fonction autre lot d'instructions spécifiques à PrismChrono pour en explorer davantage le potentiel.
nel et capable de servir plusieurs requêtes (même si séquentiellement).

**Core*   **Option D : Unité Flottante (F/D) - Dé Concepts:**
1.  **Implémentation MMU_T :**
    *   **Modulebut Exploratoire :** Commencer la *conception* du format flottant ternaire et l `mmu_t.vhd` :** Contient la logique principale.
    *   **TLB (Translation Lookaside Buffer) :** Impl'implémentation VHDL des opérations *les plus simples* (peut-être juste conversionémenter un petit TLB (ex: 8-16 entrées, full-associatif ou set-associatif simple) en BRAM ou registres rapides entier <-> flottant, ou addition très basique) pour évaluer la complexité. pour cacher les traductions récentes (VA -> PA + Permissions). Gérer les hits/misses TLB.
    *   **Page Table Walker (PTW

Compte tenu de la complexité déjà atteinte et de l'objectif à) :** Logique (probablement une FSM) qui, sur un long terme d'un OS "moderne", choisissons une **combinaison prag TLB miss, lit le `satp_t`, calcule les adresses desmatique : Option A (Stabilisation/Optimisation) + Début Option PTEs aux différents niveaux de la table de pages (en mémoire externe *via le B (DMA)**. Un contrôleur DMA est souvent très utile pour décharger le CPU des transferts de données volumineux (ex: réseau, disque simulé).

---

``` cache L1/DDR*), lit les PTEs, vérifie leur validité et les permissions, et enfin calcule l'adresse physique (PA) ou génmarkdown
# Sprint 14 VHDL (PrismChrono): OptimParère une faute de page. Doit interagir avec l'interface mémoire.isation Timing, Stabilisation & Introduction DMA

**Nom de Code Projet :** PrismChrono
**Compos
    *   **Gestion des Fautes :** Détecter les fautes (ant :** `prismChrono_VHDL`

**Objective:** StabilPage Not Valid, Protection Fault R/W/X, potentiellement Accessed/Dirtyfait, continuons la progression VHDL avec le **Sprint 14**.iser et optimiser l'implémentation VHDL existante du cœur ` bit handling) et générer le trap correspondant vers la Control Unit.
2prismchrono_core` (incluant pipeline, caches, MMU, interruptions Après avoir ajouté les fonctionnalités système essentielles (Interruptions, Atomics) et potentiellement début.  **Intégration MMU dans le Système :**
    *   **CPU, atomiques de base) en se concentrant sur l'**amélioration de la fréquence maximale (FMax)** et la **correction de bugs résiduels**. Paré le support du format compact au Sprint 13, ce sprint peut se concentrer sur des Core :** Les étages IF et MEM envoient désormais des **adresses virtuelles (VA)** à **optimisations de performance plus agressives** et/ou l'ajout de **fonctionnal la MMU.
    *   **MMU :** Retourne l'**allèlement, introduire une fonctionnalité système clé pour la performance des E/S : unités système plus avancées** qui étaient hors scope précédemment, tout en consolidant laadresse physique (PA)** correspondante (après lookup TLB ou Page Walk) aux **contrôleur d'accès direct à la mémoire (DMA) ternaire simplifié Caches L1 (I$ et D$).
    *   **Caches L**, permettant des transferts de données entre la mémoire (DDR/SDRAM) et un1 :** Doivent maintenant être indexés et taggés en utilisant l'**adresse physique ( robustesse du design.

Étant donné l'effort déjà conséquent, onPA)**. C'est une modification potentiellement importante de leur logique. ( "périphérique" (simulé pour l'instant) sans interventionOn parle de PIPT - Physically Indexed, Physically Tagged cache).
    *   **Control peut choisir un axe principal pour ce sprint : soit l'optimisation poussée, constante du CPU.

**State:** Not Started

**Priority:** Élevée (Stabilisation nécessaire, DMA utile pour futur OS/périphériques)

**Estimated soit l'ajout d'une fonctionnalité système majeure comme le **support du débogage matériel Effort:** Très Large (ex: 20-35 points, T-shirt XL - Optimisation de timing est itérative et complexe, conception/implémentation DMA est Unit :** Gère les stalls pendant la translation MMU (TLB miss, Page Walk) et les traps de faute de page.
    *   **CSR** ou une **meilleure gestion de la cohérence/multi-cœur**. Optons pour le **débogage matériel**, car c'est un ajout extrêmement utile pour le développement logiciel futur sur la plateforme.

---

```markdown
# Sprint 14 V non triviale)

**Dependencies:**
*   **Sprint 13 VHDL Terminé :** Cœur CPU VHDL relativement complet avec pipeline, caches, MMU, interruptionss :** Accès à `satp_t`.
    *   **`SFENCE.VMA` :** Implémenter l'instruction pour invalider le TLB.
3.  **Instanciation Multi-Cœur :**
HDL (PrismChrono): Module de Débogage Matériel Minimal & Optimisations Finales

**Nom de Code Projet :** PrismChrono
**Compos, atomiques. Le design synthétise et fonctionne en simulation, mais peut avoir des problèmes de timing ou des bugs subtils.
*   **Outils FPGA (Vivado/Yosys+Nextpnr) :** Cap    *   **Top-Level (`prismchrono_top.vhd`) :** Instancier **plusieurs** `prismchrono_core` (ex: `CORE_COUNT = 2` ou `4`).
    *   **Partant :** `prismChrono_VHDL`

**Objective:** Ajouter un **module de débogage matériel minimal** au design `prismchrono_coreacité à générer et analyser des rapports de timing détaillés.
*   **Interface Bus Interne :** Une forme de bus interne (AXI, Wishbone, ou custom) auquel le CPU, le contrôleur mémoire DDR, et le futur contrôleur DMA peuventage Mémoire :** Tous les cœurs accèdent à la **même interface de cache/mémoire externe**. Un arbitre simple peut être nécessaire si le cache/`, permettant à un débogueur externe (ex: GDB via un adaptateur JTAG/UART) d'interagir basiquement avec le CPU (arrêter/reprendre l'exécution, lire/écrire les registres et se connecter serait idéale (si non déjà en place, une simplification est nécessaire).

**Core Concepts:**
1.  **Optimisation de Timing (FMax) :**
    *   **Ancontrôleur mémoire ne peut gérer qu'une requête à la fois (probable).
    *   **Communication Inter-Cœur :** Pour ce sprint, la seule communication est implicite via la mémoire partagée et les atomiques. Pas la mémoire) lorsqu'il tourne sur le FPGA. Ce sprint inclut également unalyse :** Utiliser les rapports de timing statique (STA) des outils FPGA après implémentation (P&R) pour identifier les **chemins critiques d'IPI (Inter-Processor Interrupts) encore.
    *   **Simulation Séquentielle (Recommandé) :** Pour simplifier, le test cycle final d'**optimisation de performance (FMax)** et de **réduction des ressources** basé sur l'analyse des sprints précédents.

**State:** Not Started** (les plus lents) dans le design.
    *   **Techniques d'Optimisation HDL :**
        *   **Réécriture de Logbench exécute un cœur pendant N cycles, puis l'autre pendant N cycles, etc. (Round-Robin). Cela évite les vrais problèmes de concurrence

**Priority:** Élevée (Facilite grandement le développement logicielique :** Simplifier la logique combinatoire complexe sur les chemins critiques.
        *   **Pipelining Interne :** Ajouter des registres intermédiaires *à l'intérieur* d *dans le simulateur VHDL*, tout en permettant de tester la *logique* de futur, améliore la performance matérielle finale)

**Estimated Effort:** Très Large (ex: 20-35 points, T-shirt XL/XXL - Conception'un bloc combinatoire long (ex: dans l'ALU, le synchronisation (`LR.T`/`SC.T`).
4.  **Validation décodeur, ou le Page Table Walker de la MMU) pour le décou module debug est complexe, interface JTAG/autre, optimisation timing/ressources)

**Dependencies:**
*per en étapes plus courtes (augmente la latence mais améliore la FMax).
        * Atomics Multi-Cœur :** Vérifier que `LR.T`   **Sprint 13 VHDL Terminé :** Cœur CPU pip sur un cœur et `SC.T` sur le même cœur réussit si aucun   **Rééquilibrage du Pipeline Principal :** Déplacer des opérationseliné fonctionnel avec ISA de base complète, Interruptions, Atomics, Cache L autre cœur n'a écrit à l'adresse réservée entre temps, et éch1, MMU simple, accès DDR.
*   **Spécification de Débogage RISC entre les 5 étages principaux si cela réduit la charge d'un étage critique.
        *   **Optimoue sinon.

**Visualisation de l'Architecture Cible :**

```mermaid
graph-V (pour inspiration) :** Bien que non implémentée à isation des Multiplexeurs Larges :** Parfois source de délais importants.
    *   **It TD
    subgraph System_Top [prismchrono_top.vhd]
        subgraph Core_0 [PrismChrono Core 0]
            Pipeline0(100%, elle fournit un modèle conceptuel pour le module de débogage,ération :** Modifier le VHDL -> Synthèse/Implémentation -> AnalysePipeline 5 Stg) --> MMU_TLB0(MMU_ Timing -> Répéter.
2.  **Contrôleur DMA TernT + TLB 0);
            MMU_TLB0 --> Cache_ les registres associés (ex: `dcsr`, `dpc`), et les mécanismesaire Simplifié (`dma_controller_t`) :**
    *   **ObjectIF0(Cache I/D 0);
        end
        subgraph Coreif :** Transférer des blocs de données (`EncodedWord` ou `Encoded de contrôle.
*   **Interface Physique de Débogage :** Déc_1 [PrismChrono Core 1]
            Pipeline1(Pipeline 5 Stg) -->Tryte`) entre la mémoire principale (DDR/SDRAM) et uneider comment le débogueur externe communiquera avec le module de débogage V MMU_TLB1(MMU_T + TLB 1);
 interface "périphérique" (qui sera un simple port dans le testbench pour ce            MMU_TLB1 --> Cache_IF1(Cache I/D 1); sprint).
    *   **Interface de Programmation (via MMIO ouHDL (Option la plus simple : via l'**UART existant** avec un prot
        end
        %% ... Potentiellement Core 2, Core 3 ...

        subgraph Memory CSRs) :** Le CPU doit pouvoir configurer le DMA :
        *_Subsystem [Sous-Système Mémoire Partagé]
            Arocole série simple type GDB RSP ; Option plus standard mais plus complexe : via   Adresse source (mémoire ou périphérique).
        *   Adresse destination (biter(Memory Arbiter) --> MEM_CTRL(Contrôleur DDR3L/SDpériphérique ou mémoire).
        *   Taille du transfert (nombre de motsRAM);
            MEM_CTRL --> DDR_SDRAM[(RAM Externe)];/trytes ternaires).
        *   Signal de démarrage.
    *   **Logique DMA :** Une machine à états qui, une fois dém
            Cache_IF0 -- Mem Req/Resp --> Arbiter;
            Cache_IF1 **JTAG** nécessitant un IP Core TAP - Test Access Port). *arrée :
        *   Demande l'accès au bus mémoire (arbit -- Mem Req/Resp --> Arbiter;
        end

        %% CommunicationDécision pour ce sprint : Utiliser l'UART existant avec un protocole RSPrage simple si nécessaire).
        *   Effectue des lectures depuis la source minimaliste.*

**Core Concepts:**
1.  **Module de Débogage (DM (via l'interface cache/mémoire DDR).
        *   Effectue des écritures vers la destination.
        *   Incrémente les - Debug Module) VHDL :**
    *   Un module séparé qui peut adresses et décrémente le compteur.
        *   Signale la fin du interagir avec le cœur CPU (`prismchrono_core`).
    *   /Debug
        Core_0 -- UART0 TX/RX --> FPGA_IO;
        Core_1 -- UART1 TX/RX --> FPGA_IO; %% Chaque coeur a son UART? Ou**Contrôle du Cœur :** Capacité à demander au cœur de transfert (ex: via un bit de statut ou une interruption si le système d'interruption est prêt s'arrêter (`halt request`), de reprendre (`resume request`), ou d'exécuter une seule instruction).
    *   **Interface Périphérique Simulée :** Pour partagé?
        FPGA_IO --> HOST_PC(PC Hôte);
    end (`single step`).
    *   **Accès à l'État : ce sprint, le "périphérique" peut être une simple interface FIFO ou

    style Core_0 fill:#eef,stroke:#333
** Capacité à lire/écrire les GPRs (R0-R7), les CSR à registres dans le VHDL, connectée au DMA.
3.  **Arbit    style Core_1 fill:#eef,stroke:#333
rage de Bus (Simplifié) :** Si le CPU, le Cache/    style Memory_Subsystem fill:#dde,stroke:#333
```s (PC, mstatus, etc.), et la mémoire physique *pendant que le cœurMMU (pour Page Walk), et maintenant le DMA veulent tous accéder au contrôleur mémoire DDR

**Deliverables:**
*   **Code VHDL Mis à Jour/ en même temps, il faut un arbitre simple (ex: priorité fixe ou est arrêté*.
    *   **Communication Externe :** Interface série ( round-robin) pour gérer l'accès au bus mémoire externe.
4.  **Stabilisation &Nouveaux :**
    *   `rtl/mmu/mvia UART) pour recevoir les commandes du débogueur (ex: GDB via Correction Bugs :** Profiter des tests plus poussés pour identifier et corriger lesmu_t.vhd` : Module MMU ternaire avec TLB et Page Table bugs fonctionnels ou de timing qui subsistent des sprints précédents.

**Visualisation de `gdbserver` ou proxy) et envoyer les réponses, en utilisant un sous Walker.
    *   `rtl/mmu/tlb.vhd` (Optionnel) : l'Intégration DMA :**

```mermaid
graph TD
 Module TLB séparé.
    *   Mise à jour `rtl/cache    subgraph SystemOnChip_FPGA
        CPU_Core(prism/` : Adapter les caches L1 pour utiliser des adresses physiques (PI-ensemble du protocole GDB Remote Serial Protocol (RSP).
    *   **Points d'Arrêt (Breakpoints) :** Logique pourchrono_core<br/>(Pipeliné, Cache L1, MMU))PT). Ajouter interface vers arbitre mémoire.
    *   Mise à jour `rtl/core détecter l'exécution d'une instruction `EBREAK` ou (plus avancé/` : Intégrer appels MMU dans IF/MEM. Gérer stalls
        DMA_CTRL(dma_controller_t<br/>(N/fautes MMU. Finaliser `SFENCE.VMA_T`.
    *   Mise) pour correspondre le PC à une adresse de breakpoint définie via le débogueur. Déouveau));
        MEM_CTRL(Contrôleur DDR3L/SD à jour `rtl/csr/` : Implémenter `satp_t` et saclenche un trap de débogage.
2.  **Interface CPU logique d'écriture.
    *   `rtl/mem/memory_arbiter.vhd` (RAM);
        BUS_ARBITER(Arbitre de Bus Mémoire); <-> DM :** Le CPU doit pouvoir signaler des événements au DM (ex: ex
        PERIPH_IF(Interface Périphérique<br/>(SimNouveau) : Arbitre simple (ex: round-robin) pour lécution `EBREAK`, exception) via un trap spécifique (`DebugTrap`). Le DM doit pouvoir lire'accès au contrôleur DDR.
    *   Mise à jour `rtl/top/` : Instancier plusieurs cœurs, l'arbitre, le contrôleur DDRulée / Ex: UART, FIFO));

        CPU_Core -- Acc/écrire l'état interne du CPU (registres, CSRs viaès Cache/MMIO --> BUS_ARBITER; %% Accès norm.
*   **Assembleur (`prismchrono_asm`) :** Supportaux ou MMIO DMA
        DMA_CTRL -- Accès Mémoire --> BUS_ARBITER; `SFENCE.VMA_T` (si non déjà fait).
*   **Testb des ports dédiés ou un bus de debug) et contrôler son exécution ( %% Accès DMA
        MMU_Logic -- Accès Page Table --> BUS_ARBITER;enches VHDL :**
    *   `sim/testbenches/halt/resume/step).
3.  **Protocole GDB RSP %% Page Walk
        BUS_ARBITER -- Accès Granté --> MEM_CTRLtb_mmu_t.vhd` : Validation approfondie de la MMU ( (Minimal) :** Implémenter la logique dans le DM (ou un;
        MEM_CTRL --> DDR_SDRAM[(RAM Externe)];

        DMATLB hit/miss, walk, fautes).
    *   `sim_CTRL -- Transfert Données --> PERIPH_IF;
        CPU module associé) pour parser les commandes RSP de base reçues via UART (ex: `?/testbenches/tb_multicore_atomics.vhd` (Nouveau` (status), `g` (lire GPRs), `G` (éc/Final) : Testbench système instanciant **plusieurs cœurs**._Core -- Contrôle DMA via MMIO --> DMA_CTRL;
        PERIPH_IF <--rire GPRs), `m` (lire mémoire), `M` (éc Charge un programme différent ou identique dans chaque cœur (via MMU?). Teste un Données Externes (Simulées) --> DMA_CTRL;
    rire mémoire), `c` (continuer), `s` (step)) scénario de **mise à jour de compteur partagé avec spinlock `LR.T`/`SC.T`**. Simule aussi une **faute de page** et sa gestion par un et formater les réponses appropriées.
4.  **Optimisation Timingend

    style DMA_CTRL fill:#fec,stroke:#333,stroke (FMax) :**
    *   Utiliser les outils de synthèse handler.
*   **Simulation & Synthèse :**
    *   /placement-routage (Yosys/nextpnr ou Vivado) etRésultats de simulation validant la MMU et la synchronisation atomique inter-width:1px
    style BUS_ARBITER fill:#e les rapports de timing pour identifier les chemins critiques *restants* après les sprints-cœurs (simulés).
    *   Rapport de Synthèse/ef,stroke:#333,stroke-width:1px
```Timing : Évaluer l'impact très significatif de la MMU et du multi précédents.
    *   Appliquer des techniques d'optimisation VHDL plus

**Deliverables:**
*   **Code VHDL Optimisé/Ét-cœur sur les ressources et la FMax. **S'attendre à uneendu :**
    *   Modifications dans `rtl/core/`, avancées : retiming de registres, codage d'états F `rtl/cache/`, `rtl/mmu/` visant l'amélioration de baisse notable de FMax.**

**Acceptance Criteria (DoD - Definition of la FMax (pipelining interne, réécriture logique...).
    *   `rtl/dSM optimisé, duplication de logique mineure, ajustement des contraintes de timing Done):**
*   Tous les modules VHDL compilent. Les testbenches MMma/dma_controller_t.vhd` (Nouveau) : Module DMA simplifié.
5.  **Optimisation Ressources (LUTs/BRAM/FFsU et système multi-cœur passent.
*   **MMU Fonction.
    *   `rtl/bus/bus_arbiter.vhd` (Nouveau) :**
    *   Identifier les modules consommant le plus de ressources. ou intégré) : Arbitre de bus mémoire simple.
    *   M
    *   Explorer des implémentations alternatives plus compactes (ex: pournelle :**
    *   Le CPU exécute en utilisant des adresses virtuelles lorsqueise à jour du Top-Level pour intégrer DMA et arbitre.
     `satp_t` est activé.
    *   La translation certaines parties de l'ALU, du cache, ou du contrôleur mémoire via TLB et Page Table Walk fonctionne.
    *   Les fautes de page (*   Mise à jour `rtl/pkg/` : Adresses MMaccès invalide, protection R/W/X) déclenchent un trap avec la bonne) si la FMax le permet. Partager des ressources si possible.

**VisualIO pour DMA, potentiellement nouvelles causes de trap/interruptions liées au DMA.
*   **Assembleisation de l'Intégration du Debug Module :**

```mermaid
graph cause et la VA fautive (dans `mtval`/`stval`?ur (`prismchrono_asm`) Mis à Jour :** (Peut-être pas TD
    subgraph System_on_FPGA
        CPU_Core( CSR à définir/implémenter).
    *   `SFENCE.VMA` inval de nouvelles instructions, mais potentiellement des directives pour configurer les tests DMA).prismchrono_core<br/>Pipeline, Cache, MMU, etc.)
ide le TLB.
*   **Multi-Cœur Simulé &
*   **Testbenches VHDL :**
    *   ` Atomics :**
    *   Le testbench système exécute ausim/testbenches/tb_dma_controller.vhd` :        Mem_Ctrl(Contrôleur DDR/SDRAM)
        UART moins 2 cœurs (même séquentiellement).
    *   Le Testbench validant le contrôleur DMA isolément (transfert mémoire<->p_Ctrl(Contrôleur UART)
        Debug_Module(Debug test de spinlock utilisant `LR.T`/`SC.T` réussit :ériphérique simulé).
    *   `sim/testbenches/tb_prism Module VHDL<br/>(DM))

        CPU_Core -- Debug le compteur partagé est incrémenté correctement sans race condition.
*chrono_top_dma.vhd` (Nouveau/Extension) : Testbench système   Le design complet (multi-cœurs + MMU + Caches + DDR Access (Regs, Mem Req) --> Debug_Module;
        CPU_Core -- Trap complet où le CPU configure le DMA (via écritures MMIO) pour effectuer) est **synthétisé et implémenté**. La FMax est mes un transfert mémoire-vers-périphérique ou périphérique-vers-mémoire, puis Events (EBREAK, Exception) --> Debug_Module;
        Debug_Module -- Halt/Resume/urée (sera probablement basse). L'utilisation des ressources (LUTs, BRAM pourStep Control --> CPU_Core;
        Debug_Module -- Mem Access Req TLB/Caches) est rapportée.
*   `prismchrono_asm` supporte ` vérifie le résultat et/ou attend une interruption de fin de DMA (si interruptionsSFENCE.VMA_T`.

**Tasks:**

*   **[14 impl.). Tester l'arbitrage si CPU et DMA accèdent à la mémoire " --> Mem_Bus_Arbiter(Memory Bus Arbiter?);
        CPU.1] Implémentation TLB:** Concevoir et implémenter laen même temps".
*   **Simulation & Synthèse :**
    * structure et la logique du TLB (associativité, remplacement, gestion AS   Résultats de simulation validant le DMA et les optimisations de timing.
    *   **R_Core -- Mem Access Req --> Mem_Bus_Arbiter;
        Mem_Bus_ArbiterID si supportée).
*   **[14.2] Implémentationapport de Synthèse/Timing FINAL (pour ce sprint) :** Comparaison --> L1_CACHE / MEM_CTRL;

        Debug_Module -- UART TX Page Table Walker (PTW):** Écrire la FSM ou la FMax et utilisation ressources avant/après optimisation. Analyse des chemins critiques restants.
*/RX Data --> UART_Ctrl;
        UART_Ctrl -- Serial Pins logique qui lit `satp_t` et effectue les accès mémoire (via D-Cache/DDR) pour lire les PTEs ternaires et calculer --> FPGA_IO(FPGA Pins);

        %% Optional JTAG Path la PA ou une faute.
*   **[14.3] Int
        JTAG_TAP(JTAG TAP Controller<br/>(Optional IP   **Documentation :**
    *   `doc/dma_controller_design.égration MMU Complète:** Connecter TLB et PTW. Crémd` : Description du contrôleur DMA ternaire simplifié.
    *   Mer le module `mmu_t.vhd`. Intégrer dans Core)) -- Debug Bus --> Debug_Module;
        FPGA_IO --ise à jour des documents pipeline, mémoire, etc., avec les optimisations et IF/MEM stages du pipeline. Gérer les stalls pendant la translation. G JTAG Pins --> JTAG_TAP;
    end

    FPGA_IO --> l'intégration DMA.

**Acceptance Criteria (DoD - Definition oférer les fautes -> Trap.
*   **[14.4] Adaptation USB_UART_BRIDGE(Pont USB-Série);
    USB_UART_BRIDGE --> HOST Done):**
*   Tous les modules VHDL compilent. Les testbenches passent Caches L1 (PIPT):** Modifier la logique d'indexation sans erreur d'assertion.
*   Les optimisations de timing implémentées ** et de tag des caches I/D pour utiliser les adresses physiques (PA) fournies par la MMU_PC(PC Hôte);
    HOST_PC -- GDB Client.
*   **[14.5] Implémentation `améliorent la FMax rapportée par les outils FPGA** ou, au minimum --> GDB_Server(GDB Server / Proxy<br/>parlant RSPSFENCE.VMA_T`:** Ajouter l'instruction et la logique pour inval, le chemin critique est mieux compris et documenté.
*   Le contrôleur DMA (`ider le TLB.
*   **[14.6] Instdma_controller_t`) fonctionne correctement dans son testbench isolé.
*   Le test sur /dev/ttyUSBx);
    GDB_Server -- RSPanciation Multi-Cœur:** Modifier le top-level pour instancier ` Protocol --> USB_UART_BRIDGE;

    %% Alternative JTAG
    %%bench système `tb_prismchrono_top_dma` démontre queCORE_COUNT` cœurs.
*   **[14.7] Implémentation Arbitre Mémoire:** Créer un arbitre simple HOST_PC -- GDB Client --> OpenOCD(OpenOCD); :
    *   Le CPU peut configurer et démarrer un transfert DMA via (round-robin) pour partager l'accès au contrôleur DDR entre les requ
    %% OpenOCD -- JTAG Commands --> JTAG_Adapter(Adapt des accès MMIO.
    *   Le DMA effectue le transfert deêtes des caches des différents cœurs.
*   **[14.8] Finalisation/ateur JTAG);
    %% JTAG_Adapter --> FPGA_IO; données correct entre la mémoire DDR simulée et l'interface périphérique simulée.
    *   LeValidation Atomics:** Assurer que `LR.T`/`SC.T` fonctionnent à

    style Debug_Module fill:#fec,stroke:#333,stroke CPU peut être notifié de la fin du transfert (via polling d'un registre-width:2px
```

**Deliverables:**
*   **Code V travers le cache et l'arbitre, et que la logique d'invalidation de réservation est de statut DMA ou via une interruption si impl.).
    *   L'arbitrageHDL :**
    *   `rtl/debug/debug_module.vhd` (Nouveau) : Implémentation du DM avec logique de contrôle CPU, accès de bus gère les accès concurrents (CPU vs DMA) sans corruption ( correcte dans le modèle multi-cœur simulé.
*   **[1 état, et parser/formateur RSP minimal via UART.
    *   Mise à jour `rtl/core/prismchrono_core.vhd`4.9] Mise à Jour Assembleur:** Ajouter `SFENCE.VMA_T`.
*   test simple).
*   Le design complet est synthétisé et implémenté avec succès : Ajout de l'interface vers le DM (signaux halt/resume**[14.10] Testbenches Avancés:** É, respectant (idéalement) les contraintes de timing pour la F/step, accès registres/mémoire en mode debug, signalement trapcrire `tb_mmu_t.vhd` et `tbMax améliorée visée.
*   La documentation du DMA et des optimisations est réalisée debug).
    *   Mise à jour `rtl/core/trap.

**Tasks:**

*   **[14.1] Analyse Timing.rs` : Ajout de la cause `DebugRequest` ou `Breakpoint & Stratégie Optimisation:** Identifier les chemins critiques du design du Sprint 13_multicore_atomics.vhd`. Concevoir les scénarios de test assemble`.
    *   Mise à jour `rtl/uart/uart_controller.vhd` (si. Planifier des modifications VHDL ciblées (retiming, pipelining interneur (manuel).
*   **[14.11] Simulation & Débogage...).
*   **[14.2] Implémentation Optimisations nécessaire) pour être partagé entre CPU et DM, ou instanciation d'un second UART:** Exécuter, déboguer les interactions MMU/Cache/Pipeline dédié au debug.
    *   **(Optionnel)** Intégration d:** Appliquer les modifications VHDL. Itérer avec synthèse/STA pour vérifier l'impact et la logique atomique inter-cœurs.
*   **[14'un IP Core JTAG TAP si cette voie est choisie.
    *   .
*   **[14.3] Conception DMA Ternaire:**
    *   Dé.12] Synthèse, Implémentation & Analyse Timing/Ressources:** Lfinir l'interface MMIO/CSR (registres adresse source/dest, taille**Optimisations VHDL diverses** dans les modules critiques (ALU, Pipelineancer la chaîne FPGA. Analyser les résultats. **S'attendre à des, contrôle/statut).
    *   Concevoir la FSM du contrô difficultés de timing.**
*   **[14.13] Documentation:** Finalleur DMA (Idle, Read Mem, Write Periph, Read Periph, Write Mem, Done...).
    *   Définir l'interface vers le bus mémoire (via, Cache...) visant FMax et/ou réduction ressources.
*   **Assembleiser toute la documentation de conception système.

**Risks & Mitigation:**
*   **( arbitre) et vers le périphérique.
    *   Comment gérer les adresses/ur (`prismchrono_asm`) Mis à Jour :** Peu de changements,Risque MAJEUR) Complexité Totale:** MMU + Caches Ptailles ternaires ? Conversion interne en binaire ?
*   **[IPT + Multi-cœur + Atomics + DDR est un design **extrêmement complexe**.14.4] Implémentation `dma_controller_t.v sauf si de nouvelles instructions de debug sont ajoutées (peu probable).
*   **Logiciel -> **Mitigation :** **Simplifier agressivement** chaque composant (hd`:** Écrire le module DMA.
*   **[14 Hôte :** Un script Python simple (ou adaptation d'un proxy existant) agissant comme un **mini GDB Server** : se connecte au port série.5] Implémentation `bus_arbiter.vhd`TLB minimal, PTW simple, cache Direct-Mapped, arbitre simple:** Créer un arbitre simple (ex: priorité fixe CPU > DMA >, modèle exécution séquentiel). **Envisager de SCINDER** UART, parle le protocole RSP minimal avec le DM VHDL, et expose MMU?).
*   **[14.6] Intégration DMA & ce sprint (14a=MMU+Cache PIPT, 14b=Multi Arbitre:** Mettre à jour le Top-Level VHDL. Connecter CPUCore+Atomics).
*   **(Risque MAJEUR) Pro une socket TCP pour qu'un vrai GDB puisse s'y connecter (` (via MMIO), DMA, Cache/MMU (accès page walk) à l'arbitre,blèmes de Timing:** L'ajout de la MMU et de l'arbitre et l'arbitre au contrôleur DDR.
*   **[14target remote localhost:PORT`).
*   **Testbenches VHDL :**
    .7] Testbench `tb_dma_controller.vhd`:** Val*   `sim/testbenches/tb_debug_module.vhd` : va probablement créer de nouveaux chemins critiques et réduire la FMax. Atteindre laider le DMA isolément.
*   **[14.8] Mise Testbench validant l'interface RSP du DM (envoyer commandes RSP, vérifier à Jour Assembleur:** (Si besoin de nouvelles directives/mnémoniques pour faciliter les tests DMA).
*   **[14.9] Testbench clôture de timing sera difficile. -> **Mitigation :** Conception HDL soignée ( réponses) et son interaction avec un CPU simulé basiquement.
    *   M Système DMA (`tb_prismchrono_top_dma.vhd`):**
    *   Créer ROM/DDR simulée avec code CPU configurregistres aux bons endroits). Optimisations de bas niveau si nécessaire. Accepter une FMax basseise à jour `sim/testbenches/tb_prismchrono_core_full_system.ant un transfert DMA mémoire->périph, puis un autre périph->mé pour la validation fonctionnelle.
*   **(Risque Élevé)** Dévhd` : Inclure des `EBREAK` et vérifier que le DMmoire.
    *   Simuler le périphérique (ex: FIFO ou registbogage multi-cœur (même simulé séquentiellement) difficile pourres dans le testbench).
    *   Vérifier les données transf prend le contrôle.
*   **Simulation & Synthèse :**
    *   Validation les atomiques. -> **Mitigation :** Logging très détaillé des accès mémoireérées et le signal/interruption de fin de DMA.
*   **[14.10, de l'état des réservations LR, et des succès/échecs SC en simulation du débogage (arrêt sur EBREAK, lecture GPR via.

**Notes:**
*   Ce sprint vise le sommet de la complexité pour] Simulation & Débogage Final:** Exécuter tous les tests. Vérifier les timings RSP simulé).
    *   **Rapport Final Synthèse/Timing un PoC FPGA avant d'envisager des optimisations très poussées ou des extensions DMA, l'arbitrage, les optimisations pipeline.
*   **[14 ISA exotiques.
*   Obtenir un design qui synthétise et passe/Ressources :** Montre l'utilisation finale des ressources et la.11] Synthèse Finale & Rapport Timing:** Lancer la chaîne FPGA les tests fonctionnels (même à basse fréquence) serait déjà un **succès majeur**. FMax atteinte après optimisations.
*   **Documentation :**
    *   `doc complète. Générer le rapport final FMax / Ressources pour cette version.
*   **[14

**AIDEX Integration Potential:**
*   Aide cruciale pour la **conception de la/debug_interface.md` : Description du module de débogage, du.12] Documentation:** Finaliser `dma_controller_design.md` MMU ternaire** (PTW, TLB).
*   Suggestions protocole RSP supporté, et de l'utilisation avec GDB/proxy pour **adapter les caches en PIPT**.
*   Aide à la.
    *   Rapport final sur les optimisations effectuées et les performances et mettre à jour les autres documents.

**Risks & Mitigation:**
*   **Risque :** atteintes.

**Acceptance Criteria (DoD - Definition of Done):**
*   Le conception de l'**arbitre mémoire**.
*   Génération de code VHDL pour ces Optimisations de timing inefficaces ou introduisant des bugs fonctionnels. -> **Mitigation :** module de débogage (`debug_module`) est implémenté et communique via modules complexes.
*   Assistance pour l'**analyse de timing** et suggestions UART (ou JTAG) en utilisant un sous-ensemble fonctionnel du prot Modifications prudentes et ciblées. Re-simulation fonctionnelle complète après chaque optimisationocole GDB RSP (au minimum : halt, resume, step, read/write G d'optimisation HDL de base.
*   Aide à la création majeure. Utiliser les outils d'analyse de timing statique avec soin.
*   **Risque :PRs, read/write memory).
*   Le CPU core peut être arrêté des **scénarios de test multi-cœur** et à l'interprétation des résultats de** Conception du contrôleur DMA ternaire complexe (gestion adresses/tailles tern (`halt`), repris (`resume`), et exécuté pas-à-pas (`step`) via simulation/débogage.
