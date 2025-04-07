# Sprint 1 VHDL (PrismChrono): Fondations Ternaires, Types et Blocs Arithmétiques de Base

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL` (Dossier Principal)

**Objective:** Établir les fondations indispensables du projet VHDL pour PrismChrono. Cela inclut la définition rigoureuse des **types de données ternaires encodés en binaire**, l'implémentation et la **simulation exhaustive** des **blocs combinatoires ternaires les plus fondamentaux** : l'**inverseur trit-à-trit** et l'**additionneur complet 1-trit (TFA)**. Ce sprint est la pierre angulaire pour toute construction matérielle ultérieure, en particulier l'ALU complexe.

**State:** Not Started

**Priority:** Critique (Bloque tout développement VHDL)

**Estimated Effort:** Medium (ex: 5-8 points, T-shirt M - Courbe d'apprentissage VHDL + logique ternaire simulée)

**Dependencies:**
*   **Décision Finale sur l'Encodage Binaire des Trits :** Confirmer le mapping {N, Z, P} -> 2 bits. Exemple : `N="00", Z="01", P="10"`. Documenter ce choix.
*   **Environnement VHDL Fonctionnel :** GHDL, GTKWave, éditeur VHDL installés et fonctionnels.

**Core Concepts:**
1.  **Package VHDL Centralisé (`prismchrono_types_pkg.vhd`) :** Regrouper toutes les définitions de types et constantes liées à l'architecture ternaire (Trit, Tryte, Word, Address encodés) et potentiellement aux codes d'opération/registres de base.
2.  **Logique Combinatoire VHDL :** Implémenter les fonctions ternaires en utilisant des opérations binaires sur les données encodées. Privilégier la lisibilité et la correction sur l'optimisation à ce stade.
3.  **Testbenches VHDL Exhaustifs :** Valider *chaque* combinaison d'entrée pour les blocs de base afin d'assurer leur correction fonctionnelle parfaite. Utilisation systématique des `assert`.
4.  **Simulation et Visualisation :** Utiliser GHDL et GTKWave comme outils principaux pour la validation et le débogage.

**Visualisation des Modules Cibles :**

```mermaid
graph TD
    subgraph prismchrono_types_pkg.vhd [rtl/pkg/prismchrono_types_pkg.vhd]
        direction LR
        DefTrit[subtype EncodedTrit is<br/>std_logic_vector(1 downto 0)]
        DefConst[constant TRIT_N : EncodedTrit := "00"]
        DefConstZ[constant TRIT_Z : EncodedTrit := "01"]
        DefConstP[constant TRIT_P : EncodedTrit := "10"]
        DefTryte[subtype EncodedTryte is<br/>std_logic_vector(5 downto 0)]
        DefWord[subtype EncodedWord is<br/>std_logic_vector(47 downto 0)]
        DefAddr[subtype EncodedAddress is<br/>std_logic_vector(31 downto 0)]
        FuncToInt[function to_integer(t: EncodedTrit) return integer]
        FuncToTrit[function to_encoded_trit(i: integer) return EncodedTrit]
    end

    subgraph trit_inverter.vhd [rtl/core/trit_inverter.vhd]
        direction LR
        InvIn(Input: EncodedTrit) --> InvLogic{Combinatorial Logic<br/>(N->P, P->N, Z->Z)};
        InvLogic --> InvOut(Output: EncodedTrit);
    end

    subgraph ternary_full_adder_1t.vhd [rtl/core/ternary_full_adder_1t.vhd]
        direction LR
        TFA_InA(A: EncodedTrit) --> TFA_Logic{Combinatorial Logic<br/>Ternary Full Adder<br/>(A+B+Cin = Sum + 3*Cout)};
        TFA_InB(B: EncodedTrit) --> TFA_Logic;
        TFA_Cin(Cin: EncodedTrit) --> TFA_Logic;
        TFA_Logic --> TFA_Sum(Sum: EncodedTrit);
        TFA_Logic --> TFA_Cout(Cout: EncodedTrit);
    end

    DefTrit -- Used by --> InvIn; InvOut; TFA_InA; TFA_InB; TFA_Cin; TFA_Sum; TFA_Cout;
    FuncToInt -- Used by --> TFA_Logic;
    FuncToTrit -- Used by --> TFA_Logic; TFA_Sum; TFA_Cout;

    style prismchrono_types_pkg.vhd fill:#eee,stroke:#333,stroke-width:1px
    style trit_inverter.vhd fill:#ccf,stroke:#333,stroke-width:1px
    style ternary_full_adder_1t.vhd fill:#cfc,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL :**
    *   `rtl/pkg/prismchrono_types_pkg.vhd` : Package complet avec types, constantes, et fonctions de conversion `to_integer`/`to_encoded_trit`.
    *   `rtl/core/trit_inverter.vhd` : Entité et architecture fonctionnelles.
    *   `rtl/core/ternary_full_adder_1t.vhd` : Entité et architecture fonctionnelles (implémentation via conversion recommandée).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_prismchrono_types_pkg.vhd` : (Optionnel mais recommandé) Testbench simple pour valider les fonctions de conversion.
    *   `sim/testbenches/tb_trit_inverter.vhd` : Test exhaustif (N, Z, P) avec assertions.
    *   `sim/testbenches/tb_ternary_full_adder_1t.vhd` : Test exhaustif des 27 combinaisons d'entrées avec assertions pour `sum_out` et `c_out`.
*   **Simulation :**
    *   Scripts (`sim/scripts/`) pour compiler tous les fichiers VHDL et exécuter chaque testbench avec GHDL.
    *   Fichiers VCD (`.vcd`) générés pour chaque testbench.
*   **Documentation :**
    *   `doc/vhdl_encoding_and_types.md` : Documentant l'encodage binaire finalisé et le contenu du package de types.
    *   Mise à jour du `prismChrono_VHDL/README.md`.

**Acceptance Criteria (DoD - Definition of Done):**
*   Tous les fichiers VHDL (`pkg`, `core`, `testbenches`) compilent sans erreur avec `ghdl -a`.
*   L'analyse (`ghdl -a`) et l'élaboration (`ghdl -e`) des 3 testbenches réussissent.
*   L'exécution (`ghdl -r`) des testbenches `tb_trit_inverter` et `tb_ternary_full_adder_1t` se termine **sans aucune erreur d'assertion reportée**.
*   Les fichiers VCD générés sont valides et peuvent être ouverts avec GTKWave.
*   L'inspection manuelle des formes d'onde VCD pour quelques cas de test clés (ex: N+N+N, P+P+P, N+P+Z) confirme le comportement attendu des sorties `sum_out` et `c_out` du TFA et de la sortie de l'inverseur.
*   La documentation sur l'encodage est claire et correspond à l'implémentation.

**Tasks:**

*   **[1.1] Setup Environnement & Projet VHDL:**
    *   Installer GHDL & GTKWave.
    *   Configurer VSCode (ou autre éditeur) pour VHDL.
    *   Créer la structure de dossiers `prismChrono_VHDL/rtl/{pkg,core}`, `sim/{testbenches,scripts}`, `doc`.
    *   Initialiser `git` dans `prismChrono_VHDL`.
*   **[1.2] Package de Types (`prismchrono_types_pkg.vhd`):**
    *   Finaliser l'encodage 2 bits/trit (ex: `N="00", Z="01", P="10"`).
    *   Définir les constantes `TRIT_N`, `TRIT_Z`, `TRIT_P`.
    *   Définir les sous-types `EncodedTrit`, `EncodedTryte`, `EncodedWord`, `EncodedAddress`.
    *   Implémenter et **tester** (via `tb_prismchrono_types_pkg.vhd` optionnel) les fonctions `to_integer(EncodedTrit)` et `to_encoded_trit(integer)`. Gérer le cas de l'encodage inutilisé ("11").
    *   Compiler (`ghdl -a`).
*   **[1.3] Inverseur Ternaire (`trit_inverter.vhd`):**
    *   Écrire l'entité et l'architecture (combinatoire). Utiliser `with`/`select` ou `if`/`elsif` sur l'entrée `EncodedTrit`. Définir le comportement pour l'encodage "11" (ex: sortie "11"?).
    *   Compiler (`ghdl -a`).
*   **[1.4] Testbench Inverseur (`tb_trit_inverter.vhd`):**
    *   Instancier `trit_inverter`.
    *   Créer un process qui pilote l'entrée avec `TRIT_N`, `TRIT_Z`, `TRIT_P`, (et "11").
    *   Utiliser `wait for T;` (ex: 10 ns) entre les changements.
    *   Utiliser `assert output_s = EXPECTED_VALUE report "..." severity error;` pour chaque cas.
    *   Inclure la génération VCD (`--vcd=...`).
    *   Compiler, élaborer, exécuter (`ghdl -a`, `-e`, `-r`). Vérifier assertions et VCD.
*   **[1.5] Additionneur 1-Trit (`ternary_full_adder_1t.vhd`):**
    *   Écrire l'entité (3 entrées, 2 sorties `EncodedTrit`).
    *   Implémenter l'architecture (méthode via conversion `integer` recommandée). Utiliser les fonctions `to_integer`/`to_encoded_trit` du package. Soigner la logique de séparation somme/retenue (voir exemple Sprint précédent).
    *   Compiler (`ghdl -a`).
*   **[1.6] Testbench TFA (`tb_ternary_full_adder_1t.vhd`):**
    *   Instancier `ternary_full_adder_1t`.
    *   Créer un process avec 3 boucles `for` imbriquées (ou génération manuelle) pour couvrir les 27 combinaisons de `a_in`, `b_in`, `c_in` (N, Z, P).
    *   Pour chaque combinaison, déterminer les `sum_expected` et `cout_expected` (basé sur la table de vérité ternaire).
    *   Utiliser `assert (sum_s = sum_expected) and (c_out_s = cout_expected) report "TFA Error: A=" & ... severity error;`.
    *   Inclure la génération VCD.
    *   Compiler, élaborer, exécuter. Vérifier **toutes** les assertions et inspecter quelques cas clés dans GTKWave.
*   **[1.7] Scripts de Simulation:**
    *   Créer `sim/scripts/compile.sh` (fait `ghdl -a` sur tous les `.vhd` dans le bon ordre).
    *   Créer `sim/scripts/simulate.sh <testbench_name> <vcd_filename>` (fait `ghdl -e` et `ghdl -r` avec l'option `--vcd`).
*   **[1.8] Documentation:** Rédiger `doc/vhdl_encoding_and_types.md`. Mettre à jour le README VHDL.

**Risks & Mitigation:**
*   **(Identique)** Courbe apprentissage VHDL. -> **Mitigation:** Commencer simple, tutoriels, GHDL erreurs.
*   **(Identique)** Erreurs logique ternaire (TFA). -> **Mitigation:** Tests exhaustifs, visualisation VCD, double-vérifier table de vérité.
*   **Risque :** Problèmes de configuration GHDL/GTKWave. -> **Mitigation:** Suivre documentation GHDL/GTKWave, tester avec exemples simples fournis par GHDL.

**Notes:**
*   La **rigueur des testbenches** est *essentielle* dans ce sprint. Chaque erreur ici se propagera.
*   L'implémentation du TFA via conversion est **pédagogiquement utile** car elle force à bien comprendre l'arithmétique ternaire équilibrée.
*   Ce sprint établit les **conventions de codage** et la **structure de test** pour le reste du projet VHDL.

**AIDEX Integration Potential:**
*   **(Identique)** Boilerplate VHDL, aide logique INV/TFA, génération cas de tests TFA + assertions, débogage erreurs GHDL, explication concepts VHDL, aide scripts simu.