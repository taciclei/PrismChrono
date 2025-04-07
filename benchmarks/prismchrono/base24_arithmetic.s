# Benchmark: Base24 Arithmetic
# Calculs exploitant la base 24 ou la symétrie
# Ce benchmark démontre les avantages de l'architecture ternaire pour les calculs en base 24

# Définition des constantes
.equ OPERATIONS_COUNT, 30  # Nombre d'opérations à effectuer
.equ DATA_ADDR, 0x1000     # Adresse des données d'entrée
.equ RESULT_ADDR, 0x1200   # Adresse des résultats

# Constantes pour la base 24
.equ BASE24, 24            # Base de calcul (3^3 * 2^3)

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR      # Adresse des données
    MOVI r2, RESULT_ADDR    # Adresse des résultats
    MOVI r3, OPERATIONS_COUNT # Nombre d'opérations
    MOVI r4, 0              # Index courant

# Partie 1: Calculs en base 24 avec optimisations ternaires
base24_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, standard_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes
    LOADW r7, r5, 0        # r7 = données[index] (premier opérande)
    LOADW r8, r5, 1        # r8 = données[index+1] (deuxième opérande)
    
    # Effectuer les calculs en base 24 avec optimisations ternaires
    # 1. Conversion en base 24 (utilisation des propriétés ternaires)
    TRIT_EXTRACT r9, r7, 0  # Extraire les trits individuels
    TRIT_EXTRACT r10, r7, 1
    TRIT_EXTRACT r11, r7, 2
    
    # Calculer la valeur en base 24
    MOVI r12, 9            # 3^2
    MUL r10, r10, r12       # r10 = deuxième trit * 9
    MOVI r12, 3
    MUL r11, r11, r12       # r11 = troisième trit * 3
    ADD r9, r9, r10         # Combiner les valeurs
    ADD r9, r9, r11
    
    # Faire de même pour le deuxième opérande
    TRIT_EXTRACT r10, r8, 0
    TRIT_EXTRACT r11, r8, 1
    TRIT_EXTRACT r12, r8, 2
    
    MOVI r13, 9
    MUL r11, r11, r13
    MOVI r13, 3
    MUL r12, r12, r13
    ADD r10, r10, r11
    ADD r10, r10, r12
    
    # 2. Effectuer l'opération en base 24
    ADD r11, r9, r10       # Addition en base 24
    
    # 3. Conversion du résultat en format ternaire
    MOVI r12, BASE24
    MOD r13, r11, r12      # r13 = r11 % 24 (reste de la division par 24)
    DIV r11, r11, r12      # r11 = r11 / 24 (quotient)
    
    # Stocker le résultat
    STOREW r13, r6, 0      # résultat[index] = reste
    STOREW r11, r6, 1      # résultat[index+1] = quotient
    
    # Passer à l'opération suivante
    ADDI r4, r4, 2
    BRANCH AL, base24_loop

# Partie 2: Calculs standard pour comparaison
standard_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

standard_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, symmetry_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes
    LOADW r7, r5, 0        # r7 = données[index] (premier opérande)
    LOADW r8, r5, 1        # r8 = données[index+1] (deuxième opérande)
    
    # Effectuer les calculs standard
    ADD r9, r7, r8         # Addition standard
    
    # Conversion en base 24 (méthode standard)
    MOVI r10, BASE24
    MOD r11, r9, r10       # r11 = r9 % 24 (reste)
    DIV r12, r9, r10       # r12 = r9 / 24 (quotient)
    
    # Stocker le résultat
    STOREW r11, r6, 0      # résultat[index] = reste
    STOREW r12, r6, 1      # résultat[index+1] = quotient
    
    # Passer à l'opération suivante
    ADDI r4, r4, 2
    BRANCH AL, standard_loop

# Partie 3: Calculs exploitant la symétrie ternaire
symmetry_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

symmetry_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, end         # Si index >= nombre d'opérations, terminer
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes
    LOADW r7, r5, 0        # r7 = données[index] (premier opérande)
    
    # Exploiter la symétrie ternaire pour les calculs
    # Exemple: calcul de la valeur symétrique (-x dans le système ternaire équilibré)
    NEG r8, r7             # r8 = -r7 (symétrie par rapport à zéro)
    
    # Autre exemple: rotation des trits (symétrie circulaire)
    TRIT_ROTATE r9, r7, 1  # Rotation des trits de 1 position
    
    # Stocker les résultats
    STOREW r8, r6, 0       # résultat[index] = valeur symétrique
    STOREW r9, r6, 1       # résultat[index+1] = valeur avec trits rotés
    
    # Passer à l'opération suivante
    ADDI r4, r4, 2
    BRANCH AL, symmetry_loop

end:
    # Fin du programme
    HALT