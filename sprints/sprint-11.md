nel (2 passes, lexer, parser de base, table des symboles) doit être solide.
*   **Sprint 9 (ISA ≈ RV32I) / Sprint Ω (Fondations Système) / Phase 3:** Spécification *finale* et complète de toutes les instructions (y compris R, I, S, B, U, J, Shifts, CSRs, MRET_T, etc.), leur encodage 12 trits précis, et leur sémantique.

**Core Concept: Feature Completeness, Robustness, and Usability**

Ce sprint va au-delà du simple support des instructions pour faire de `prismchrono_asm` un outil réellement utilisable et fiable. Il s'agit de couvrir tous les cas, de gérer les erreurs gracieusement, et de fournir une sortie optimisée.

```mermaid
graph LR
    A[Code Source .s<br/>(ISA Complète + Directives Avancées)] --> B{prismchrono_asm (v1.0)};

    subgraph prismchrono_asm [Processus d'Assemblage Finalisé]
        direction TB

        subgraph Pass1 [Passe 1: Analyse & Symboles Évoluée]
            P1_Parse[Lecture & Parsing Complet] --> P1_Addr{Calcul Adresse};
            P1_Addr --> P1_Label{Label/EQU Défini?};
            P1_Label -- Oui --> P1_SymTab[(Table des Symboles<br/>Labels & Constantes)];
            P1_Label -- Non --> P1_Size{Calcul Taille};
            P1_Directive{Directive Avancée? (.org/.align/.equ...)} -- Oui --> P1_Addr/P1_SymTab;
            P1_Directive -- Non --> P1_Label;
            P1_Size --> P1_Addr;
            P1_Parse --> P1_Directive;
            P1_Parse --> P1_IR[(Représentation Intermédiaire<br/>+ Infos Ligne/Colonne)];
        end

        subgraph Pass2 [Passe 2: Résolution, Validation & Encodage Complet]
             P2_IR[Lecture IR] --> P2_Expr{Opérande=Expression?};
             P2_Expr -- Oui --> P2_Eval[Évaluer Expression];
             P2_Expr -- Non --> P2_Val[Valeur Directe/Label];
             P2_Val --> P2_Resolve{Résoudre Label via Table Symb.};
             P2_Eval --> P2_Resolve;
             P2_Resolve --> P2_Validate[Valider Opérandes (Type, Plage)];
             P2_Validate -- OK --> P2_Encode[Encoder Instruction/Donnée];
             P2_Validate -- Erreur --> P2_Error(Erreur d'Assemblage);
             P2_Encode --> P2_Output[Buffer Code Machine<br/>(Format Binaire TBD)];
             P2_IR --> P2_DataDir{Directive Avancée? (.tryte/.word/.string)};
             P2_DataDir -- Oui --> P2_Encode;
             P2_DataDir -- Non --> P2_Expr;
        end

        Pass1 --> P2_IR;
        Pass1 -.-> P2_Resolve;
        P2_Output --> WriteFile[Écriture Fichier .tbin/.tobj];
        P2_Error -.-> WriteFile;
    end

    B --> F[Fichier Binaire .tbin<br/>(Optionnel: .tobj Texte)];
    F --> S((prismchrono_sim));

    style Pass1 fill:#ccf,stroke:#333,stroke-width:1px
    style Pass2 fill:#cfc,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   Exécutable `prismchrono_asm` finalisé pour l'ISA v1.0 de base.
*   Support complet de **toutes les instructions PrismChrono v1.0** (équivalent RV32I + système Omega).
*   **Format de sortie binaire (`.tbin`)** défini et implémenté (ex: séquence de trytes bruts, potentiellement avec un en-tête simple). Option `-t` pour garder la sortie texte `.tobj`.
*   **Gestion des erreurs améliorée** avec messages précis, numéro de ligne, et contexte si possible. Rapport d'erreurs multiples.
*   Support pour les **expressions constantes simples** dans les opérandes immédiats.
*   Support pour les directives `.equ` (définition de constantes) et `.string` / `.asciz` (définition de chaînes de caractères ternaires).
*   **Tests unitaires et d'intégration** exhaustifs couvrant toutes les instructions, directives, cas limites, et gestion d'erreurs.
*   Exemples `.s` plus complexes (factorielle, manipulation de tableau, appels de fonction simples).
*   Documentation `README.md` complètement mise à jour.

**Acceptance Criteria (DoD - Definition of Done):**
*   `cargo build --release` et `cargo test --all-features` (si applicable) réussissent.
*   L'assembleur parse et encode correctement **toutes** les instructions PrismChrono v1.0 (R, I, S, B, U, J, Shifts, CSRs, System).
*   Les calculs d'offset pour **`JAL` et `BRANCH`** sont précis, et les limites de plage (-1093/+1093 pour JAL, -40/+40 pour BRANCH) sont strictement vérifiées.
*   La **validation des opérandes** est complète (registre valide, type/plage d'immédiat correcte pour chaque instruction).
*   La directive **`.equ <symbole> <expression>`** permet de définir des constantes symboliques utilisables dans les opérandes.
*   La directive **`.string "..."`** (ou `.asciz`) génère une séquence de trytes représentant la chaîne (encodage ternaire des caractères à définir, ex: 1 tryte/caractère pour ASCII simplifié ?) terminée par un tryte Zéro.
*   Les **expressions constantes** (ex: `5 * (3 + LABEL_OFFSET)`, `SYM >> 2`) sont correctement évaluées (arithmétique entière simple, décalages, opérateurs logiques MIN/MAX si définis) pendant la Passe 2.
*   L'option `-o output.tbin` génère un fichier **binaire** compact contenant la séquence de trytes du programme.
*   L'option `-o output.tobj` (ou option `-t`) génère toujours le **format texte lisible**.
*   Les **messages d'erreur** sont significativement améliorés : indiquent la ligne, la colonne (si possible), le contexte de l'erreur (ex: `Error at line 15: Immediate value '150' out of range for ADDI (expected -121 to +121)`). L'assembleur tente de rapporter plusieurs erreurs par assemblage (jusqu'à une limite).
*   Les **tests unitaires** couvrent tous les encodeurs, les cas limites des plages, les expressions, les nouvelles directives.
*   Des **tests d'intégration** assemblent des exemples plus complexes (factorielle, boucle avec tableau) et le `.tbin` généré, une fois chargé dans `prismchrono_sim` (via une nouvelle fonction de chargement binaire), exécute correctement l'algorithme.

**Structure Cible du Crate `prismchrono_asm` :**
*(Évolution de la structure du Sprint 10)*

```
prismchrono_asm/
├── ... (idem Sprint 10)
└── src/
    ├── main.rs         # Gestion CLI améliorée (options -o, -t)
    ├── core_types.rs
    ├── error.rs        # Enum d'erreurs plus riche, support contexte
    ├── lexer.rs        # Reconnaissance opérateurs expressions (+, -, *, /, >>, <<, MIN, MAX?)
    ├── parser.rs       # Support des expressions dans les opérandes, .equ, .string
    ├── ast.rs          # Potentiellement un AST plus riche pour les expressions
    ├── symbol.rs       # Gérer les symboles .equ (constantes) en plus des labels
    ├── assembler.rs    # Logique des passes gérant expressions et toutes directives
    ├── encoder.rs      # !! Fonctions pour TOUTES les instructions, encodage binaire !!
    ├── operand.rs      # Évaluation des expressions constantes
    ├── output.rs       # Fonctions write_tobj ET write_tbin
    └── tests/
        ├── mod.rs
        ├── expression_tests.rs  # Nouveaux tests
        ├── full_isa_tests.rs    # Tests d'intégration assemblant des fichiers complexes
        └── ... (tests par format/instruction étendus)
```

**Tasks (Nouvelles ou Étendues):**

*   **[11.1] Complétion Encodeurs ISA:** Implémenter les fonctions `encode_*` manquantes dans `encoder.rs` pour *toutes* les instructions non couvertes au Sprint 10 (SUB, MIN, MAX, SLTs, Loads, Stores, Shifts, AUIPC, JALR, Branches, CSRs, System). Mettre à jour `parser.rs` et ajouter des tests unitaires pour chaque.
*   **[11.2] Encodage Branchements (Final):** Raffiner `encode_branch` pour gérer *toutes* les conditions (`EQ`...`BXN`). Valider strictement la plage de l'offset 4 trits. Ajouter des tests exhaustifs pour les conditions et les offsets limites.
*   **[11.3] Validation Opérandes (Systématique):** Revoir *tous* les encodeurs pour ajouter/vérifier la validation systématique des plages des immédiats/offsets et des types de registres attendus. Retourner des `EncodeError` spécifiques.
*   **[11.4] Directive `.equ`:**
    *   Modifier `parser.rs` pour reconnaître `.equ SYM EXPR`.
    *   Modifier `symbol.rs` pour stocker les constantes (différencier des labels d'adresse).
    *   Modifier la résolution (Passe 2) pour utiliser ces constantes dans les expressions.
*   **[11.5] Directive `.string` / `.asciz`:**
    *   Décider d'un encodage ternaire pour les caractères (ex: 1 tryte par caractère ASCII 0-26 ? Ou encodage plus complexe ?). Documenter ce choix.
    *   Modifier `parser.rs` pour reconnaître `.string "..."`.
    *   Modifier `encoder.rs` pour générer la séquence de trytes correspondante, terminée par un tryte Zéro.
*   **[11.6] Expressions Constantes:**
    *   Modifier `lexer.rs` pour reconnaître les opérateurs (`+`, `-`, `*`, `/`, `>>`, `<<`, peut-être `|` pour MAX, `&` pour MIN ?).
    *   Modifier `parser.rs` / `ast.rs` pour construire un arbre d'expression pour les opérandes immédiats.
    *   Implémenter l'évaluation d'expressions dans `operand.rs` ou `assembler.rs` (Passe 2), en utilisant la table des symboles pour les labels/equ. Gérer la précédence des opérateurs.
*   **[11.7] Format Sortie Binaire (`.tbin`):**
    *   Définir le format `.tbin` (ex: juste la séquence brute des trytes ? Un petit en-tête avec taille/adresse de départ ?).
    *   Implémenter `output::write_tbin` qui écrit les données encodées (Passe 2) dans ce format binaire.
    *   Ajouter une option CLI (ex: `-b` ou déduire du suffixe `.tbin`) pour choisir le format binaire.
*   **[11.8] Gestion Erreurs Améliorée:**
    *   Enrichir `enum AssembleError` et ses sous-types pour capturer plus de contexte (ligne, colonne, token fautif, message spécifique).
    *   Modifier le parser pour stocker les infos de localisation (ligne/colonne) dans l'AST/IR.
    *   Modifier la boucle principale d'assemblage pour collecter *plusieurs* erreurs (jusqu'à une limite) avant de s'arrêter, et les afficher de manière formatée.
*   **[11.9] Tests Étendus:**
    *   Ajouter des tests unitaires pour *toutes* les nouvelles instructions et leurs cas limites.
    *   Tester spécifiquement la validation des plages d'immédiats/offsets.
    *   Tester le parsing et l'évaluation des expressions constantes.
    *   Tester les directives `.equ` et `.string`.
    *   Tester la génération des formats `.tobj` et `.tbin`.
    *   Tester la robustesse de la gestion des erreurs (vérifier que les erreurs attendues sont bien levées avec les bons messages).
*   **[11.10] Exemples Complexes:** Écrire des exemples `.s` plus longs (factorielle, recherche tableau) utilisant un plus large éventail d'instructions et de directives. Créer des tests d'intégration qui assemblent ces exemples et vérifient la sortie `.tbin` ou `.tobj`.
*   **[11.11] Documentation Finale:** Mettre à jour `README.md` pour refléter l'ensemble des fonctionnalités, la syntaxe complète, les directives, les options CLI, et le format de sortie.

**Risks & Mitigation:**
*   **(Nouveau)** **Complexité Expressions:** L'évaluation d'expressions peut être complexe (précédence, types). -> Commencer par des expressions très simples (+/-), étendre prudemment. Tests ++.
*   **(Nouveau)** **Format Binaire:** Assurer la cohérence entre l'assembleur et le futur chargeur du simulateur. -> Définir le format *simplement* au début (ex: juste les trytes bruts).
*   **Robustesse Erreurs:** Collecter et afficher plusieurs erreurs correctement peut être délicat. -> Concevoir une structure de collecte d'erreurs flexible.
*   Effort global important. -> Prioriser la couverture ISA et la correction sur les fonctionnalités annexes (expressions complexes, macros...).

**Notes:**
*   Ce sprint transforme `prismchrono_asm` d'un outil basique en un assembleur complet pour l'ISA définie. La qualité et la robustesse sont les maîtres mots.
*   À la fin de ce sprint, l'outil devrait être suffisamment mature pour supporter le développement de programmes significatifs pour `prismchrono_sim`.

**AIDEX Integration Potential:**
*   Aide à l'implémentation systématique des encodeurs restants.
*   Assistance pour la logique d'évaluation des expressions.
*   Génération de code pour le formatage amélioré des erreurs.
*   Suggestions pour la définition et l'implémentation du format binaire `.tbin`.
*   Génération de tests exhaustifs pour les cas limites et les nouvelles fonctionnalités.
*   Revue de code pour la robustesse et la complétude.
```