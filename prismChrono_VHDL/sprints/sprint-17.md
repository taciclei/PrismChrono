# Sprint 17 VHDL (PrismChrono): Différenciation Ternaire - Instructions Spécialisées Avancées & Optimisations Uniques

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Implémenter en VHDL un ensemble d'**instructions et de mécanismes architecturaux avancés** spécifiquement conçus pour **exploiter et potentiellement démontrer matériellement les avantages uniques** de la logique ternaire équilibrée, de la Base 24/60, et de la gestion native des états spéciaux de PrismChrono. Ce sprint vise à créer une **rupture tangible** par rapport aux architectures binaires en optimisant le matériel pour des tâches où le ternaire excelle théoriquement.

**State:** Not Started

**Priority:** Très Élevée (Réalisation de la promesse unique de PrismChrono)

**Estimated Effort:** Très Large (ex: 25-40 points, T-shirt XL/XXL - Conception et implémentation de logiques ternaires complexes non standards)

**Dependencies:**
*   **Sprint 16 VHDL Terminé :** Cœur CPU VHDL multi-cœur (simulé) stable avec pipeline, cache L1 cohérent (simplifié), MMU, DDR, Interruptions, Atomics de base.
*   **ISA PrismChrono Étendue (README Simu / Sprint Futur Instruc) :** Définition claire des instructions spécialisées ternaires/B24 *les plus prometteuses* et de leur encodage.
*   **Assembleur (`prismchrono_asm`) :** Doit être mis à jour pour supporter *toutes* les nouvelles instructions de ce sprint.

**Core Concepts : Focus sur les Points Forts Théoriques**

1.  **Logique Multi-Valuée Matérielle :**
    *   **Branchement 3 Voies Natif (`BRANCH3` ou `TBNZ/TBP/TBN`) :** Implémenter un mécanisme de branchement qui teste directement un résultat ternaire (N, Z, P) issu d'une instruction précédente (ex: `TCMP3` ou `SIGNUM_T`) ou d'un registre, et peut sauter vers *trois* destinations potentielles (ou deux + non-pris). Nécessite une logique de contrôle et potentiellement un calcul d'adresse plus complexe.
    *   **Sélection Ternaire Rapide (`TSEL`) :** Implémenter l'instruction `TSEL Rd, Rs_cond, Rs_ifN, Rs_ifZ, Rs_ifP` de manière optimisée, potentiellement en parallèle dans l'étage EX si les lectures registres peuvent être anticipées.
2.  **Arithmétique Base 24/60 Optimisée :**
    *   **Unité Arithmétique Tryte (TAU - Tryte Arithmetic Unit) :** Créer une petite unité fonctionnelle dédiée (ou une extension majeure de l'ALU) optimisée pour les opérations sur des `EncodedTryte` (6 bits) en Base 24 (ou 60 si défini).
        *   `ADD_B24/SUB_B24/MUL_B24` : Opérations modulo B24 rapides sur des trytes.
        *   `CONVERT_B24_TERN` / `CONVERT_TERN_B24` : Conversion rapide entre valeur numérique tryte et sa représentation ternaire équilibrée (-13 à +13).
    *   **Instructions Multi-Trytes :** Instructions opérant sur plusieurs trytes d'un mot en parallèle (ex: `ADD_B24_VEC Rd, Rs1, Rs2` qui additionne 8 paires de trytes en parallèle). Nécessite un datapath plus large ou une unité SIMD ternaire simple.
3.  **Gestion Matérielle États Spéciaux :**
    *   **Instructions de Vérification Rapide :** Optimiser `CHECKW_VALID` ou `IS_SPECIAL_TRYTE`.
    *   **Propagation Contrôlée :** Instructions permettant de définir comment les états spéciaux se propagent dans l'ALU (ex: `SET_NAN_MODE immediate` pour choisir si Op(NaN, X) = NaN ou si l'opération tente de continuer). Nécessite modification ALU/Contrôle.
    *   **Load/Store Conditionnel :** `LOADW_IF_VALID Rd, addr(Rs1)` (charge seulement si la donnée en mémoire n'est pas NaN/Null?) ou `STOREW_IF_VALID Src, addr(Rs1)` (n'écrit que si Src est valide?). Nécessite une lecture avant écriture ou un état spécial dans le cache.
4.  **Exploitation Densité Ternaire :**
    *   **Instructions `PACK`/`UNPACK` Ternaires :** Implémenter `PACK_TERNARY` / `UNPACK_TERNARY` pour convertir efficacement entre des formats de données compacts (ex: plusieurs petits nombres ternaires stockés dans un seul mot) et les registres standards. Nécessite des décaleurs/masqueurs ternaires complexes.
    *   **(Si Format C fait) Optimisation Format Compact Ternaire :** Analyser si l'encodage 8 trits peut être rendu *encore plus dense* en exploitant mieux les 3^8 combinaisons (par rapport à un simple sous-ensemble d'instructions 12t).

**Visualisation : Ajout d'Unités Fonctionnelles Spécialisées**

```mermaid
graph TD
    subgraph prismchrono_core.vhd [Ajouts Majeurs]
        %% Execution Stage (EX) Enhancements
        EX_Stage --> ALU_Main(ALU 24t);
        EX_Stage --> TAU(Tryte Arithmetic Unit<br/>(Base 24/60 Ops));
        EX_Stage --> PACK_UNPACK(Pack/Unpack Unit<br/>(Ternary Density));
        EX_Stage --> SPEC_STATE_LOGIC(Special State Logic<br/>(CHECKW, IS_SPECIAL...));

        %% Branch Logic Enhancements
        CU -- Cond (N/Z/P) --> BRANCH_LOGIC(Branch Logic);
        BRANCH_LOGIC -- Target Addr --> PC_Update_Logic; %% Peut avoir 3 cibles

        %% Data Path Additions
        Datapath -- Operands --> TAU;
        Datapath -- Operands --> PACK_UNPACK;
        TAU -- Result --> MUX_WR_DATA;
        PACK_UNPACK -- Result --> MUX_WR_DATA;
        SPEC_STATE_LOGIC -- Result (P/N) --> MUX_WR_DATA;
    end

    style TAU fill:#fec,stroke:#333,stroke-width:1px
    style PACK_UNPACK fill:#fec,stroke:#333,stroke-width:1px
    style SPEC_STATE_LOGIC fill:#fec,stroke:#333,stroke-width:1px
    style BRANCH_LOGIC fill:#ffc,stroke:#333,stroke-width:1px

```

**Deliverables:**
*   **Code VHDL Mis à Jour/Nouveaux :**
    *   Modules VHDL pour les nouvelles unités fonctionnelles (`tryte_arith_unit.vhd`, `pack_unpack_unit.vhd`...).
    *   ALU, Datapath, Control Unit étendus pour intégrer et contrôler ces unités/instructions.
    *   Logique de branchement modifiée pour `BRANCH3` (si implémenté).
    *   Mise à jour `rtl/pkg/` avec tous les nouveaux opcodes/fonctions.
*   **Assembleur (`prismchrono_asm`) Mis à Jour :** Support complet pour **toutes** les nouvelles instructions spécialisées. Syntaxe claire pour les opérations Base24 ou multi-valuées.
*   **Testbenches VHDL :**
    *   Tests unitaires pour chaque nouvelle unité fonctionnelle spécialisée.
    *   Extension majeure des testbenches système (`tb_..._full_system`, `tb_..._special_instr`) avec des séquences de code assembleur (généré par le nouvel assembleur) qui :
        *   Utilisent intensivement les instructions `TCMP3`/`TSEL`/`BRANCH3`.
        *   Effectuent des calculs significatifs en Base 24/60 via la TAU.
        *   Manipulent les états spéciaux avec `CHECKW`/`IS_SPECIAL`.
        *   Utilisent `PACK`/`UNPACK` pour des données compactes.
*   **Simulation & Synthèse :**
    *   Validation en simulation du fonctionnement correct et des avantages potentiels (ex: moins d'instructions pour une tâche donnée) des nouvelles instructions.
    *   Rapport de Synthèse/Timing : Évaluer le coût en ressources (LUTs/BRAM) et l'impact sur la FMax de ces instructions spécialisées.
*   **Documentation :**
    *   `doc/ternary_specialized_instructions_hdl.md` (MàJ) : Documentation complète de toutes les instructions spécialisées implémentées, leur logique, et leur cas d'usage potentiel.
    *   Mise à jour des documents ALU, Datapath, FSM, ISA.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les modules VHDL compilent. Les testbenches (unitaires et système) passent sans erreur d'assertion.
*   L'assembleur `prismchrono_asm` gère la syntaxe et l'encodage de toutes les nouvelles instructions.
*   La simulation prouve le fonctionnement correct des **instructions spécialisées sélectionnées** :
    *   Logique multi-valuée (`TCMP3`, `TSEL`, `BRANCH3`?) exécutée correctement.
    *   Opérations Base 24/60 (`ADD_B24`...) via TAU produisent les bons résultats modulo la base.
    *   Manipulation/Test des états spéciaux via `CHECKW`/`IS_SPECIAL` fonctionne.
    *   Compression/Décompression via `PACK`/`UNPACK` fonctionne.
*   Les nouvelles instructions s'intègrent au pipeline et leur latence (si multi-cycles) est gérée.
*   Le design complet est synthétisé et implémenté. Le **coût en ressources** et l'**impact sur la FMax** des instructions spécialisées sont mesurés et documentés.
*   (Critère Clé) Au moins un **micro-benchmark** simple (exécuté en simulation VHDL) montre un **avantage quantifiable** (ex: nombre de cycles réduit, taille de code réduite) grâce à l'utilisation d'une instruction spécialisée par rapport à une séquence équivalente d'instructions de base.

**Tasks:**

*   **[17.1] Sélection Finale & Conception Instructions Spé.:** Confirmer le sous-ensemble précis à implémenter (TCMP3, ABS_T, SIGNUM_T, EXTRACT/INSERT_TRYTE, ADD_B24?, CHECKW, PACK/UNPACK?, TSEL?, BRANCH3?). Définir leur sémantique et encodage ISA final.
*   **[17.2] Implémentation VHDL - Logique Multi-Valuée:** Ajouter TCMP3 à l'ALU. Concevoir et implémenter l'unité TSEL et/ou la logique BRANCH3 (modification FSM + Datapath).
*   **[17.3] Implémentation VHDL - Arithmétique Symétrique:** Ajouter ABS_T, SIGNUM_T à l'ALU.
*   **[17.4] Implémentation VHDL - Base 24/Trytes:** Ajouter EXTRACT/INSERT au datapath. Concevoir et implémenter l'unité TAU (ou extension ALU) pour ADD_B24.
*   **[17.5] Implémentation VHDL - États Spéciaux:** Ajouter la logique CHECKW, IS_SPECIAL_TRYTE (probablement combinatoire sur le datapath).
*   **[17.6] Implémentation VHDL - Densité:** Concevoir et implémenter l'unité PACK/UNPACK (probablement une unité avec décaleurs/masqueurs complexes).
*   **[17.7] Mise à Jour Control Unit:** Étendre le décodeur et la FSM pour gérer toutes ces nouvelles instructions (certaines peuvent nécessiter des états multi-cycles).
*   **[17.8] Mise à Jour Assembleur (`prismchrono_asm`):** **Travail conséquent** pour ajouter la syntaxe (ex: `ADD_B24 R1, R2, R3`? `PACK R1, R2, R3, R4`?) et l'encodage de toutes ces nouvelles instructions.
*   **[17.9] Mise à Jour Testbenches:** Écrire des tests unitaires pour les nouvelles unités. Étendre massivement le testbench système avec du code assembleur (généré !) utilisant chaque nouvelle instruction et validant son résultat. Inclure un micro-benchmark comparatif (ex: faire une opé B24 avec ADD_B24 vs avec des instructions de base).
*   **[17.10] Simulation & Débogage:** Valider toutes les nouvelles fonctionnalités en simulation VHDL.
*   **[17.11] Synthèse & Analyse:** Lancer la chaîne FPGA. Analyser l'utilisation finale des ressources (on s'approche peut-être des limites du 85F !) et la FMax obtenue. Comparer avec le Sprint précédent.
*   **[17.12] Documentation Finale:** Documenter toutes les instructions spécialisées, leur coût, et leur avantage potentiel démontré.

**Risks & Mitigation:**
*   **Risque :** La logique pour certaines instructions spécialisées (PACK/UNPACK, Base 24, TSEL) est très complexe en HDL et consomme beaucoup de ressources/dégrade le timing. -> **Mitigation :** Choisir un sous-ensemble réaliste. Simplifier les implémentations (ex: multi-cycles). Prioriser les instructions à l'impact le plus fort.
*   **Risque :** Difficulté à démontrer un avantage *quantifiable* en simulation VHDL (ex: gain en cycles difficile à mesurer précisément sans benchmarks complexes). -> **Mitigation :** Se concentrer sur la validation fonctionnelle et l'analyse qualitative du code (ex: "cette tâche nécessite 1 instruction spécialisée au lieu de 5 instructions de base"). Documenter le coût en ressources comme contrepartie.
*   **Risque :** Saturation des ressources du FPGA ECP5-85F. -> **Mitigation :** Surveiller l'utilisation à chaque ajout. Optimiser agressivement le code VHDL. Être prêt à désactiver certaines instructions si nécessaire pour faire tenir le design.
*   **Risque :** L'assembleur ne suit pas le rythme des ajouts VHDL. -> **Mitigation :** Bien coordonner. Tester le VHDL avec des instructions encodées manuellement si besoin au début.

**Notes:**
*   Ce sprint est l'occasion de rendre PrismChrono VHDL unique et d'explorer activement le potentiel du ternaire en matériel (simulé).
*   L'analyse post-synthèse (ressources vs FMax vs fonctionnalité ajoutée) est cruciale pour évaluer le "coût/bénéfice" des instructions spécialisées.
*   C'est potentiellement le dernier sprint majeur d'ajout de fonctionnalités *CPU* avant de se concentrer sur l'OS, les périphériques plus complexes, ou des optimisations très poussées.

**AIDEX Integration Potential:**
*   **Conception Instructions Spécialisées :** Brainstorming sur la sémantique ternaire/B24, aide à la conception de la logique VHDL.
*   **Génération Code VHDL :** Pour les nouvelles unités fonctionnelles et l'extension des modules existants.
*   **Mise à Jour Assembleur :** Assistance pour ajouter la nouvelle syntaxe et l'encodage.
*   **Génération Code de Test :** Création de séquences assembleur complexes pour valider les nouvelles instructions et démontrer leurs avantages potentiels.
*   **Analyse Performance/Ressources :** Aide à interpréter les rapports de synthèse et de timing. Suggestions pour optimiser ou évaluer le coût/bénéfice.
