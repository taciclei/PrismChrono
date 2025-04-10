# Interface Mémoire PrismChrono

Ce document décrit l'interface mémoire du processeur PrismChrono, en particulier la gestion des opérations Load/Store et l'interface avec les BRAMs du FPGA.

## Architecture Générale

L'architecture mémoire de PrismChrono est organisée comme suit :

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
| prismchrono_core | <-> | bram_controller | <-> | BRAM (FPGA)      |
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
```

Le cœur du processeur (`prismchrono_core`) communique avec la mémoire principale via le contrôleur BRAM (`bram_controller`), qui abstrait les détails spécifiques des primitives BRAM du FPGA.

## Instructions de Chargement et Stockage

PrismChrono supporte les instructions suivantes pour l'accès mémoire :

- **LOADW** (I-Format) : Charge un mot ternaire (24 trits) depuis la mémoire vers un registre.
- **LOADT** (I-Format) : Charge un tryte (3 trits) depuis la mémoire et l'étend avec le signe vers un registre.
- **LOADTU** (I-Format) : Charge un tryte (3 trits) depuis la mémoire et l'étend avec des zéros vers un registre.
- **STOREW** (S-Format) : Stocke un mot ternaire (24 trits) depuis un registre vers la mémoire.
- **STORET** (S-Format) : Stocke un tryte (3 trits) depuis un registre vers la mémoire.

## Calcul d'Adresse Mémoire

L'adresse mémoire effective est calculée comme suit :

```
Adresse = Base (Rs1) + SignExtend(Offset)
```

Où :
- `Base` est le contenu du registre source Rs1
- `Offset` est l'offset immédiat encodé dans l'instruction (signé)

## Alignement Mémoire

### Contraintes d'Alignement

- **LOADW/STOREW** : L'adresse doit être alignée sur 8 trytes (les 3 bits de poids faible doivent être zéro).
- **LOADT/LOADTU/STORET** : Aucune contrainte d'alignement (peut accéder à n'importe quelle adresse).

### Gestion des Erreurs d'Alignement

Si une instruction LOADW ou STOREW tente d'accéder à une adresse non alignée, une exception est générée :

- Pour LOADW : Exception `LoadAddressMisaligned`
- Pour STOREW : Exception `StoreAddressMisaligned`

Ces exceptions sont détectées par le contrôleur BRAM qui active le signal `alignment_error`, lequel est propagé au mécanisme de trap du processeur.

## Endianness

PrismChrono utilise le format **Little-Endian** pour les accès mémoire :

- Les trytes de poids faible sont stockés aux adresses basses
- Les trytes de poids fort sont stockés aux adresses hautes

Exemple pour un mot de 24 trits (8 trytes) stocké à l'adresse A :

```
Adresse A+0 : Tryte 0 (bits 5-0)
Adresse A+1 : Tryte 1 (bits 11-6)
Adresse A+2 : Tryte 2 (bits 17-12)
Adresse A+3 : Tryte 3 (bits 23-18)
Adresse A+4 : Tryte 4 (bits 29-24)
Adresse A+5 : Tryte 5 (bits 35-30)
Adresse A+6 : Tryte 6 (bits 41-36)
Adresse A+7 : Tryte 7 (bits 47-42)
```

## Extension de Signe et Zéro

Pour les instructions de chargement de tryte :

- **LOADT** : Le tryte chargé est étendu à 24 trits en propageant le signe ternaire (trit de poids fort du tryte).
- **LOADTU** : Le tryte chargé est étendu à 24 trits en ajoutant des zéros ternaires (TRIT_Z).

## Interface du Contrôleur BRAM

### Interface avec le Cœur du Processeur

```vhdl
-- Interface avec le cœur du processeur
mem_addr        : in  EncodedAddress;                -- Adresse mémoire demandée par le CPU
mem_data_in     : in  EncodedWord;                   -- Données à écrire en mémoire (mot complet)
mem_tryte_in    : in  EncodedTryte;                  -- Tryte à écrire en mémoire (pour STORET)
mem_read        : in  std_logic;                     -- Signal de lecture mémoire
mem_write       : in  std_logic;                     -- Signal d'écriture mémoire (mot complet)
mem_write_tryte : in  std_logic;                     -- Signal d'écriture mémoire (tryte)
mem_data_out    : out EncodedWord;                   -- Données lues de la mémoire (mot complet)
mem_tryte_out   : out EncodedTryte;                  -- Tryte lu de la mémoire (pour LOADT/LOADTU)
mem_ready       : out std_logic;                     -- Signal indiquant que la mémoire est prête
alignment_error : out std_logic;                     -- Signal indiquant une erreur d'alignement
```

### Interface avec la BRAM

```vhdl
-- Interface avec la BRAM (primitive FPGA)
bram_addr       : out std_logic_vector(15 downto 0); -- Adresse pour la BRAM (binaire)
bram_data_in    : in  std_logic_vector(47 downto 0); -- Données de la BRAM (binaire)
bram_data_out   : out std_logic_vector(47 downto 0); -- Données pour la BRAM (binaire)
bram_we         : out std_logic;                     -- Write enable pour la BRAM
bram_en         : out std_logic;                     -- Enable pour la BRAM
bram_tryte_sel  : out std_logic_vector(7 downto 0)   -- Sélection de tryte (8 trytes par mot)
```

## Machine à États du Contrôleur BRAM

Le contrôleur BRAM utilise une machine à états finis (FSM) pour gérer les accès mémoire :

1. **IDLE** : État d'attente, vérifie l'alignement pour les accès mot
2. **READ_WORD** : Lecture d'un mot complet
3. **READ_TRYTE** : Lecture d'un tryte (pour LOADT/LOADTU ou pour préparer un STORET)
4. **WRITE_WORD** : Écriture d'un mot complet
5. **WRITE_TRYTE** : Écriture d'un tryte (après read-modify-write)
6. **WAIT_BRAM** : Attente de la BRAM

### Opération Read-Modify-Write pour STORET

Pour l'instruction STORET, le contrôleur BRAM effectue une opération read-modify-write :

1. Lecture du mot complet contenant le tryte à modifier
2. Modification du tryte spécifique dans le mot
3. Écriture du mot modifié en mémoire

Cette approche est nécessaire car les BRAMs du FPGA ont généralement une granularité d'accès plus grande qu'un tryte.

## Intégration avec le Cycle d'Instruction

Le cycle d'instruction pour les opérations Load/Store est étendu avec les états suivants dans la FSM du processeur :

1. **EXEC_ADDR_CALC_LS** : Calcul de l'adresse effective pour Load/Store
2. **CHECK_ALIGNMENT** : Vérification de l'alignement pour LOADW/STOREW
3. **MEMORY_ACCESS** : Accès mémoire (lecture pour Load, écriture pour Store)
4. **WRITEBACK_LOAD** : Écriture de la donnée chargée dans le registre destination (uniquement pour Load)

Les instructions Store ne passent pas par l'état WRITEBACK car elles n'écrivent pas dans le banc de registres.