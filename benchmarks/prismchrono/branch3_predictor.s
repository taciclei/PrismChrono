# Benchmark: Branch3 Predictor
# Évaluation des performances du prédicteur de branchement ternaire avancé
# Ce benchmark compare le prédicteur de branchement ternaire avancé au prédicteur standard

# Définition des constantes
.equ DATA_SIZE, 100       # Nombre d'éléments à traiter
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ RESULT_ADDR, 0x1400  # Adresse des résultats

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
    MOVI r3, DATA_SIZE     # Nombre d'éléments
    MOVI r4, 0             # Index courant
    MOVI r5, 0             # Compteur de branches correctement prédites (standard)
    MOVI r6, 0             # Compteur de branches correctement prédites (avancé)

# Partie 1: Utilisation du prédicteur de branchement ternaire avancé
advanced_predictor_loop:
    # Vérifier si on a traité tous les éléments
    CMP r4, r3
    BRANCH GE, standard_init # Si index >= nombre d'éléments, passer à la partie suivante
    
    # Calculer l'adresse de la donnée courante
    ADD r7, r1, r4        # r7 = adresse_données + index
    
    # Charger la valeur
    LOADW r8, r7, 0       # r8 = données[index]
    
    # Utiliser BRANCH3_HINT pour prendre une décision avec prédiction
    # Le hint est défini comme Z (neutre) pour commencer
    # Si r8 < 0, aller à negative_case
    # Si r8 = 0, aller à zero_case
    # Si r8 > 0, aller à positive_case
    BRANCH3_HINT r8, Z, negative_case, zero_case, positive_case

negative_case:
    # Traitement pour valeur négative
    MOVI r9, 10           # Résultat pour cas négatif
    STOREW r9, r2, r4     # résultat[index] = 10
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    # Dans un cas réel, cette information viendrait du prédicteur
    # Ici, on simule en vérifiant si la valeur est effectivement négative
    MOVI r10, NEGATIVE
    CMP r8, r10
    BRANCH NE, next_advanced
    ADDI r6, r6, 1        # Prédiction correcte
    BRANCH AL, next_advanced

zero_case:
    # Traitement pour valeur zéro
    MOVI r9, 20           # Résultat pour cas zéro
    STOREW r9, r2, r4     # résultat[index] = 20
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    MOVI r10, ZERO
    CMP r8, r10
    BRANCH NE, next_advanced
    ADDI r6, r6, 1        # Prédiction correcte
    BRANCH AL, next_advanced

positive_case:
    # Traitement pour valeur positive
    MOVI r9, 30           # Résultat pour cas positif
    STOREW r9, r2, r4     # résultat[index] = 30
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    MOVI r10, POSITIVE
    CMP r8, r10
    BRANCH NE, next_advanced
    ADDI r6, r6, 1        # Prédiction correcte

next_advanced:
    # Passer à l'élément suivant
    ADDI r4, r4, 1        # index++
    BRANCH AL, advanced_predictor_loop

# Partie 2: Utilisation du prédicteur de branchement standard pour comparaison
standard_init:
    MOVI r4, 0             # Réinitialiser l'index
    ADDI r2, r2, DATA_SIZE # Décaler l'adresse de résultat

standard_predictor_loop:
    # Vérifier si on a traité tous les éléments
    CMP r4, r3
    BRANCH GE, end        # Si index >= nombre d'éléments, terminer
    
    # Calculer l'adresse de la donnée courante
    ADD r7, r1, r4        # r7 = adresse_données + index
    
    # Charger la valeur
    LOADW r8, r7, 0       # r8 = données[index]
    
    # Utiliser des branchements standard avec prédiction binaire
    # Vérifier si la valeur est négative
    MOVI r10, 0
    CMP r8, r10
    BRANCH LT, std_negative_case
    
    # Vérifier si la valeur est zéro
    CMP r8, r10
    BRANCH EQ, std_zero_case
    
    # Si on arrive ici, la valeur est positive
    BRANCH AL, std_positive_case

std_negative_case:
    # Traitement pour valeur négative
    MOVI r9, 10           # Résultat pour cas négatif
    STOREW r9, r2, r4     # résultat[index] = 10
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    # Dans un cas réel, cette information viendrait du prédicteur
    # Ici, on simule en vérifiant si la valeur est effectivement négative
    MOVI r10, NEGATIVE
    CMP r8, r10
    BRANCH NE, next_standard
    ADDI r5, r5, 1        # Prédiction correcte
    BRANCH AL, next_standard

std_zero_case:
    # Traitement pour valeur zéro
    MOVI r9, 20           # Résultat pour cas zéro
    STOREW r9, r2, r4     # résultat[index] = 20
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    MOVI r10, ZERO
    CMP r8, r10
    BRANCH NE, next_standard
    ADDI r5, r5, 1        # Prédiction correcte
    BRANCH AL, next_standard

std_positive_case:
    # Traitement pour valeur positive
    MOVI r9, 30           # Résultat pour cas positif
    STOREW r9, r2, r4     # résultat[index] = 30
    
    # Incrémenter le compteur de prédictions correctes si la prédiction était correcte
    MOVI r10, POSITIVE
    CMP r8, r10
    BRANCH NE, next_standard
    ADDI r5, r5, 1        # Prédiction correcte

next_standard:
    # Passer à l'élément suivant
    ADDI r4, r4, 1        # index++
    BRANCH AL, standard_predictor_loop

end:
    # Stocker les compteurs de prédictions correctes
    MOVI r11, RESULT_ADDR
    ADDI r11, r11, DATA_SIZE
    ADDI r11, r11, DATA_SIZE
    STOREW r5, r11, 0     # Stocker le nombre de prédictions correctes (standard)
    STOREW r6, r11, 1     # Stocker le nombre de prédictions correctes (avancé)
    
    HALT