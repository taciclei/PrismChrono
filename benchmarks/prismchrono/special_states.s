# Benchmark: Special States
# Traitement d'un tableau avec des valeurs spéciales (NULL, NaN)
# Ce benchmark démontre la gestion efficace des états spéciaux dans l'architecture ternaire

# Définition des constantes
.equ ARRAY_SIZE, 50       # Taille du tableau
.equ SPECIAL_COUNT, 10    # Nombre de valeurs spéciales dans le tableau
.equ ARRAY_ADDR, 0x1000   # Adresse du tableau
.equ RESULT_ADDR, 0x1200  # Adresse des résultats

# Valeurs spéciales
.equ NULL_VALUE, 0x80000000  # Représentation de NULL
.equ NAN_VALUE, 0x7FFFFFFF   # Représentation de NaN
.equ UNDEFINED, 0x40000000   # Représentation d'une valeur indéfinie

# Section de données
.section .data
# Le tableau sera initialisé par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, ARRAY_ADDR    # Adresse du tableau
    MOVI r2, RESULT_ADDR   # Adresse des résultats
    MOVI r3, ARRAY_SIZE    # Taille du tableau
    MOVI r4, 0             # Index courant
    MOVI r5, 0             # Compteur de valeurs NULL
    MOVI r6, 0             # Compteur de valeurs NaN
    MOVI r7, 0             # Compteur de valeurs indéfinies
    MOVI r8, 0             # Somme des valeurs valides
    MOVI r9, 0             # Compteur de valeurs valides

# Partie 1: Traitement avec détection explicite des valeurs spéciales
standard_processing:
    # Vérifier si on a parcouru tout le tableau
    CMP r4, r3
    BRANCH GE, ternary_init # Si index >= taille, passer à la partie suivante
    
    # Calculer l'adresse de l'élément courant
    ADD r10, r1, r4       # r10 = adresse_tableau + index
    
    # Charger la valeur
    LOADW r11, r10, 0     # r11 = tableau[index]
    
    # Vérifier si c'est une valeur NULL
    MOVI r12, NULL_VALUE
    CMP r11, r12
    BRANCH NE, check_nan
    ADDI r5, r5, 1        # Incrémenter compteur de NULL
    BRANCH AL, next_element
    
check_nan:
    # Vérifier si c'est une valeur NaN
    MOVI r12, NAN_VALUE
    CMP r11, r12
    BRANCH NE, check_undefined
    ADDI r6, r6, 1        # Incrémenter compteur de NaN
    BRANCH AL, next_element
    
check_undefined:
    # Vérifier si c'est une valeur indéfinie
    MOVI r12, UNDEFINED
    CMP r11, r12
    BRANCH NE, valid_value
    ADDI r7, r7, 1        # Incrémenter compteur d'indéfinis
    BRANCH AL, next_element
    
valid_value:
    # C'est une valeur valide, l'ajouter à la somme
    ADD r8, r8, r11       # Ajouter à la somme
    ADDI r9, r9, 1        # Incrémenter compteur de valeurs valides
    
next_element:
    # Passer à l'élément suivant
    ADDI r4, r4, 1
    BRANCH AL, standard_processing

# Partie 2: Traitement avec instructions ternaires spéciales pour les états spéciaux
ternary_init:
    # Stocker les résultats de la première partie
    STOREW r5, r2, 0      # Nombre de NULL
    STOREW r6, r2, 1      # Nombre de NaN
    STOREW r7, r2, 2      # Nombre d'indéfinis
    STOREW r8, r2, 3      # Somme des valeurs valides
    STOREW r9, r2, 4      # Nombre de valeurs valides
    
    # Réinitialiser les compteurs pour la deuxième partie
    MOVI r4, 0            # Index courant
    MOVI r5, 0            # Compteur de valeurs NULL
    MOVI r6, 0            # Compteur de valeurs NaN
    MOVI r7, 0            # Compteur de valeurs indéfinies
    MOVI r8, 0            # Somme des valeurs valides
    MOVI r9, 0            # Compteur de valeurs valides
    ADDI r2, r2, 10       # Décaler l'adresse de résultat

ternary_processing:
    # Vérifier si on a parcouru tout le tableau
    CMP r4, r3
    BRANCH GE, end        # Si index >= taille, terminer
    
    # Calculer l'adresse de l'élément courant
    ADD r10, r1, r4       # r10 = adresse_tableau + index
    
    # Charger la valeur
    LOADW r11, r10, 0     # r11 = tableau[index]
    
    # Utiliser l'instruction spéciale IS_SPECIAL pour détecter les valeurs spéciales
    # Cette instruction fictive vérifie si une valeur est spéciale (NULL, NaN, indéfinie)
    # et retourne un code indiquant le type de valeur spéciale
    IS_SPECIAL r12, r11   # r12 = type de valeur spéciale (0 si valeur normale)
    
    # Vérifier le résultat
    MOVI r13, 0
    CMP r12, r13
    BRANCH NE, handle_special
    
    # C'est une valeur normale
    ADD r8, r8, r11       # Ajouter à la somme
    ADDI r9, r9, 1        # Incrémenter compteur de valeurs valides
    BRANCH AL, ternary_next
    
handle_special:
    # Utiliser BRANCH3 pour traiter les différents types de valeurs spéciales
    # Si r12 = 1, c'est NULL
    # Si r12 = 2, c'est NaN
    # Si r12 = 3, c'est indéfini
    BRANCH3 r12, null_case, nan_case, undefined_case
    
null_case:
    ADDI r5, r5, 1        # Incrémenter compteur de NULL
    BRANCH AL, ternary_next
    
nan_case:
    ADDI r6, r6, 1        # Incrémenter compteur de NaN
    BRANCH AL, ternary_next
    
undefined_case:
    ADDI r7, r7, 1        # Incrémenter compteur d'indéfinis
    
ternary_next:
    # Passer à l'élément suivant
    ADDI r4, r4, 1
    BRANCH AL, ternary_processing

end:
    # Stocker les résultats de la deuxième partie
    STOREW r5, r2, 0      # Nombre de NULL
    STOREW r6, r2, 1      # Nombre de NaN
    STOREW r7, r2, 2      # Nombre d'indéfinis
    STOREW r8, r2, 3      # Somme des valeurs valides
    STOREW r9, r2, 4      # Nombre de valeurs valides
    
    # Fin du programme
    HALT