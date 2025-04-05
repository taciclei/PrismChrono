# Benchmark: Ternary Logic
# Implémentation d'un système de vote à trois états (Positif/Zéro/Négatif)
# Ce benchmark est conçu pour mettre en évidence les avantages de la logique ternaire

# Définition des constantes
.equ ARRAY_SIZE, 50      # Nombre de votes
.equ ARRAY_ADDR, 0x1000  # Adresse du tableau de votes
.equ RESULT_ADDR, 0x1400 # Adresse où stocker le résultat

# Valeurs ternaires
.equ NEGATIVE, -1        # Vote négatif
.equ ZERO, 0             # Abstention
.equ POSITIVE, 1         # Vote positif

# Section de données
.section .data
# Le tableau de votes sera initialisé par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, ARRAY_ADDR   # Adresse du tableau
    MOVI r2, ARRAY_SIZE   # Taille du tableau
    MOVI r3, 0            # Compteur de votes positifs
    MOVI r4, 0            # Compteur de votes négatifs
    MOVI r5, 0            # Compteur d'abstentions
    MOVI r6, 0            # Index courant

count_loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r6, r2            # Comparer index et taille
    BRANCH GE, end_count  # Si index >= taille, sortir de la boucle
    
    # Calculer l'adresse de l'élément courant
    ADD r7, r1, r6        # r7 = adresse de base + index
    
    # Charger le vote courant
    LOADW r8, r7, 0       # r8 = tableau[index]
    
    # Déterminer le type de vote (utilisation de la logique ternaire)
    # Avantage PrismChrono: peut utiliser COMPARE3 ou équivalent pour tester en une seule instruction
    
    # Vérifier si c'est un vote positif
    MOVI r9, POSITIVE
    CMP r8, r9
    BRANCH NE, check_negative
    ADDI r3, r3, 1        # Incrémenter compteur de votes positifs
    BRANCH ALWAYS, next_vote
    
check_negative:
    # Vérifier si c'est un vote négatif
    MOVI r9, NEGATIVE
    CMP r8, r9
    BRANCH NE, check_zero
    ADDI r4, r4, 1        # Incrémenter compteur de votes négatifs
    BRANCH ALWAYS, next_vote
    
check_zero:
    # Si ce n'est ni positif ni négatif, c'est une abstention
    ADDI r5, r5, 1        # Incrémenter compteur d'abstentions
    
next_vote:
    # Passer au vote suivant
    ADDI r6, r6, 1        # index++
    BRANCH ALWAYS, count_loop

end_count:
    # Déterminer le résultat du vote
    # Règle: majorité simple (plus de votes positifs que négatifs = accepté)
    CMP r3, r4            # Comparer votes positifs et négatifs
    BRANCH LE, vote_rejected
    
    # Vote accepté
    MOVI r10, POSITIVE
    BRANCH ALWAYS, store_result
    
vote_rejected:
    # Vérifier s'il y a égalité
    CMP r3, r4
    BRANCH NE, vote_negative
    
    # Égalité
    MOVI r10, ZERO
    BRANCH ALWAYS, store_result
    
vote_negative:
    # Plus de votes négatifs
    MOVI r10, NEGATIVE
    
store_result:
    # Stocker le résultat et les compteurs
    MOVI r11, RESULT_ADDR
    STOREW r10, r11, 0    # Résultat du vote
    STOREW r3, r11, 1     # Nombre de votes positifs
    STOREW r4, r11, 2     # Nombre de votes négatifs
    STOREW r5, r11, 3     # Nombre d'abstentions
    
    # Fin du programme
    HALT