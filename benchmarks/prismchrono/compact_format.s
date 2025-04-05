# Benchmark: Compact Format
# Comparaison entre format standard et format compact
# Ce benchmark démontre les avantages du format d'instruction compact en termes de densité de code

# Définition des constantes
.equ ITERATIONS, 50       # Nombre d'itérations
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ RESULT_ADDR, 0x1200  # Adresse des résultats

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR     # Adresse des données
    MOVI r2, RESULT_ADDR   # Adresse des résultats
    MOVI r3, ITERATIONS    # Nombre d'itérations

# Partie 1: Utilisation du format standard
standard_format:
    # Initialisation pour la partie standard
    MOVI r4, 0             # Compteur d'itérations
    MOVI r5, 0             # Accumulateur

standard_loop:
    # Vérifier si on a effectué toutes les itérations
    CMP r4, r3
    BRANCH GE, compact_format # Si compteur >= itérations, passer à la partie suivante
    
    # Calculer l'adresse de la donnée courante
    ADD r6, r1, r4        # r6 = adresse_données + compteur
    
    # Charger la valeur
    LOADW r7, r6, 0       # r7 = données[compteur]
    
    # Effectuer des opérations standard
    ADD r5, r5, r7        # Ajouter la valeur à l'accumulateur
    ADDI r4, r4, 1        # Incrémenter le compteur
    
    # Vérifier si l'accumulateur dépasse une certaine valeur
    MOVI r8, 1000
    CMP r5, r8
    BRANCH LT, standard_loop # Si accumulateur < 1000, continuer la boucle
    
    # Réinitialiser l'accumulateur si nécessaire
    MOVI r5, 0
    BRANCH AL, standard_loop # Continuer la boucle

# Partie 2: Utilisation du format compact
compact_format:
    # Stocker le résultat de la partie standard
    STOREW r5, r2, 0
    
    # Initialisation pour la partie compact
    MOVI r4, 0             # Compteur d'itérations
    MOVI r5, 0             # Accumulateur

compact_loop:
    # Vérifier si on a effectué toutes les itérations
    CMP r4, r3
    BRANCH GE, end        # Si compteur >= itérations, terminer
    
    # Calculer l'adresse de la donnée courante (utilisation du format compact)
    CADD r4, r1           # r4 = r4 + r1 (format compact)
    
    # Charger la valeur
    LOADW r7, r4, 0       # r7 = données[compteur]
    
    # Effectuer des opérations avec format compact
    CADD r5, r7           # r5 = r5 + r7 (format compact)
    CMOV r4, r1           # r4 = r1 (format compact)
    CADD r4, r4           # r4 = r4 + r4 (format compact)
    
    # Vérifier si l'accumulateur dépasse une certaine valeur
    MOVI r8, 1000
    CMP r5, r8
    CBRANCH LT, compact_continue # Si accumulateur < 1000, continuer (format compact)
    
    # Réinitialiser l'accumulateur si nécessaire
    MOVI r5, 0

compact_continue:
    CADD r4, r4           # r4 = r4 + r4 (format compact)
    CBRANCH AL, compact_loop # Continuer la boucle (format compact)

end:
    # Stocker le résultat de la partie compact
    STOREW r5, r2, 4
    
    # Fin du programme
    HALT