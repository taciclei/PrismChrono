Okay, je comprends. Tu veux une version améliorée de la description du **Sprint 10 (Assembleur - Base)**, en utilisant le nouveau nom "PrismChrono" et en tenant compte de la structure actuelle de ton projet `prismChrono_sim`.

Voici une version révisée et plus détaillée :

```markdown
# Sprint 10: Assembleur de Base (`prismchrono_asm`)

**Nom de Code Projet :** PrismChrono
**Composant :** `prismchrono_asm` (Nouvel outil)

**Objective:** Développer l'outil en ligne de commande `prismchrono_asm`, un assembleur **fondamental** pour l'architecture PrismChrono. Cet outil traduira des fichiers texte (`.s`) contenant du code assembleur PrismChrono (mnémoniques, registres, labels, directives) en un fichier de sortie (`.tobj`) représentant le code machine ternaire (format texte lisible dans un premier temps). L'implémentation reposera sur le mécanisme classique de l'**assemblage en deux passes** pour gérer les références avant aux labels. Ce sprint se concentre sur un sous-ensemble *essentiel* d'instructions et de directives, suffisant pour écrire et assembler des programmes de test de base pour le simulateur `prismchrono_sim`.

**State:** Not Started

**Priority:** High (Critique pour permettre l'écriture et le test de programmes significatifs sur `prismchrono_sim`)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - la mise en place d'un assembleur est un travail conséquent)

**Dependencies:**
*   **Sprint 5 (ISA Formalisation et Décodeur) / Phase 3 (ISA PrismChrono v1.0) :** Fournissent la spécification *exacte* de l'encodage 12 trits des instructions (formats R, I, S, B, U, J), les valeurs ternaires des OpCodes, Funcs, Conds, et le mapping des registres. L'encodeur de `prismchrono_asm` doit s'y conformer strictement.
*   **`prismchrono_sim/src/core/types.rs` :** Définit les types `Trit`, `Tryte`, `Word`, `Address` qui seront nécessaires pour représenter et manipuler les données ternaires dans l'assembleur.

**Core Concept: Two-Pass Assembly**

L'assemblage en deux passes est nécessaire pour résoudre les références à des labels définis *après* leur utilisation (références avant).

```mermaid
graph LR
    A[Fichier .s<br/>(Assembleur PrismChrono)] --> B{prismchrono_asm};

    subgraph prismchrono_asm [Processus d'Assemblage]
        direction TB

        subgraph Pass1 [Passe 1: Analyse & Symboles]
            P1_Parse[Lecture & Parsing Ligne par Ligne] --> P1_Addr{Calcul Adresse Courante};
            P1_Addr --> P1_Label{Label Défini?};
            P1_Label -- Oui --> P1_SymTab[(Table des Symboles)];
            P1_Label -- Non --> P1_Size{Calcul Taille (Instr/Data)};
            P1_Directive{Directive .org/.align?} -- Oui --> P1_Addr;
            P1_Directive -- Non --> P1_Label;
            P1_Size --> P1_Addr;
            P1_Parse --> P1_Directive;
            P1_Parse --> P1_IR[(Représentation Intermédiaire)];
        end

        subgraph Pass2 [Passe 2: Résolution & Encodage]
             P2_IR[Lecture IR] --> P2_LabelRef{Référence Label?};
             P2_LabelRef -- Oui --> P2_Resolve{Résoudre via Table Symb.};
             P2_Resolve --> P2_Calc[Calculer Offset/Imm Final];
             P2_LabelRef -- Non --> P2_Calc;
             P2_Calc --> P2_EncodeInstr[Encoder Instruction -> 12 Trits];
             P2_IR --> P2_DataDir{Directive .tryte/.word?};
             P2_DataDir -- Oui --> P2_EncodeData[Encoder Données -> Trytes];
             P2_DataDir -- Non --> P2_LabelRef;
             P2_EncodeInstr --> P2_Output[Buffer Code Machine];
             P2_EncodeData --> P2_Output;
        end

        Pass1 --> P2_IR;
        Pass1 -.-> P2_Resolve;
        P2_Output --> WriteFile[Écriture Fichier .tobj];
    end

    B --> F[Fichier .tobj<br/>(Texte Lisible)];
    F -.-> S((prismchrono_sim));

    style Pass1 fill:#ccf,stroke:#333,stroke-width:1px
    style Pass2 fill:#cfc,stroke:#333,stroke-width:1px
```
*   **Passe 1 :** Lit le code source, calcule l'adresse de chaque ligne (en tenant compte de la taille des instructions et des directives `.org`, `.align`, `.tryte`, `.word`), et construit la **table des symboles** qui associe chaque label défini à son adresse.
*   **Passe 2 :** Relit le code source (ou la représentation intermédiaire), utilise la table des symboles pour résoudre les références aux labels (calculer les offsets pour `JAL`), puis **encode** chaque instruction en sa représentation ternaire de 12 trits et génère les données pour les directives `.tryte`/`.word`.

**Deliverables:**
*   Un nouveau crate Rust `prismchrono_asm` dans le dépôt.
*   Un exécutable `prismchrono_asm` (via `cargo build --release`).
*   Capacité à générer un fichier `.tobj` (format texte, ex: `0000: ZZZ ZZZ ZZZ ZZZ # NOP`) à partir d'un fichier `.s`.
*   Tests unitaires (`cargo test`) pour le lexer, le parser (syntaxe de base), la table des symboles, et l'encodage des instructions/directives ciblées.
*   Exemples `prismchrono_asm/examples/*.s` (ex: `halt.s`, `addi_lui.s`, `jump_loop.s`).
*   Documentation `prismchrono_asm/README.md` (utilisation, syntaxe supportée, format `.tobj`).

**Acceptance Criteria (DoD - Definition of Done):**
*   `cargo build --release` et `cargo test` réussissent dans `prismchrono_asm`.
*   `prismchrono_asm examples/some_example.s -o output.tobj` fonctionne sans erreur pour les exemples valides.
*   **Parsing :** Reconnaissance correcte des labels (`label:`), commentaires (`#`), directives (`.org`, `.tryte`, `.word`, `.align`), instructions ciblées (`NOP`, `HALT`, `ADDI`, `LUI`, `JAL`), registres (`R0`-`R7`), nombres (décimal et potentiellement ternaire `T_PZN`), et labels dans les opérandes.
*   **Passe 1 :** Adresses correctement calculées, table des symboles correctement remplie. Gestion des `.org` et `.align`.
*   **Passe 2 :** Références avant aux labels résolues. Offset pour `JAL` correctement calculé (`(target_addr - pc_apres_jal) / 4`).
*   **Encodage :** Les instructions `NOP`, `HALT`, `ADDI`, `LUI`, `JAL` génèrent les séquences de 12 trits **conformes** à l'ISA PrismChrono (Sprint 5). Les valeurs pour `.tryte` (1 tryte) et `.word` (8 trytes, Little Endian) sont correctement générées.
*   **Sortie :** Le fichier `.tobj` texte est généré, lisible, et représente fidèlement le code machine et les données (avec adresses).
*   **Erreurs :** Messages d'erreur basiques mais clairs pour syntaxe invalide, label non défini, opérande incorrect (avec numéro de ligne).
*   **Validation :** Les exemples `.s` s'assemblent, et le `.tobj` produit est valide (vérifiable manuellement et/ou via une fonction de chargement basique dans `prismchrono_sim`).

**Structure Cible du Crate `prismchrono_asm` :**
*(Basée sur la structure de `prismchrono_sim` et les besoins d'un assembleur)*

```
prismchrono_asm/
├── Cargo.toml
├── examples/
│   ├── halt.s
│   ├── addi_lui.s
│   └── jump_loop.s
├── README.md
└── src/
    ├── main.rs         # CLI, orchestration
    ├── core_types.rs   # Copie/Lien depuis ../prismchrono_sim/src/core/types.rs
    ├── error.rs        # Définition des erreurs (ParseError, SymbolError, EncodeError)
    ├── lexer.rs        # Tokenisation du source .s -> Vec<Token>
    ├── parser.rs       # Analyse des tokens -> Représentation Intermédiaire (AST ou Vec<Statement>)
    ├── ast.rs          # (Optionnel mais recommandé) Définition des noeuds AST (InstructionNode, DirectiveNode, etc.)
    ├── symbol.rs       # Struct SymbolTable, gestion des labels
    ├── assembler.rs    # Contient la logique principale des deux passes
    │                   # (Alternative: pass1.rs, pass2.rs)
    ├── encoder.rs      # Fonctions pour encoder instructions/directives -> [Trit; 12] / Vec<Tryte>
    ├── operand.rs      # Parsing et validation des opérandes (registres, immédiats, labels)
    └── output.rs       # Formatage et écriture du fichier .tobj
    └── tests/          # Tests unitaires et d'intégration
        ├── mod.rs
        ├── parser_tests.rs
        └── encoder_tests.rs
        └── ...
```
*   *(Décision Task 10.1)* : **Copier `types.rs`** dans `prismchrono_asm/src/core_types.rs` pour l'instant afin de découpler les crates pendant le développement initial. Un refactoring vers un `prismchrono_core` commun pourra être fait plus tard.

**Tasks (Détaillées):**

*   **[10.1] Setup Projet & Types:** Créer `prismchrono_asm`, copier `types.rs`, créer la structure des modules.
*   **[10.2] Lexer:** Implémenter `lexer.rs` pour tokeniser les lignes (`Token::Mnemonic`, `Token::Register`, `Token::Number`, `Token::LabelDef`, `Token::LabelRef`, `Token::Directive`, etc.). Gérer les commentaires, espaces, nombres décimaux.
*   **[10.3] Parser & AST:** Définir l'AST dans `ast.rs`. Implémenter `parser.rs` pour convertir `Vec<Token>` en `Vec<AstNode>`. Reconnaître la syntaxe des instructions/directives ciblées.
*   **[10.4] Symbol Table:** Implémenter `symbol.rs` avec `HashMap<String, Address>`. Fonctions `define`/`resolve`. Gestion erreurs (redéfinition).
*   **[10.5] Passe 1:** Dans `assembler.rs` (ou `pass1.rs`), implémenter la fonction `run_pass1(nodes: &[AstNode]) -> Result<SymbolTable, Pass1Error>`. Calculer adresses, gérer `.org`/`.align`, remplir la table des symboles.
*   **[10.6] Encodage Données:** Dans `encoder.rs`, fonctions pour `.tryte` (valeur -> `Tryte`), `.word` (valeur -> `[Tryte; 8]` Little Endian). Gérer la conversion décimal -> ternaire.
*   **[10.7] Encodage Instructions (Helpers):** Dans `encoder.rs`, fonctions `assemble_i_format`, `assemble_u_format`, `assemble_j_format` prenant les champs décodés et retournant `Result<[Trit; 12], EncodeError>`. Utiliser les constantes OpCode/etc. (à définir dans `isa_defs.rs`?).
*   **[10.8] Encodage Instructions (Spécifiques):** Implémenter `encode_nop`, `encode_halt`, `encode_addi`, `encode_lui`, `encode_jal` en appelant les helpers avec les bons paramètres. Pour `JAL`, calculer l'offset relatif `(target_addr - (current_addr + 4)) / 4` et vérifier la plage 7 trits signés.
*   **[10.9] Passe 2:** Dans `assembler.rs` (ou `pass2.rs`), implémenter `run_pass2(nodes: &[AstNode], symbols: &SymbolTable) -> Result<Vec<(Address, EncodedData)>, Pass2Error>`. Itérer, résoudre labels, appeler encodeurs, collecter les données encodées avec leur adresse. `EncodedData` peut être `Instruction([Trit; 12])` ou `Data(Vec<Tryte>)`.
*   **[10.10] Output & CLI:** Dans `output.rs`, fonction `write_tobj`. Dans `main.rs`, utiliser `clap` pour CLI, orchestrer les passes, appeler `write_tobj`.
*   **[10.11] Erreurs:** Définir les `enum` d'erreurs dans `error.rs`. Propager les `Result`. Afficher des messages formatés avec ligne/contexte.
*   **[10.12] Tests & Exemples:** Écrire des tests unitaires (`src/tests/`) pour parser, encoder, résoudre. Créer les fichiers `.s` dans `examples/`. Ajouter un test d'intégration qui assemble un exemple et compare la sortie à une référence.

**Risks & Mitigation:** (Identiques, mais s'appliquent maintenant à `prismchrono_asm`)

**Notes:**
*   Ce sprint est la pierre angulaire pour utiliser `prismchrono_sim` de manière productive.
*   Focus sur la correction du mécanisme de base (2 passes, encodage simple) plutôt que sur des fonctionnalités avancées ou des optimisations.

**AIDEX Integration Potential:** (Identique, adapté au contexte de l'assembleur)
```