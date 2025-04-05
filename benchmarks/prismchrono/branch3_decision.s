# Benchmark: Branch3 Decision
# Démonstration de l'efficacité du branchement ternaire (BRANCH3)
# Ce benchmark compare l'utilisation de BRANCH3 vs des branchements binaires classiques

# Définition des constantes
.equ DECISIONS_COUNT, 30  # Nombre de décisions à prendre
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ RESULT_ADDR, 0x1200  # Adresse des résultats

# Valeurs ternaires
.equ NEGATIVE, -1         # Valeur négative
.equ ZERO, 0              # Valeur zéro
.equ POSITIVE, 1          # Valeur positive

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
    MOVI r3, DECISIONS_COUNT # Nombre de décisions
    MOVI r4, 0             # Index courant

# Partie 1: Utilisation de BRANCH3 pour prendre des décisions ternaires
branch3_loop:
    # Vérifier si on a traité toutes les décisions
    CMP r4, r3
    BRANCH GE, standard_init # Si index >= nombre de décisions, passer à la partie suivante
    
    # Calculer l'adresse de la donnée courante
    ADD r5, r1, r4        # r5 = adresse_données + index
    ADD r6, r2, r4        # r6 = adresse_résultats + index
    
    # Charger la valeur
    LOADW r7, r5, 0       # r7 = données[index]
    
    # Utiliser BRANCH3 pour prendre une décision basée sur la valeur ternaire
    # Si r7 < 0, aller à negative_case
    # Si r7 = 0, aller à zero_case
    # Si r7 > 0, aller à positive_case
    BRANCH3 r7, negative_case, zero_case, positive_case

negative_case:
    # Traitement pour valeur négative
    MOVI r8, 10           # Résultat pour cas négatif
    STOREW r8, r6, 0      # résultat[index] = 10
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, branch3_loop # Continuer la boucle

zero_case:
    # Traitement pour valeur zéro
    MOVI r8, 20           # Résultat pour cas zéro
    STOREW r8, r6, 0      # résultat[index] = 20
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, branch3_loop # Continuer la boucle

positive_case:
    # Traitement pour valeur positive
    MOVI r8, 30           # Résultat pour cas positif
    STOREW r8, r6, 0      # résultat[index] = 30
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, branch3_loop # Continuer la boucle

# Partie 2: Utilisation de branchements standard pour comparaison
standard_init:
    MOVI r4, 0             # Réinitialiser l'index
    ADDI r2, r2, DECISIONS_COUNT # Décaler l'adresse de résultat

standard_loop:
    # Vérifier si on a traité toutes les décisions
    CMP r4, r3
    BRANCH GE, end        # Si index >= nombre de décisions, terminer
    
    # Calculer l'adresse de la donnée courante
    ADD r5, r1, r4        # r5 = adresse_données + index
    ADD r6, r2, r4        # r6 = adresse_résultats + index
    
    # Charger la valeur
    LOADW r7, r5, 0       # r7 = données[index]
    
    # Vérifier si la valeur est négative
    MOVI r9, 0
    CMP r7, r9
    BRANCH LT, std_negative_case
    
    # Vérifier si la valeur est zéro
    CMP r7, r9
    BRANCH EQ, std_zero_case
    
    # Si on arrive ici, la valeur est positive
    BRANCH AL, std_positive_case

std_negative_case:
    # Traitement pour valeur négative
    MOVI r8, 10           # Résultat pour cas négatif
    STOREW r8, r6, 0      # résultat[index] = 10
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, standard_loop # Continuer la boucle

std_zero_case:
    # Traitement pour valeur zéro
    MOVI r8, 20           # Résultat pour cas zéro
    STOREW r8, r6, 0      # résultat[index] = 20
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, standard_loop # Continuer la boucle

std_positive_case:
    # Traitement pour valeur positive
    MOVI r8, 30           # Résultat pour cas positif
    STOREW r8, r6, 0      # résultat[index] = 30
    ADDI r4, r4, 1        # Incrémenter l'index
    BRANCH AL, standard_loop # Continuer la boucle

end:
    # Fin du programme
    HALT