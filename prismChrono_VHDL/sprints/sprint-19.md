# Sprint 19 VHDL (PrismChrono): Accélération Neuronale Ternaire Initiale (TNN Extension - Base)

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Explorer et implémenter une **première extension matérielle expérimentale** dans `prismchrono_core` dédiée à l'**accélération de calculs fondamentaux utilisés dans les réseaux neuronaux ternaires (TNN)**. L'objectif est d'ajouter une ou deux **instructions TNN de base** (ex: une forme de produit scalaire ternaire ou une fonction d'activation simple) en VHDL, démontrant la faisabilité d'intégrer de tels accélérateurs et d'évaluer leur coût en ressources par rapport à une implémentation logicielle (en assembleur PrismChrono).

**State:** Not Started

**Priority:** Moyenne/Élevée (Explore un domaine d'application potentiellement clé pour le ternaire, mais moins fondamental que les sprints système précédents)

**Estimated Effort:** Large (ex: 15-25 points, T-shirt L/XL - Conception d'unités de calcul ternaire non standard, intégration pipeline/datapath)

**Dependencies:**
*   **Sprint 18 VHDL Terminé :** Cœur CPU VHDL stable et relativement optimisé.
*   **ISA PrismChrono Étendue (README Simu) :** Définition précise (sémantique, encodage) des instructions TNN cibles (ex: `TNNMUL`, `TNNACT`).
*   **Recherche / Conception TNN :** Compréhension des opérations clés dans les réseaux neuronaux ternaires (ex: multiplication ternaire {N,Z,P} * {N,Z,P}, accumulation, fonctions d'activation ternaires type signum ou seuil).

**Core Concepts:**
1.  **Réseaux Neuronaux Ternaires (TNN) :** Réseaux où les poids et/Okayou les activations sont quantifiés sur trois niveaux (-1, 0, +, après un Sprint 18 VHDL intense axé sur la stabilisation, les interruptions via PLIC simulé et le débogage matériel, le **Sprint1 ou N, Z, P). L'objectif est de réduire la complexité 19 VHDL** peut enfin revenir sur l'ajout de **fonctionnalités qui de calcul (la multiplication par -1, 0, 1 est simple) et la taille mémoire par rapport aux réseaux binaires ou flottants.
2. exploitent plus agressivement le caractère unique de PrismChrono**, ou commencer  **Opérations TNN Clés :**
    *   **Produit à intégrer des **optimisations de performance plus avancées** comme un début Scalaire / Convolution :** Implique de nombreuses multiplications ternaires (p de support pour les instructions compactes ou un cache L2.

Choisissons deoids * activation) suivies d'une accumulation (addition). La multiplication ternaire X nous concentrer sur :

1.  **Instructions Ternaires SpécialNOR binaire est souvent utilisée comme approximation : `a*b ≈ XNOR(a_isées (Suite) :** Implémenter un autre lot d'instructions du backlog (Sprint 17) qui semblaient prometteuses mais peut-être plus complexes.
2.  **Introduction Format Compact (C) :** Si nonbin, b_bin)` si on encode N=0, P=1 ( fait précédemment, c'est le moment d'ajouter le support pour les instructionsZ doit être géré séparément). Une implémentation ternaire directe pourrait être différente.
    *   **Fonction d'Activation Ternaire :** App 8 trits pour améliorer la densité de code.
3.  **(Optionnel) Optimisation Cache L1 :** Améliorer la performance oulique un seuil pour convertir une somme accumulée en une sortie ternaire N l'efficacité du cache L1 (ex: meilleure politique LRU, préfetching, Z, ou P (ex: `signum` ou une fonction avec seuils simple).

---

```markdown
# Sprint 19 VHDL (Prism +/- Th).
3.  **Accélérateur Matériel (UF - Unité Fonctionnelle) :**
    *   Concevoir une unité VHDL dédiée (`tnn_unit.vhd`?) capable d'effectuerChrono): Instructions Ternaires Avancées & Support Format Compact (C)

**Nom une opération TNN de base (ex: produit scalaire ternaire sur un petit de Code Projet :** PrismChrono
**Composant :** ` nombre d'éléments, ou une fonction d'activation).
    *   Cette unité sera probablement **multi-cycles**.
    *   Elle sera intégrée dansprismChrono_VHDL`

**Objective:** Différencier davantage l' l'étage d'exécution (EX) du pipeline.
4.implémentation matérielle VHDL de PrismChrono en :
1.    **Instructions ISA TNN :**
    *   Définir etImplémentant un **nouveau lot d'instructions ternaires spécialisées** complexes, choisies pour leur potentiel d'accélération ou de simplification de tâches implémenter l'instruction (ex: `TDOTPROD Rd, Rs spécifiques (ex: Base 24/60, logique multi-valuée1, Rs2` pour un produit scalaire ternaire de vecteurs courts avancée, manipulation d'états spéciaux).
2.  Intégrant le support pour le **format d'instruction compact 8 trits (Format C)**, stockés dans Rs1/Rs2, ou `TACTIVATE Rd, Rs1 modifiant les étages Fetch et Decode du pipeline pour gérer les deux longueurs d` pour appliquer une fonction d'activation).
    *   Adapter le décodeur et l'unité de contrôle pour ces instructions.

**Visualisation de l'Inté'instruction et améliorer potentiellement la densité de code et l'efficacité du cache dgration :**

```mermaid
graph TD
    subgraph prismchrono'instructions.
3.  **(Optionnel)** Apportant des **_core.vhd [Ajout Unité TNN]
        %% Executionoptimisations ciblées au cache L1** (si l'analyse des Stage (EX)
        EX_Stage --> ALU_Main(ALU  sprints précédents a révélé des goulots d'étranglement spécifiques).

**State24t);
        EX_Stage --> TNN_Unit(Tern:** Not Started

**Priority:** Élevée (Pousse la différenciation ternary Neural Network Unit<br/>(ex: Dot Product, Activation));
        %%aire, améliore potentiellement densité/performance)

**Estimated Effort:** Très Large (ex ... autres unités ...

        %% Datapath
        Datapath -- Operands (: 25-40 points, T-shirt XL/XXL -Rs1, Rs2) --> TNN_Unit;
        TNN_Unit -- Nouvelles unités fonctionnelles ternaires complexes, refonte majeure Fetch/Decode pour Result --> MUX_WR_DATA;

        %% Control Unit
        CU format C)

**Dependencies:**
*   **Sprint 18 VHDL -- Contrôle TNN Unit & Stalls --> TNN_Unit;
 Terminé :** Cœur CPU VHDL stable et optimisé, avec pipeline, cache L1, MMU, DDR, PLIC simulé, Debug        CU -- Contrôle MUX WR --> MUX_WR_DATA;
        IR -- TNN Opcodes --> CU;
    end

    style TNN Module de base. FMax raisonnable atteinte.
*   **ISA PrismCh_Unit fill:#fec,stroke:#333,stroke-widthrono Étendue :** Définition précise et encodage des instructions spécial:1px
```

**Deliverables:**
*   **Code Visées ternaires *avancées* et des instructions du *format compact 8 trits*.
*   **Assembleur (`prismchrono_asm`) :** Devra être mis à jour pour supporter *toutes* les nouvelles instructions (spHDL Mis à Jour/Nouveaux :**
    *   `rtl/accel/tnn_unit.vhd` (Nouveau) :écialisées et compactes).

**Core Concepts:**
1.   Module VHDL implémentant la (ou les) fonction(s) T**Instructions Spécialisées Avancées :**
    *   **SéNN choisie(s) (ex: produit scalaire ternaire multi-cycleslection :** Choisir parmi les instructions non implémentées au Sprint 17, fonction d'activation).
    *   Mise à jour `rtl/core, en privilégiant celles avec le plus fort potentiel ternaire/B24 (/datapath.vhd` : Intégration de l'unité TNNex: `ADD_B24_TRYTE`, `MUL_B24_TRYTE`?, `TSEL`, `BRANCH3`, `PACK`/ dans l'étage EX.
    *   Mise à jour ``UNPACK`, `LOADTM`/`STORETM`...).
    *   rtl/core/control_unit.vhd` : Décodage et**Implémentation :** Conception et écriture VHDL des unités fonctionnelles dédiées (ex: `base24_unit`, `pack_unpack_unit contrôle des nouvelles instructions TNN, gestion des stalls si l'unité TNN est multi-`) ou extensions majeures de l'ALU/Datapath. Gestion potentcycles.
    *   Mise à jour `rtl/pkg/`ielle de latences multi-cycles.
2.  **Support Format Compact ( : Nouveaux opcodes TNN.
*   **Assembleur (`C - 8 Trits) :**
    *   **Détection Longprismchrono_asm`) Mis à Jour :** Support pour la syntaxe et lueur :** L'étage Fetch ou Decode doit pouvoir déterminer si l''encodage des nouvelles instructions TNN.
*   **Testbinstruction est sur 8 ou 12 trits (souvent basé sur lesenches VHDL :**
    *   `sim/testbenches/ premiers trits de l'instruction).
    *   **Fetch Modifié :** Ltb_tnn_unit.vhd` : Testbench unitaire pour val'étage IF doit potentiellement chercher plus de données (ex: chercher toujoursider la fonctionnalité de l'unité TNN isolément.
    *   M 12t ou plus) et les stocker dans un buffer. Il fournit ensuite soit 8t soit 12t à l'étage IDise à jour `sim/testbenches/tb_prismchrono_core_. La logique d'incrémentation du PC devient variable (+2 ou +3full_system.vhd` (ou nouveau) avec des séquences de code assembleur utilisant les instructions TNN et vérifiant leur résultat.
*    trytes ? alignement ?).
    *   **Decode Modifié :** Le décodeur doit gérer les deux jeux d'opcodes et extraire les champs (**Simulation & Synthèse :**
    *   Validation en simulation du fonctionnement des instructions Tplus petits et réarrangés) des instructions 8t. Peut nécessiter unNN.
    *   Rapport de Synthèse/Timing : Évaluer le décodeur 8t séparé ou une logique conditionnelle complexe.
 coût en ressources (LUTs, DSPs?, BRAM?) et l'impact    *   **Expansion (Optionnel) :** Parfois, les instructions sur la FMax de l'unité TNN.
*   **Documentation compactes sont "étendues" en leur équivalent 12t plus :**
    *   `doc/tnn_extension.md` : tôt dans le pipeline pour simplifier les étages suivants.
3.  ** Description de l'architecture de l'unité TNN, des instructions implémentées,Optimisation Cache L1 (Optionnel) :**
    *   ** et de leur utilisation potentielle.

**Acceptance Criteria (DoD - DefinitionAnalyse :** Utiliser des compteurs de performance (si ajoutés au S18) ou une analyse de trace pour identifier les faiblesses ( of Done):**
*   Tous les modules VHDL compilent. Les testbenches passent sans erreur d'assertion.
*   L'assembleex: taux de miss élevé, politique LRU inefficace, latence écur `prismchrono_asm` supporte les nouvelles instructions TNN.
riture write-back).
    *   **Améliorations :** Implément*   La simulation du testbench système démontre l'exécution correcte deer une meilleure politique LRU (pseudo-LRU), ajouter un petit buffer d'écriture (write buffer) pour masquer la latence du write-back, envis la (ou des) **instruction(s) TNN implémentée(sager un préfetching matériel très simple (ex: prefetch ligne suivante sur miss)**, produisant le résultat attendu pour des données de test connues.
*   ).

**Visualisation : Impact sur Fetch/Decode, Nouvelles Unités EXL'unité TNN s'intègre correctement dans le pipeline, et les**

```mermaid
graph TD
    subgraph prismchrono_core. **stalls multi-cycles** (si nécessaire) sont gérés.
*   Levhd [Évolution Sprint 19]
        %% Fetch/Decode pour design complet est synthétisé et implémenté. Le **coût en Format Compact
        MEM_IF(I-Cache / Mem Interface) -- ressources** de l'unité TNN est mesuré et documenté. La Fetched Data --> IF_Logic{IF Stage Logic};
        IF_Logic -- Detect FMax globale est réévaluée.
*   La documentation de l'extensions 8t/12t --> Instr_Buffer(Instruction Buffer/Aligner);
        IF_Logic -- Variable Inc --> PC_Reg; TNN est créée.

**Tasks:**

*   **[19
        Instr_Buffer -- 8t or 12t Instr --> IF.1] Conception Unité TNN:**
    *   **Choisir l_ID_Reg;
        IF_ID_Reg --> ID_Logic{ID Stage Logic};
        ID_Logic -- Decodes 8t &'Opération :** Sélectionner 1 ou 2 opérations TNN clés 12t --> ID_EX_Reg;
        ID_Logic -- Control Signals --> CU(Control Unit);

        %% Execution Stage avec Nouvelles Un à implémenter (ex: Produit Scalaire Ternaire sur 8ités
        ID_EX_Reg -- Operands/Control --> EX_Stage{EX Stage};
        EX_Stage --> ALU(ALU 24t); éléments ? Fonction d'activation Signum ?).
    *   **Définir Alg
        EX_Stage --> NEW_TERN_UNIT_1(Ex: Baseorithme/Logique :** Comment réaliser l'opération en logique ternaire (24/60 Unit);
        EX_Stage --> NEW_TERNsimulée en binaire) ? Comment gérer les accumulateurs ? Sera-t-elle_UNIT_2(Ex: Pack/Unpack Unit);
        EX combinatoire ou multi-cycles ?
    *   **Définir Interface_Stage --> NEW_TERN_UNIT_3(Ex: Adv. Multi-Value Logic);
        ALU -- Result --> MUX_WB;
        NEW_TERN_UNIT_1 -- Result --> MUX_WB;
        NEW_TERN_UNIT_2 -- Result --> MUX_WB;
        NEW_ :** Quels opérandes (registres), quel résultat ? Quels signaux deTERN_UNIT_3 -- Result --> MUX_WB;

        %% Cache L1 Optimisation (Optionnel)
        subgraph L1_Caches [Caches L1 Améliorés]
            I_Cache( contrôle (start, busy, done) ?
*   **[19I-Cache<br/>+ Prefetch?)
            D_Cache(D-.2] Implémentation VHDL (`tnn_unit.vCache<br/>+ pLRU? + Write Buffer?)
        end
        IF_Stage <--> I_Cache;
        MEM_Stage <--> D_Cache;

    end

    style Instr_Buffer fill:#hd`) :** Écrire le module VHDL pour l'unité TNN choisie. Si multi-cycles, implémenter la FSM interneeef,stroke:#333
    style ID_Logic fill:#.
*   **[19.3] Testbench Unitaire (`ccf,stroke:#333
    style NEW_TERN_UNITtb_tnn_unit.vhd`) :** Valider l'unité TNN_1 fill:#fec,stroke:#333
    style NEW_TERN_UNIT_2 fill:#fec,stroke:#333 isolément avec des vecteurs de test couvrant différents cas.
*   **[19.4] Définition ISA & Encodage TNN:** Final
    style NEW_TERN_UNIT_3 fill:#fec,strokeiser l'opcode, le format (probablement R-Type ou custom), et l'encodage 12t (ou 8t?) pour la:#333
    style L1_Caches fill:#dde,stroke:#3/les nouvelle(s) instruction(s) TNN. Mettre à jour33
```

**Deliverables:**
*   **Code VHDL `prismchrono_types_pkg`.
*   **[19. Mis à Jour/Nouveaux :**
    *   Modules VHDL5] Mise à Jour Datapath:** Instancier `tnn_unit pour les nouvelles unités fonctionnelles ternaires (`base24_unit.vhd`` dans l'étage EX. Ajouter les MUX et connexions nécessaires pour les opérandes et le résultat.
*   **[19.6]...).
    *   Modification majeure des étages `IF` et `ID` pour Mise à Jour Control Unit:**
    *   Étendre le décodeur pour reconnaître les le support du format compact 8t/12t.
    *   Modification opcodes TNN.
    *   Adapter la FSM pour contrôler l de l'ALU, Datapath, Control Unit pour intégrer les nouvelles instructions'unité TNN (signal `start`).
    *   Si l'unité TNN.
    *   (Optionnel) Modifications des modules `l1_ic est multi-cycles, implémenter la logique de **stall** du pipeline (figerache.vhd`/`l1_dcache.vhd` pour IF/ID/EX) tant que l'unité TNN est occupée les optimisations.
    *   Mise à jour `rtl/pkg (`busy` signal).
*   **[19.7] Mise à Jour/` : Nouveaux opcodes/fonctions pour spécialisées et compactes Assembleur:** Ajouter le support pour les nouvelles instructions TNN.
*   **[1.
*   **Assembleur (`prismchrono_asm`) Mis à Jour9.8] Mise à Jour Testbench Système:**
    *   É :** **Travail conséquent** pour ajouter la syntaxe et l'encodcrire du code assembleur (généré) qui initialise des données (vectage de *toutes* les nouvelles instructions (spécialisées ET compactes). Doit pouvoir générer du code mixte 8t/12t.
eurs ternaires en mémoire), les charge dans des registres, exécute l*   **Testbenches VHDL :**
    *   Tests unit'instruction TNN, et stocke/vérifie le résultat.
    *aires pour les nouvelles unités fonctionnelles ternaires.
    *   Extension majeure des testbenches système (`tb_..._full_system` ou nouveau   Vérifier la gestion correcte des stalls si l'instruction TNN est multi `tb_..._advanced_isa`) pour :
        *   Valider chaque-cycles.
*   **[19.9] Simulation & Dé nouvelle instruction spécialisée avancée.
        *   Valider l'exécution correcte d'un mélange d'instructions 8t et 12bogage:** Valider l'exécution de bout en bout des instructions TNN danst.
        *   Valider les optimisations de cache (si faites le pipeline via simulation et VCD.
*   **[19.1, via compteurs de performance ou analyse de trace).
*   **Simulation & Synth0] Synthèse & Analyse:** Lancer la chaîne FPGA. Analyser lèse :**
    *   Validation fonctionnelle de toutes les nouvelles fonctionnalités en simulation.'utilisation des ressources (LUTs, DSPs, BRAM) de l'unité T
    *   Rapport de Synthèse/Timing : Évaluer le coût final en ressources (on est probablement proche des limites du 85F) et la FNN et l'impact global sur la FMax.
*   **[Max après intégration de ces fonctionnalités avancées.
*   **Documentation :**
    19.11] Documentation:** Rédiger `doc/tnn*   Documentation complète de *toutes* les instructions spécialisées et compactes implémentées_extension.md`.

**Risks & Mitigation:**
*   **.
    *   Mise à jour de la documentation du pipeline (gestion 8t/12t) et du cache (optimisations).

**Risque :** Conception de la logique TNN ternaire complexe et non standard.Acceptance Criteria (DoD - Definition of Done):**
*   Tous -> **Mitigation :** Commencer par une opération très simple (ex: activation sign les modules VHDL compilent. Tous les testbenches (incluant les nouveaux/um, ou produit scalaire sur très peu d'éléments). S'inspirer deétendus) passent sans erreur d'assertion.
*   L'assembleur la littérature TNN mais adapter au ternaire équilibré.
*   **Ris `prismchrono_asm` supporte **toutes** les instructions implémentéesque :** Unité TNN trop gourmande en ressources ou trop lente ( (standard 12t, compactes 8t, spécialisées ternchemin critique long). -> **Mitigation :** Utiliser une implémentation multiaires).
*   La simulation prouve le fonctionnement correct des **instructions spécialisées avancées** sélectionnées.
*   Le CPU VHDL **décode et exéc-cycles. Optimiser le VHDL. Utiliser les blocs DSP de l'ECPute correctement un flux mixte d'instructions 8t et 12t**,5 si pertinent (pour les multiplications internes si nécessaires).
*   **Risque : avec une gestion correcte du PC.
*   (Optionnel) Les optimisations** Intégration de l'unité multi-cycles dans le pipeline complexe de cache L1 sont fonctionnelles et leur impact (simulé) est évalu (gestion des stalls). -> **Mitigation :** Bien définir l'interface (é.
*   Le design complet final est synthétisé et implémenté sur lestart/busy/done). Utiliser un schéma de stall standard. Tester spéc FPGA cible. L'utilisation des ressources est **critique** et documentée. Laifiquement les interactions avec le forwarding existant.

**Notes:**
*   Ce sprint FMax finale est mesurée.
*   La documentation de l'ISA étendue est plus **exploratoire**. Le but est de démontrer la *faisabilité* et des optimisations est complète.
*   (Critère Clé) et d'avoir une première idée du *coût* d'une acc Des micro-benchmarks spécifiques exécutés en simulation VHDL montrent un avantage clairélération matérielle ternaire spécifique.
*   Le choix de l'opération (cycles, taille de code) pour les instructions spécialisées ou le format compact par TNN à implémenter est clé : il faut quelque chose qui soit pertinent rapport aux implémentations précédentes.

**Tasks:**

*   **[19 pour les TNN *et* potentiellement avantageux en ternaire.
.1] Sélection Finale & Conception Instr. Spécialisées Avancées*   Les résultats de ce sprint (coût en ressources, performance potentielle) gu:** Choisir 2-4 instructions ternaires/B24 avancées (ex:ideront les décisions futures sur l'intérêt de poursuivre dans cette voie d'accélération `TSEL`, `ADD_B24`, `PACK`/`UNPACK`). matérielle spécialisée.

**AIDEX Integration Potential:**
*   Aide à la Finaliser leur sémantique et encodage.
*   **[ recherche et à la compréhension des algorithmes TNN et de leur adaptation potentielle au ternaire19.2] Implémentation VHDL - Unités Spécial équilibré.
*   Assistance pour la conception et l'implisées:** Créer les modules VHDL (`base24_unit`...).
*   **[19.3] Conception Support Format Compact (Cémentation VHDL de l'unité TNN (logique ternaire simul):**
    *   Finaliser l'ISA compacte 8t (ée, FSM multi-cycles).
*   Génération de code assemblequelles instructions, quel encodage).
    *   Concevoir la logiqueur de test utilisant les nouvelles instructions TNN.
*   Aide à l' IF/ID pour gérer les deux longueurs (buffer? pré-décodanalyse des rapports de synthèse pour évaluer le coût de l'unité TNN.age? PC variable?).
*   **[19.4] Impl
*   Débogage assisté des simulations impliquant l'unité TNNémentation VHDL - Modification IF/ID pour Format C:** Modifier lourd et les stalls pipeline.
