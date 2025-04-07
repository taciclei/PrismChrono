# Sprint 2 VHDL (PrismChrono): ALU 24 Trits et Banc de Registres

**Nom de Code Projet :** PrismChrono
**Composant :** `prismChrono_VHDL`

**Objective:** Construire et valider en simulation les deux composants majeurs du datapath :
1.  L'**ALU 24 Trits (`alu_24t`)** : Capable d'effectuer les opérations arithmétiques (ADD, SUB) et logiques (TMIN, TMAX, TINV) de base de l'ISA PrismChrono sur des mots ternaires de 24 trits (encodés en 48 bits). Elle utilisera l'additionneur 1-trit (TFA) du Sprint 1 comme brique élémentaire.
2.  Le **Banc de Registres (`register_file`)** : Capable de stocker les 8 registres généraux (R0-R7) de 24 trits (48 bits) et de permettre des lectures (2 ports) et une écriture synchrones.

**State:** Not Started

**Priority:** Critique (Composants centraux du CPU)

**Estimated Effort:** Large (ex: 13-20 points, T-shirt L/XL - Implémentation de l'ALU N-trits et du RegFile, testbenches complexes)

**Dependencies:**
*   **Sprint 1 VHDL Terminé :** Le package `prismchrono_types_pkg.vhd` (avec `EncodedWord`, `EncodedTrit`, etc.) et surtout le module `ternary_full_adder_1t.vhd` sont fonctionnels et validés.
*   **ISA PrismChrono (README Simu / Phase 3) :** Nécessite la définition des opcodes ALU (`AluOpCodeType`?) et la sémantique précise des opérations (ex: comment les flags ZF, SF, OF, CF, XF sont affectés par ADD/SUB).

**Core Concepts:**
1.  **ALU N-Trits (Ripple Carry) :** Construire l'ALU 24 trits en instanciant 24 fois le `ternary_full_adder_1t` pour l'addition/soustraction (propagation de la retenue - "ripple carry"). La logique MIN/MAX/INV s'applique trit-à-trit (donc bit-pair par bit-pair sur l'encodage).
2.  **Calcul des Flags :** Implémenter la logique combinatoire pour calculer les flags (ZF, SF, OF, CF, XF) à partir du résultat de l'ALU et des opérandes.
3.  **Banc de Registres Synchrone :** Utiliser un tableau de `EncodedWord` en VHDL et un `process` sensible à l'horloge pour gérer l'écriture dans le registre sélectionné. Les lectures sont typiquement combinatoires.
4.  **Testbenches Modulaires :** Tester l'ALU et le Banc de Registres séparément avec des testbenches dédiés avant de les intégrer.

**Visualisation des Modules Cibles :**

```mermaid
graph TD
    subgraph alu_24t.vhd [rtl/core/alu_24t.vhd]
        direction LR
        ALU_OpA(OpA: EncodedWord) --> ALU_Logic{ALU Logic (24 Trits)};
        ALU_OpB(OpB: EncodedWord) --> ALU_Logic;
        ALU_OpCode(OpCode: AluOpType) --> ALU_Logic;
        ALU_Cin(Cin: EncodedTrit) --> ALU_Logic;
        ALU_Logic -- Uses x24 --> TFA(ternary_full_adder_1t);
        ALU_Logic --> ALU_Result(Result: EncodedWord);
        ALU_Logic --> ALU_Flags(Flags: FlagBusType);
        ALU_Logic --> ALU_Cout(Cout: EncodedTrit);
    end

    subgraph register_file.vhd [rtl/core/register_file.vhd]
        direction TB
        RF_Clk(Clk) --> RF_WriteLogic{Write Logic (on rising_edge)};
        RF_Rst(Rst) --> RF_WriteLogic;
        RF_WrEn(Write Enable) --> RF_WriteLogic;
        RF_WrAddr(Write Addr [4 bits?]) --> RF_WriteLogic;
        RF_WrData(Write Data: EncodedWord) --> RF_WriteLogic;
        RF_WriteLogic --> RF_Regs[(Internal Array<br/>regs: array(0 to 7) of EncodedWord)];

        RF_RdAddr1(Read Addr 1 [4 bits?]) --> RF_ReadLogic1{Read Port 1 (Combinatorial)};
        RF_Regs --> RF_ReadLogic1;
        RF_ReadLogic1 --> RF_RdData1(Read Data 1: EncodedWord);

        RF_RdAddr2(Read Addr 2 [4 bits?]) --> RF_ReadLogic2{Read Port 2 (Combinatorial)};
        RF_Regs --> RF_ReadLogic2;
        RF_ReadLogic2 --> RF_RdData2(Read Data 2: EncodedWord);
    end

    TFA_Types[prismchrono_types_pkg] --> ALU_OpA; ALU_OpB; ALU_Cin; ALU_Result; ALU_Cout; ALU_OpCode; ALU_Flags;
    TFA_Types --> RF_WrData; RF_RdData1; RF_RdData2; RF_WrAddr; RF_RdAddr1; RF_RdAddr2;

    style alu_24t.vhd fill:#ccf,stroke:#333,stroke-width:1px
    style register_file.vhd fill:#cfc,stroke:#333,stroke-width:1px
```

**Deliverables:**
*   **Code VHDL :**
    *   `rtl/core/alu_24t.vhd` : Entité et architecture ALU 24 trits (ADD, SUB, TMIN, TMAX, TINV, calcul des flags).
    *   `rtl/core/register_file.vhd` : Entité et architecture banc de registres (8 x 24t/48b, 2 read, 1 write sync).
    *   Mise à jour de `rtl/pkg/prismchrono_types_pkg.vhd` pour ajouter les types `AluOpType` (enum ou std_logic_vector pour ADD, SUB, etc.) et `FlagBusType` (structure ou vector pour ZF, SF, OF, CF, XF).
*   **Testbenches VHDL :**
    *   `sim/testbenches/tb_alu_24t.vhd` : Testbench stimulant l'ALU avec diverses opérations, opérandes (zéro, positifs, négatifs, valeurs limites), et vérifiant le résultat et **tous les flags** via `assert`.
    *   `sim/testbenches/tb_register_file.vhd` : Testbench simulant des lectures et écritures synchrones, vérifiant que les données lues correspondent aux données écrites précédemment, testant les lectures simultanées et l'écriture pendant lecture.
*   **Simulation :**
    *   Mise à jour des scripts (`sim/scripts/`) pour compiler et simuler les nouveaux modules.
    *   Fichiers VCD générés pour les deux testbenches.
*   **Documentation :**
    *   `doc/alu_design.md` : Description de l'implémentation de l'ALU 24t et de la logique des flags.
    *   `doc/regfile_design.md` : Description de l'implémentation du banc de registres.
    *   Mise à jour du `README.md` VHDL.

**Acceptance Criteria (DoD - Definition of Done):**
*   Le package de types mis à jour et les entités `alu_24t`, `register_file` compilent sans erreur.
*   Le testbench `tb_alu_24t` s'exécute **sans erreur d'assertion** pour une suite de tests couvrant :
    *   Addition (cas simples, retenues, zéro, négatifs, overflow si OF implémenté).
    *   Soustraction (idem).
    *   TMIN, TMAX, TINV (cas simples).
    *   Vérification systématique des flags ZF, SF, CF (sortie du 24e TFA), OF (si impl.), XF (si la gestion des états spéciaux UNDEF/NaN est déjà incluse dans l'ALU).
*   Le testbench `tb_register_file` s'exécute **sans erreur d'assertion**, validant :
    *   Écriture correcte dans un registre via `write_enable` et `write_addr` au front d'horloge.
    *   Lecture correcte et immédiate (combinatoire) via `read_addr1`/`read_addr2`.
    *   Lecture de la *nouvelle* valeur si lecture et écriture sur la même adresse dans le même cycle (comportement "Read-After-Write" ou "Write-Through" typique).
    *   Lecture correcte sur les deux ports simultanément.
    *   Le reset initialise les registres (à Zéro ou état indéfini?).
*   Les fichiers VCD générés pour `tb_alu_24t` et `tb_register_file` peuvent être ouverts et permettent de vérifier visuellement le comportement sur quelques cycles clés.
*   La documentation de conception pour l'ALU et le RegFile est créée.

**Tasks:**

*   **[2.1] Mise à Jour Types (`prismchrono_types_pkg.vhd`):**
    *   Ajouter `type AluOpType is (OP_ADD, OP_SUB, OP_TMIN, OP_TMAX, OP_TINV, ...);` (ou un `std_logic_vector` avec constantes).
    *   Ajouter `subtype FlagBusType is std_logic_vector(4 downto 0);` avec des constantes pour les indices (ex: `FLAG_Z_IDX : integer := 0; ... FLAG_X_IDX : integer := 4;`). Ou utiliser un `record`.
*   **[2.2] Implémentation ALU 24 Trits (`alu_24t.vhd`):**
    *   Définir l'entité avec les ports `op_a`, `op_b`, `alu_op`, `c_in`, `result`, `flags`, `c_out`.
    *   **Addition/Soustraction :**
        *   Utiliser un `generate` VHDL pour instancier 24 `ternary_full_adder_1t`.
        *   Gérer l'entrée `c_in`.
        *   Pour SUB (A - B), on calcule A + INV(B) + Cin=P. Le `operand_b` doit être inversé (TINV trit-à-trit) et `c_in` doit être forcé à `TRIT_P` *avant* d'entrer dans la chaîne d'additionneurs, lorsque `alu_op` est `OP_SUB`.
        *   Connecter la retenue (`c_out` du TFA `i`) à l'entrée (`c_in` du TFA `i+1`).
        *   Le `c_out` final du 24e TFA est le Carry Flag ternaire (CF).
    *   **Opérations Logiques (TMIN, TMAX, TINV) :**
        *   Implémenter ces opérations trit-à-trit (donc 2 bits par 2 bits) sur les `EncodedWord` `op_a` et `op_b`. Un `generate` ou une boucle `for` dans un `process` peuvent être utilisés.
    *   **Multiplexeur de Résultat :** Utiliser un `case alu_op is ...` pour sélectionner le résultat correct (issu de l'additionneur ou de la logique TMIN/TMAX/TINV) à affecter à la sortie `result`.
    *   **Calcul des Flags (Logique Combinatoire) :**
        *   `ZF`: Vérifier si *tous* les trits (pairs de bits) du `result` sont égaux à `TRIT_Z`.
        *   `SF`: Vérifier le trit le plus significatif (MS T) du `result` (ex: bits 47-46). SF=1 si `TRIT_N`.
        *   `CF`: Sortie `c_out` du 24e TFA (pour ADD/SUB).
        *   `XF`: Logique à définir. Initialement Zéro, ou tester si `result` contient l'encodage "11" ?
        *   `OF`: Overflow signé pour ADD/SUB. Logique ternaire spécifique à implémenter (ex: changement de signe inattendu : signe(A)=signe(B) != signe(Result)).
    *   Compiler (`ghdl -a`).
*   **[2.3] Testbench ALU (`tb_alu_24t.vhd`):**
    *   Instancier `alu_24t`.
    *   Créer un process pour générer différentes valeurs pour `op_a`, `op_b`, `alu_op`, `c_in`.
    *   **Couvrir des cas variés :**
        *   ADD/SUB: 0+0, 1+1, N+N, P+N, débordements (max+1, min-1), propagation retenue.
        *   LOGIC: TMIN(P..P, Z..Z), TMAX(N..N, P..P), TINV(P..P), TINV(N..N), TINV(Z..Z).
        *   Aléatoire ou systématique ? Commencer systématique pour les cas clés.
    *   Après chaque jeu d'entrées, `wait for T;` et `assert` sur `result` ET sur **tous les bits de `flags`**.
    *   Générer VCD. Compiler, élaborer, exécuter, vérifier assertions et VCD.
*   **[2.4] Implémentation Banc de Registres (`register_file.vhd`):**
    *   Définir l'entité (ports clk, rst, wr_en, wr_addr, wr_data, rd_addr1, rd_data1, rd_addr2, rd_data2).
    *   Déclarer le tableau interne `signal regs : RegArray(0 to 7) of EncodedWord;`.
    *   **Processus d'Écriture (Synchrone) :**
        ```vhdl
        process(clk, rst)
        begin
            if rst = '1' then
                -- Initialisation au reset (ex: tout à Zéro ?)
                regs <= (others => (others => TRIT_Z(0))); -- Attention syntaxe VHDL pour aggrégat multi-dim
                -- Plus simple: initialiser chaque mot à zéro dans une boucle for.
            elsif rising_edge(clk) then
                if wr_en = '1' then
                    -- Convertir wr_addr (ex: 4 bits) en index entier
                    regs(to_integer(unsigned(wr_addr))) <= wr_data;
                end if;
            end if;
        end process;
        ```
    *   **Logique de Lecture (Combinatoire) :**
        ```vhdl
        rd_data1 <= regs(to_integer(unsigned(rd_addr1)));
        rd_data2 <= regs(to_integer(unsigned(rd_addr2)));
        ```
    *   Compiler (`ghdl -a`).
*   **[2.5] Testbench Banc de Registres (`tb_register_file.vhd`):**
    *   Instancier `register_file`.
    *   Générer `clk` et `rst`.
    *   Créer un process pour piloter `wr_en`, `wr_addr`, `wr_data`, `rd_addr1`, `rd_addr2`.
    *   **Scénario de test :**
        1.  Reset.
        2.  Écrire une valeur V1 dans R1. Attendre un cycle. Lire R1, vérifier V1. Lire R2, vérifier valeur initiale.
        3.  Écrire V2 dans R2. Attendre un cycle. Lire R1, vérifier V1. Lire R2, vérifier V2.
        4.  Dans le même cycle : Écrire V3 dans R3, Lire R3 (port 1), Lire R1 (port 2). Attendre un cycle. Vérifier que ReadData1 a lu l'ancienne valeur de R3 (ou la nouvelle selon la spec VHDL/FPGA) et ReadData2 a lu V1. Lire R3, vérifier V3.
    *   Utiliser `assert` pour toutes les vérifications.
    *   Générer VCD. Compiler, élaborer, exécuter, vérifier assertions et VCD.
*   **[2.6] Scripts & Documentation:** Mettre à jour les scripts de simulation. Rédiger `doc/alu_design.md` et `doc/regfile_design.md`.

**Risks & Mitigation:**
*   **Risque :** Logique de l'ALU ternaire (ADD/SUB 24t, flags OF/XF) complexe et sujette aux erreurs. -> **Mitigation :** Tests unitaires *très* poussés pour l'ALU. Débogage VCD minutieux. Valider la logique des flags par rapport à des exemples calculés à la main. Commencer sans OF/XF si trop complexe.
*   **Risque :** Implémentation Ripple Carry Adder lente pour la fréquence cible finale. -> **Mitigation :** Acceptable pour ce sprint. Des architectures d'additionneurs plus rapides (Carry Lookahead adapté au ternaire) sont des optimisations futures (Sprint 13+).
*   **Risque :** Gestion des types et conversions VHDL (std_logic_vector, unsigned, integer) source d'erreurs. -> **Mitigation :** Utiliser `numeric_std`. Être très attentif aux tailles de vecteurs et aux conversions explicites. Utiliser les messages du compilateur GHDL.
*   **Risque :** Comportement exact lecture/écriture simultanée du RegFile. -> **Mitigation :** Le vérifier spécifiquement en simulation. Le comportement sur FPGA peut dépendre de la synthèse (BRAM primitives).

**Notes:**
*   La validation exhaustive de l'ALU (surtout les flags) est primordiale.
*   Ce sprint fournit les "muscles" (ALU) et la mémoire immédiate (Registres) du CPU. Le prochain sprint se concentrera sur le "cerveau" (Unité de Contrôle) et l'assemblage du datapath.

**AIDEX Integration Potential:**
*   Génération de la structure VHDL pour l'ALU 24t (avec `generate` pour les TFA).
*   Aide à l'écriture de la logique de calcul des flags (ZF, SF, OF, CF, XF) en VHDL.
*   Génération du boilerplate pour le banc de registres (entité, architecture, process d'écriture).
*   Génération de scénarios de test et assertions pour les testbenches `tb_alu_24t` et `tb_register_file`.
*   Aide au débogage des erreurs de simulation VHDL ou des comportements inattendus dans GTKWave.
*   Explication des concepts VHDL spécifiques (generate, process synchrone, lecture combinatoire de tableau).