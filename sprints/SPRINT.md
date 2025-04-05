# Projet : Simulateur pour l'Architecture 🏳️‍🌈 LGBT+ (Ternaire Base 24, 24t/16MTr)
# Fichier : SPRINT.md

**Objectif Général :** Développer un simulateur fonctionnel en Rust pour l'architecture LGBT+ définie (Phases 1-3), capable de charger et d'exécuter du code machine, ainsi qu'un assembleur basique pour générer ce code.

**Méthodologie :** Développement Itératif par Sprints, avec assistance potentielle via AIDEX (AI-Driven Engineering eXperience). Chaque sprint vise un objectif spécifique et produit un résultat testable.

---

## Sprint 0 : Fondations et Configuration (Terminé)

*   **Objectif :** Mettre en place l'environnement de développement, définir les types de données fondamentaux.
*   **Tâches Clés :**
    *   ✅ Initialiser le projet Rust avec `cargo new`.
    *   ✅ Mettre en place le versionnage avec `git`.
    *   ✅ Définir les types `Trit`, `Tryte`, `Word` (24 trits), `Address` (16 trits) dans `src/core/types.rs`.
    *   ✅ Définir les états spéciaux (`UNDEF`, `NULL`, `NaN`) dans `Tryte`.
    *   ✅ Assurer la compilation initiale et la visibilité des types (`pub`).
    *   ✅ Créer le module `core` et configurer `src/core/mod.rs`.
    *   ✅ Ajouter des tests unitaires de base pour les conversions `Trit`/`Tryte`.
*   **Definition of Done (DoD) :** Le projet compile. Les types de base sont définis et accessibles. Les tests unitaires pour les types passent.
*   **Intégration AIDEX :** Assistance pour la syntaxe Rust, suggestions de design pour les enums/structs, génération de code boilerplate pour les tests.

---

## Sprint 1 : Sous-système Mémoire (Terminé)

*   **Objectif :** Implémenter la mémoire principale simulée (16 MTrytes) avec des accès sûrs.
*   **Tâches Clés :**
    *   ✅ Créer le module `memory` (`src/memory.rs`).
    *   ✅ Définir `enum MemoryError { OutOfBounds, Misaligned }`.
    *   ✅ Implémenter `struct Memory { trytes: Vec<Tryte> }`.
    *   ✅ Implémenter `Memory::new()` et `Memory::with_size()` (initialisation à `Tryte::Undefined`).
    *   ✅ Implémenter `Memory::size()`.
    *   ✅ Implémenter `read_tryte` and `write_tryte` avec vérification des limites (`Result`).
    *   ✅ Implémenter `read_word` et `write_word` (pour mots 24t / 8 trytes) avec vérification des limites ET de l'alignement (adresses multiples de 8). Gérer l'endianness (Little-Endian).
    *   ✅ Écrire des tests unitaires exhaustifs pour toutes les fonctions de `Memory`, couvrant les cas nominaux, les erreurs (limites, alignement) et l'endianness.
*   **Definition of Done (DoD) :** Le module `memory` compile. Toutes les fonctions d'accès mémoire sont implémentées et passent les tests unitaires. Le `main.rs` peut créer et interagir basiquement avec la mémoire.
*   **Intégration AIDEX :** Aide à l'implémentation de la logique d'alignement et de gestion des limites, suggestions pour des cas de test mémoire.

---

## Sprint 2 : État du Processeur (Registres) (Terminé)

*   **Objectif :** Définir et implémenter les structures représentant l'état interne du CPU.
*   **Tâches Clés :**
    *   ✅ Créer le module `cpu` (`src/cpu/mod.rs`).
    *   ✅ Créer `src/cpu/registers.rs`.
    *   ✅ Définir `struct Flags { zf: bool, sf: bool, xf: bool }` (ou équivalent ternaire).
    *   ✅ Définir `enum Register { R0, ..., R7 }` avec des méthodes de conversion vers/depuis `usize`.
    *   ✅ Définir `enum RegisterError { InvalidIndex }`.
    *   ✅ Définir `struct ProcessorState { gpr: [Word; 8], pc: Word, sp: Word, fr: Flags }`.
    *   ✅ Implémenter `ProcessorState::new()` avec des valeurs d'initialisation par défaut (ex: PC=0, SP=MAX_ADDRESS, GPR=Undefined, Flags=0).
    *   ✅ Implémenter les méthodes `read_gpr`, `write_gpr`, `read_pc`, `write_pc`, `read_sp`, `write_sp`, `read_flags`, `write_flags` sur `ProcessorState`, retournant des `Result` si applicable.
    *   ✅ Écrire des tests unitaires pour vérifier l'initialisation et l'accès aux registres.
*   **Definition of Done (DoD) :** Le module `cpu::registers` compile. La structure `ProcessorState` peut être créée et ses composants (GPR, PC, SP, FR) peuvent être lus et écrits via les méthodes définies. Les tests unitaires passent.
*   **Intégration AIDEX :** Génération de code pour les méthodes d'accès aux registres, suggestions pour la représentation des `Flags`.

---

## Sprint 3 : ALU - Opérations Logiques & Préparation Arithmétique (Terminé)

*   **Objectif :** Implémenter les opérations logiques de l'ALU et l'additionneur 1-trit.
*   **Tâches Clés :**
    *   ✅ Créer `src/alu.rs`.
    *   ✅ Implémenter les opérations logiques sur `Word` (24 trits) :
        *   ✅ `trit_inv_word(a: Word) -> Word`
        *   ✅ `trit_min_word(a: Word, b: Word) -> Word`
        *   ✅ `trit_max_word(a: Word, b: Word) -> Word`
    *   ✅ Implémenter l'additionneur complet 1-trit : `ternary_full_adder(a: Trit, b: Trit, cin: Trit) -> (Trit, Trit)` (sum, cout).
    *   ✅ Écrire des tests unitaires **exhaustifs** pour ces fonctions logiques et le TFA. Tester avec divers motifs de trits et états spéciaux (propagation).
*   **Definition of Done (DoD) :** Les fonctions logiques de l'ALU et le TFA sont implémentés et passent tous les tests unitaires.
*   **Intégration AIDEX :** Aide à l'implémentation de la logique trit-à-trit sur les mots, génération de cas de test pour le TFA et les opérations logiques.

---

## Sprint 4 : ALU - Opérations Arithmétiques (24 Trits) (Terminé)

*   **Objectif :** Implémenter l'addition et la soustraction 24 trits.
*   **Tâches Clés :**
    *   ✅ Implémenter l'additionneur 24 trits (ex: ripple carry) en utilisant le TFA :
        *   ✅ `add_24_trits(a: Word, b: Word, cin: Trit) -> (Word, Trit, Flags)` (result, cout, flags Z/S/X/O).
        *   ✅ Gérer la propagation des états spéciaux (`NaN`, `NULL`, `UNDEF`) selon les règles définies.
        *   ✅ Calculer correctement les flags ZF, SF, XF, CF (cout), OF (overflow signé).
    *   ✅ Implémenter la soustraction 24 trits :
        *   ✅ `sub_24_trits(a: Word, b: Word, bin: Trit) -> (Word, Trit, Flags)` (result, bout, flags Z/S/X/O) en utilisant `add_24_trits` et `trit_inv_word`.
    *   ✅ Implémenter la comparaison :
        *   ✅ `compare_24_trits(a: Word, b: Word) -> Flags` (effectue une soustraction interne, retourne les flags).
    *   ✅ Écrire des tests unitaires **très intensifs** pour ADD, SUB, CMP. Couvrir les cas simples, les retenues/emprunts, les limites (max/min), l'overflow, et la gestion des états spéciaux. Vérifier la correction de tous les flags.
*   **Definition of Done (DoD) :** Les fonctions ADD, SUB, CMP 24 trits sont implémentées et passent tous les tests unitaires. La gestion des flags et des états spéciaux est correcte.
*   **Intégration AIDEX :** Suggestions pour l'implémentation de l'additionneur N-trits, aide à la logique de détection d'overflow ternaire, génération de nombreux cas de test arithmétiques.

---

## Sprint 5 : ISA - Formalisation et Décodeur (Terminé)

*   **Objectif :** Finaliser la définition de l'ISA 12 trits et implémenter le décodeur d'instructions.
*   **Tâches Clés :**
    *   ✅ Créer `src/cpu/isa.rs`.
    *   ✅ Documenter précisément les formats d'instruction (R, I, S, B, U, J) sur 12 trits.
    *   ✅ Attribuer des valeurs ternaires spécifiques aux OpCodes, Funcs, Conds.
    *   ✅ Définir les `enum` Rust `Register`, `AluOp`, `Cond`, `Instruction`.
    *   ✅ Créer `src/cpu/decode.rs`.
    *   ✅ Implémenter la fonction `decode(instr_bits: [Trit; 12]) -> Result<Instruction, DecodeError>`. Utiliser des conversions pour extraire les champs et construire l'`Instruction`.
    *   ✅ Définir `enum DecodeError { InvalidOpcode, InvalidFormat, InvalidRegister, InvalidAluOp, InvalidCondition, InvalidInstruction }`.
    *   ✅ Écrire des tests unitaires pour `decode`, en lui fournissant des séquences de 12 trits connues et en vérifiant que la bonne `Instruction` est produite. Tester les cas d'erreur.
*   **Definition of Done (DoD) :** L'ISA est documentée. Les enums `Instruction`, etc. sont définis. La fonction `decode` est implémentée et passe les tests unitaires pour les instructions définies.
*   **Intégration AIDEX :** Aide à la conception des formats ternaires, génération du code boilerplate pour les enums et la fonction `decode` (structure de `match`), suggestions de tests pour le décodeur.

---

## Sprint 6 : CPU Core - Cycle Fetch & Exécution (Base) (Terminé)

*   **Objectif :** Mettre en place la boucle principale Fetch-Decode-Execute et exécuter quelques instructions très simples.
*   **Tâches Clés :**
    *   ✅ Créer `src/cpu/mod.rs` et `src/cpu/execute_core.rs`.
    *   ✅ Définir `struct Cpu { state: ProcessorState, memory: Memory, halted: bool }`.
    *   ✅ Implémenter la fonction `Cpu::fetch() -> Result<[Trit; 12], FetchError>` (lit 4 trytes à `state.pc`, gère erreurs mémoire).
    *   ✅ Implémenter la fonction principale `Cpu::step()` :
        1.  ✅ Appelle `fetch()`.
        2.  ✅ Appelle `decode()` sur les trits récupérés.
        3.  ✅ Appelle `execute()` (voir tâche suivante) sur l'instruction décodée.
        4.  ✅ Met à jour `state.pc` (typiquement `pc + 4`, sauf si modifié par `execute`).
    *   ✅ Implémenter une première version de `Cpu::execute(instr: Instruction) -> Result<(), ExecuteError>` avec un `match` sur `instr` :
        *   ✅ Implémenter **uniquement** les cas pour `Instruction::Nop` et `Instruction::Halt`.
        *   ✅ Les autres branches retournent une erreur `ExecuteError::Unimplemented`.
    *   ✅ Ajouter une boucle `run()` dans `main.rs` ou `Cpu` qui appelle `step()` jusqu'à `Halt` ou erreur.
    *   ✅ Préparer un petit programme machine (séquence de trits/trytes) contenant `NOP` et `HALT` à charger manuellement dans la mémoire pour tester (implémenté dans `src/bin/test_cpu.rs`).
*   **Definition of Done (DoD) :** Le simulateur peut charger un code machine minimal, exécuter `NOP` (sans rien faire sauf incrémenter PC) et s'arrêter correctement sur `HALT`.
*   **Intégration AIDEX :** Génération de la structure de la boucle `step()`, du `match` pour `execute()`.

---

## Sprint 7 : Instructions Load/Store (Terminé)

*   **Objectif :** Implémenter les instructions de chargement et stockage mémoire (Format I et S).
*   **Tâches Clés :**
    *   ✅ Implémenter l'exécution pour `LOADW Rd, imm(Rs1)` (chargement d'un mot de 24 trits).
        *   ✅ Vérifier l'alignement de l'adresse (multiple de 8).
        *   ✅ Gérer les erreurs d'accès mémoire (OutOfBounds, Misaligned).
        *   ✅ Utiliser le mode d'adressage Base+Offset : `Rd <- Mem[Rs1 + SignExtend(imm)]`.
    *   ✅ Implémenter l'exécution pour `STOREW Rs1, Src, offset` (stockage d'un mot de 24 trits).
        *   ✅ Vérifier l'alignement de l'adresse (multiple de 8).
        *   ✅ Gérer les erreurs d'accès mémoire.
        *   ✅ Utiliser le mode d'adressage Base+Offset : `Mem[Rs1 + SignExtend(offset)] <- Src`.
    *   ✅ Implémenter l'exécution pour `LOADT Rd, imm(Rs1)` (chargement d'un tryte avec extension de signe).
        *   ✅ Charger un seul tryte et étendre son signe sur 24 trits.
    *   ✅ Implémenter l'exécution pour `LOADTU Rd, imm(Rs1)` (chargement d'un tryte sans extension de signe).
        *   ✅ Charger un seul tryte et étendre avec des zéros.
    *   ✅ Implémenter l'exécution pour `STORET Rs1, Src, offset` (stockage d'un tryte).
        *   ✅ Stocker uniquement le tryte de poids faible du registre source.
    *   ✅ Implémenter l'exécution pour `LUI Rd, imm` (Load Upper Immediate).
        *   ✅ Placer l'immédiat dans les trits supérieurs du registre destination.
    *   ✅ Gérer correctement les interactions avec `Memory` et `ProcessorState`.
    *   ✅ Écrire des tests unitaires pour chaque instruction, couvrant les cas normaux et les cas d'erreur.
    *   ✅ Créer des programmes machine dédiés pour tester ces instructions (implémenté dans `src/bin/test_load_store.rs`).
*   **Definition of Done (DoD) :** Les instructions de chargement et stockage sont implémentées et passent tous les tests unitaires. Des programmes de test simples peuvent être exécutés correctement.
*   **Intégration AIDEX :** Aide à l'implémentation de la logique d'exécution pour les instructions de chargement/stockage, génération de programmes de test.

---

## Sprint 8 : Instructions ALU (Terminé)

*   **Objectif :** Implémenter les instructions arithmétiques et logiques (Formats R et I).
*   **Tâches Clés :**
    *   ✅ Implémenter les instructions de format R (registre-registre) :
        *   ✅ `ADD Rd, Rs1, Rs2` : `Rd <- Rs1 + Rs2` (Addition 24t).
        *   ✅ `SUB Rd, Rs1, Rs2` : `Rd <- Rs1 - Rs2` (Soustraction 24t).
        *   ✅ `MIN Rd, Rs1, Rs2` : `Rd <- TRIT_MIN(Rs1, Rs2)` (Logique trit-à-trit).
        *   ✅ `MAX Rd, Rs1, Rs2` : `Rd <- TRIT_MAX(Rs1, Rs2)` (Logique trit-à-trit).
        *   ✅ `INV Rd, Rs1` : `Rd <- TRIT_INV(Rs1)` (Logique trit-à-trit).
        *   ✅ `SLT Rd, Rs1, Rs2` : `Rd <- (Rs1 < Rs2) ? 1 : 0` (Set if Less Than, signé).
        *   ✅ `CMP Rs1, Rs2` : Met à jour FR sans écrire dans Rd.
    *   ✅ Implémenter les instructions de format I (registre-immédiat) :
        *   ✅ `ADDI Rd, Rs1, imm` : `Rd <- Rs1 + SignExtend(imm)`.
        *   ✅ `SUBI Rd, Rs1, imm` : `Rd <- Rs1 - SignExtend(imm)`.
        *   ✅ `MINI Rd, Rs1, imm` : `Rd <- TRIT_MIN(Rs1, SignExtend(imm))`.
        *   ✅ `MAXI Rd, Rs1, imm` : `Rd <- TRIT_MAX(Rs1, SignExtend(imm))`.
        *   ✅ `SLTI Rd, Rs1, imm` : `Rd <- (Rs1 < SignExtend(imm)) ? 1 : 0`.
    *   ✅ Appeler correctement les fonctions de l'ALU (`add_24_trits`, `sub_24_trits`, etc.).
    *   ✅ Mettre à jour les flags (ZF, SF, XF) après chaque opération.
    *   ✅ Gérer correctement la propagation des états spéciaux (`NaN`, `NULL`, `UNDEF`).
    *   ✅ Écrire des tests unitaires pour chaque instruction, couvrant les cas normaux, limites et spéciaux.
    *   ✅ Créer des programmes machine dédiés pour tester ces instructions.
*   **Definition of Done (DoD) :** Les instructions ALU sont implémentées et passent tous les tests unitaires. Des programmes de test simples peuvent être exécutés correctement.
*   **Intégration AIDEX :** Aide à l'implémentation de la logique d'exécution pour les instructions ALU, génération de programmes de test.

---

## Sprint 9 : Instructions de Contrôle de Flux (En cours)

*   **Objectif :** Implémenter les instructions de saut et de branchement (Formats J et B).
*   **Tâches Clés :**
    *   ✅ Implémenter les instructions de saut inconditionnel (Format J) :
        *   ✅ `JAL Rd, offset` : `Rd <- PC + 4; PC <- PC + SignExtend(offset) * 4`.
            *   ✅ Saut relatif au PC avec stockage de l'adresse de retour.
            *   ✅ Si `Rd = R0`, le retour n'est pas stocké (simple JMP).
    *   ✅ Implémenter les instructions de saut indirect :
        *   ✅ `JALR Rd, imm(Rs1)` : `temp <- PC + 4; PC <- (Rs1 + SignExtend(imm)) & ~1; Rd <- temp`.
            *   ✅ Saut à une adresse calculée à partir d'un registre.
            *   ✅ L'adresse cible doit être alignée.
    *   ⏳ Implémenter les instructions de branchement conditionnel (Format B) :
        *   ✅ `BRANCH cond, offset` : `if (condition(FR) == true) PC <- PC + SignExtend(offset) * 4`.
        *   ✅ Implémenter les conditions basées sur les flags :
            *   ✅ `EQ` (ZF=1) : Égalité.
            *   ✅ `NE` (ZF=0) : Non-égalité.
            *   ✅ `LT` (SF=1) : Inférieur à.
            *   ✅ `GE` (SF=0 ou ZF=1) : Supérieur ou égal à.
            *   ✅ `XS` (XF=1) : État spécial.
            *   ✅ `XN` (XF=0) : État normal.
    *   ⏳ Gérer correctement la modification du PC et les calculs d'adresse cible.
    *   ⏳ Vérifier l'alignement des adresses cibles (multiple de 4 trytes).
    *   ⏳ Écrire des tests unitaires pour chaque instruction et chaque condition.
    *   ⏳ Créer des programmes machine dédiés pour tester ces instructions, incluant :
        *   Sauts simples.
        *   Appels de sous-routines avec retour.
        *   Boucles conditionnelles.
        *   Structures de contrôle (if-then-else).
*   **Definition of Done (DoD) :** Les instructions de contrôle de flux sont implémentées et passent tous les tests unitaires. Des programmes de test simples avec des boucles et des sauts peuvent être exécutés correctement.
*   **Intégration AIDEX :** Aide à l'implémentation de la logique d'exécution pour les instructions de contrôle de flux, génération de programmes de test.

---

## Sprint 10 : Assembleur - Base (À venir)

*   **Objectif :** Créer un assembleur basique pour l'architecture LGBT+ capable de traduire du code assembleur en code machine ternaire.
*   **Tâches Clés :**
    *   Créer le projet `lgbt_asm` avec la structure de base :
        *   `src/main.rs` : Point d'entrée et gestion des arguments.
        *   `src/parser.rs` : Analyse syntaxique du code assembleur.
        *   `src/symbol.rs` : Gestion de la table des symboles.
        *   `src/encoder.rs` : Encodage des instructions en code machine ternaire.
        *   `src/error.rs` : Gestion des erreurs avec messages clairs.
    *   Implémenter le parsing basique du code assembleur :
        *   Tokenisation des lignes d'assembleur.
        *   Reconnaissance des mnémoniques d'instructions.
        *   Parsing des opérandes (registres, immédiats, labels).
        *   Gestion des commentaires et des lignes vides.
    *   Supporter les labels et leur résolution :
        *   Définition de labels (ex: `loop:`).
        *   Référencement de labels dans les instructions (ex: `JAL R1, loop`).
    *   Supporter les directives d'assemblage :
        *   `.org <addr>` : Définit l'adresse de début du code suivant.
        *   `.tryte <value>` : Insère un tryte avec la valeur spécifiée.
        *   `.word <value>` : Insère un mot (24 trits) avec la valeur spécifiée.
        *   `.align <n>` : Aligne le compteur d'emplacement sur un multiple de n.
    *   Implémenter la table des symboles (passe 1) :
        *   Collecter tous les labels et leur adresse.
        *   Gérer les références avant et arrière.
    *   Implémenter l'encodage pour les instructions de base :
        *   `NOP` : No Operation.
        *   `HALT` : Arrêt du simulateur.
        *   `ADDI Rd, Rs1, imm` : Addition avec immédiat.
        *   `LUI Rd, imm` : Load Upper Immediate.
        *   `JAL Rd, offset` : Jump And Link.
    *   Générer un fichier de sortie utilisable par le simulateur :
        *   Format texte lisible pour le débogage (représentation des trits).
        *   Format binaire compact pour l'exécution.
    *   Écrire des tests unitaires pour chaque composant de l'assembleur.
    *   Créer des programmes d'exemple simples pour tester l'assembleur.
*   **Definition of Done (DoD) :** L'assembleur peut parser du code assembleur simple, résoudre les labels, et générer un fichier binaire/texte utilisable par le simulateur. Les tests unitaires passent et les programmes d'exemple s'assemblent correctement.
*   **Intégration AIDEX :** Aide à l'implémentation du parsing et de la logique de l'assembleur, génération de code assembleur de test.

---

## Sprint 11 : Assembleur - Complet (À venir)

*   **Objectif :** Compléter l'assembleur pour supporter toutes les instructions et fonctionnalités définies dans l'ISA LGBT+ v1.0.
*   **Tâches Clés :**
    *   Ajouter le support pour toutes les instructions des formats :
        *   Format R : `ADD`, `SUB`, `MIN`, `MAX`, `INV`, `SLT`, `CMP`.
        *   Format I : `ADDI`, `SUBI`, `MINI`, `MAXI`, `SLTI`, `LOADW`, `LOADT`, `LOADTU`, `JALR`.
        *   Format S : `STOREW`, `STORET`.
        *   Format B : `BRANCH` avec toutes les conditions (`EQ`, `NE`, `LT`, `GE`, `XS`, `XN`, etc.).
        *   Format U : `LUI`.
        *   Format J : `JAL`.
    *   Implémenter le calcul précis des offsets pour sauts et branches (passe 2) :
        *   Calcul des déplacements relatifs pour `JAL` et `BRANCH`.
        *   Vérification des limites des offsets (plage valide).
        *   Alignement des adresses cibles.
    *   Améliorer la gestion des erreurs :
        *   Messages d'erreur détaillés avec numéro de ligne et contexte.
        *   Détection des erreurs syntaxiques et sémantiques.
        *   Vérification des types d'opérandes et des plages de valeurs.
        *   Rapport d'erreurs multiples avant l'arrêt.
    *   Ajouter des fonctionnalités avancées :
        *   Expressions constantes (ex: `ADDI R1, R0, 5+3`).
        *   Macros simples pour les séquences d'instructions courantes.
        *   Inclusion de fichiers (`.include "file.s"`).
        *   Sections de données et de code (`.data`, `.text`).
    *   Optimiser le format de sortie pour une meilleure intégration avec le simulateur :
        *   Format binaire efficace pour le chargement rapide.
        *   Informations de débogage (mapping adresses/lignes source).
        *   Table des symboles exportée pour le débogage.
    *   Écrire des tests unitaires exhaustifs pour toutes les fonctionnalités.
    *   Créer des programmes assembleur plus complexes pour tester l'assembleur :
        *   Algorithmes mathématiques (factorielle, fibonacci).
        *   Manipulation de tableaux et de structures de données.
        *   Sous-routines avec conventions d'appel.
*   **Definition of Done (DoD) :** L'assembleur supporte toutes les instructions et fonctionnalités définies dans l'ISA. Des programmes assembleur complexes peuvent être assemblés et exécutés correctement sur le simulateur. La gestion des erreurs est robuste et les messages sont clairs.
*   **Intégration AIDEX :** Aide à l'implémentation des fonctionnalités avancées de l'assembleur, génération de programmes assembleur de test plus complexes.

---

## Sprint 12 : Intégration et Tests End-to-End (À venir)

*   **Objectif :** Tester le système complet (Assembleur -> Simulateur) avec des programmes complexes et mettre en place un workflow de développement fluide.
*   **Tâches Clés :**
    *   Écrire une suite de programmes de test significatifs en assembleur LGBT+ :
        *   **Algorithmes mathématiques :**
            *   Calcul de factorielle (récursif et itératif).
            *   Suite de Fibonacci.
            *   Calcul du PGCD (algorithme d'Euclide).
        *   **Manipulation de données :**
            *   Copie de blocs mémoire.
            *   Recherche dans un tableau.
            *   Tri de tableau (insertion, sélection).
        *   **Structures de contrôle :**
            *   Boucles imbriquées.
            *   Appels de fonctions récursifs.
            *   Structures conditionnelles complexes.
    *   Créer un workflow de développement complet :
        *   Script d'assemblage et de chargement automatisé.
        *   Intégration de l'assembleur et du simulateur.
        *   Outils de validation des résultats.
    *   Améliorer les capacités d'inspection et de débogage du simulateur :
        *   Affichage de l'état des registres et des flags.
        *   Inspection de la mémoire à des adresses spécifiques.
        *   Exécution pas à pas des instructions.
        *   Points d'arrêt conditionnels.
        *   Traçage de l'exécution.
    *   Tester le système complet :
        *   Assembler les programmes avec `lgbt_asm`.
        *   Charger et exécuter les programmes sur `lgbt_sim`.
        *   Vérifier les résultats en mémoire et dans les registres.
    *   Mesurer les performances :
        *   Nombre d'instructions par seconde.
        *   Efficacité de l'encodage des instructions.
        *   Utilisation de la mémoire.
    *   Corriger les bugs découverts lors de l'intégration.
    *   Documenter le processus complet de développement et d'exécution de programmes.
*   **Definition of Done (DoD) :** Plusieurs programmes de test non triviaux s'assemblent et s'exécutent correctement sur le simulateur, produisant les résultats attendus. Le workflow Assembleur -> Simulateur est fonctionnel et bien documenté. Les outils de débogage permettent une analyse efficace de l'exécution.
*   **Intégration AIDEX :** Suggestions pour des programmes de test plus complexes, aide au débogage des problèmes d'intégration, optimisation des performances.

---

## Sprint 13+ : Améliorations et Futures Extensions (À venir)

*   **Objectifs :** Ajouter des fonctionnalités avancées ou améliorer les outils pour une architecture LGBT+ plus complète et performante.
*   **Tâches Possibles :**
    *   **Extensions arithmétiques :**
        *   Implémentation de MUL/DIV en logiciel (via routines appelées par OpCodes dédiés).
        *   Bibliothèque de fonctions mathématiques (racine carrée, puissance, trigonométrie).
        *   Support pour l'arithmétique à virgule fixe ou flottante.
    *   **Améliorations du simulateur :**
        *   Interface graphique pour le débogage et la visualisation.
        *   Visualisation de l'état du processeur en temps réel.
        *   Profiling et analyse de performance.
        *   Mode d'exécution accéléré (JIT ou interprétation optimisée).
    *   **Améliorations de l'assembleur :**
        *   Macros avancées et préprocesseur.
        *   Bibliothèque standard de routines.
        *   Optimisations du code généré.
    *   **Documentation et analyse :**
        *   Documentation détaillée de l'architecture et des outils.
        *   Début de la Phase 5 : Analyse et comparaison avec architectures binaires.
        *   Benchmark de performance et d'efficacité énergétique théorique.
    *   **Extensions architecturales :**
        *   Définition d'une architecture d'E/S (Phase X).
        *   Support des interruptions et exceptions (Phase Y).
        *   Modèle de mémoire virtuelle.
        *   Support multi-cœur théorique.
    *   **Applications :**
        *   Développement d'un petit système d'exploitation.
        *   Implémentation d'un langage de haut niveau compilé pour LGBT+.
        *   Applications de démonstration (jeux simples, traitement de données).
*   **Definition of Done (DoD) :** Variable selon la tâche choisie, mais chaque extension doit être documentée, testée et intégrée harmonieusement avec le système existant.
*   **Intégration AIDEX :** Assistance pour la conception des extensions, génération de code pour les fonctionnalités avancées, aide à l'optimisation et à l'analyse comparative.

---

## Sprint 11 : Implémentation des Instructions Spécialisées LGBT+

*   **Objectif :** Implémenter les instructions spécialisées identifiées dans le sprint 10 pour exploiter pleinement les avantages de l'architecture ternaire LGBT+.
*   **Tâches Clés :**
    *   Mettre à jour l'ISA pour inclure les nouvelles opérations spécialisées :
        *   Logique multi-valuée : `COMPARE3`, `TERNARY_MUX`, `TEST_STATE`
        *   Arithmétique signée symétrique : `ABS`, `SIGNUM`, `CLAMP`
        *   Traitement avec états spéciaux : `IS_SPECIAL_TRYTE`, `CHECKW`, `SELECT_VALID`
        *   Manipulation Base 24 : `EXTRACT_TRYTE`, `INSERT_TRYTE`, `VALIDATE_B24`
        *   Contrôle de flux multi-états : `BRANCH3`, `JUMP_TABLE`
    *   Implémenter les nouvelles instructions dans les fichiers d'exécution :
        *   `execute_alu.rs` pour les instructions ALU spécialisées
        *   `execute_branch.rs` pour les instructions de branchement spécialisées
    *   Mettre à jour le décodeur pour supporter les nouveaux formats d'instructions
    *   Créer des tests unitaires pour valider le fonctionnement des nouvelles instructions
    *   Documenter les nouvelles instructions dans la documentation du projet

## Récapitulatif et Suivi d'Avancement

| Sprint | Titre | État | Progression |
|--------|-------|------|------------|
| 0 | Fondations et Configuration | Terminé | 100% |
| 1 | Sous-système Mémoire | Terminé | 100% |
| 2 | État du Processeur (Registres) | Terminé | 100% |
| 3 | ALU - Opérations Logiques & Préparation Arithmétique | Terminé | 100% |
| 4 | ALU - Opérations Arithmétiques (24 Trits) | Terminé | 100% |
| 5 | ISA - Formalisation et Décodeur | Terminé | 100% |
| 6 | CPU Core - Cycle Fetch & Exécution (Base) | Terminé | 100% |
| 7 | Instructions Load/Store | Terminé | 100% |
| 8 | Instructions ALU | Terminé | 100% |
| 9 | Instructions de Contrôle de Flux | En cours | 80% |
| 10 | Assembleur - Base | À venir | 0% |
| 11 | Assembleur - Complet | À venir | 0% |
| 12 | Intégration et Tests End-to-End | À venir | 0% |
| 13+ | Améliorations et Futures Extensions | À venir | 0% |

---

Ce plan de sprint fournit une feuille de route détaillée. Chaque sprint est une étape concrète vers la réalisation du simulateur complet. N'hésite pas à ajuster la portée ou l'ordre si nécessaire au fur et à mesure de l'avancement !

La progression actuelle montre que les fondations sont en place, le sous-système mémoire est terminé, l'état du processeur est implémenté et l'ALU est complètement fonctionnelle avec toutes les opérations logiques et arithmétiques. L'ISA et le décodeur d'instructions sont entièrement implémentés, et la plupart des instructions (ALU, mémoire, sauts) sont fonctionnelles. Les instructions de branchement conditionnel sont presque terminées (80%). Les prochaines étapes se concentreront sur la finalisation des instructions de contrôle de flux et le développement de l'assembleur (sprints 10 et 11).