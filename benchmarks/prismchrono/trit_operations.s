# Benchmark: Trit Operations
# Implémentation d'opérations spécialisées trit par trit (TMIN, TMAX, TSUM, TCMP3)
# Ce benchmark démontre l'efficacité des instructions ternaires spécialisées

# Définition des constantes
.equ ARRAY_SIZE, 50      # Taille du tableau
.equ ARRAY_ADDR, 0x1000  # Adresse du premier tableau
.equ ARRAY2_ADDR, 0x1200 # Adresse du deuxième tableau
.equ RESULT_ADDR, 0x1400 # Adresse où stocker les résultats

# Section de données
.section .data
# Les tableaux seront initialisés par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, ARRAY_ADDR   # Adresse du premier tableau
    MOVI r2, ARRAY2_ADDR  # Adresse du deuxième tableau
    MOVI r3, RESULT_ADDR  # Adresse des résultats
    MOVI r4, ARRAY_SIZE   # Taille du tableau
    MOVI r5, 0            # Index courant

# Partie 1: Utilisation de TMIN pour trouver le minimum trit par trit
tmin_loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r5, r4
    BRANCH GE, tmax_init  # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses des éléments courants
    ADD r6, r1, r5        # r6 = adresse1 + index
    ADD r7, r2, r5        # r7 = adresse2 + index
    ADD r8, r3, r5        # r8 = adresse_résultat + index
    
    # Charger les valeurs
    LOADW r9, r6, 0       # r9 = tableau1[index]
    LOADW r10, r7, 0      # r10 = tableau2[index]
    
    # Appliquer l'opération TMIN (minimum trit par trit)
    TMIN r11, r9, r10     # r11 = min(r9, r10) trit par trit
    
    # Stocker le résultat
    STOREW r11, r8, 0     # résultat[index] = r11
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, tmin_loop  # Continuer la boucle

# Partie 2: Utilisation de TMAX pour trouver le maximum trit par trit
tmax_init:
    MOVI r5, 0            # Réinitialiser l'index
    ADDI r3, r3, ARRAY_SIZE # Décaler l'adresse de résultat

tmax_loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r5, r4
    BRANCH GE, tsum_init  # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses des éléments courants
    ADD r6, r1, r5        # r6 = adresse1 + index
    ADD r7, r2, r5        # r7 = adresse2 + index
    ADD r8, r3, r5        # r8 = adresse_résultat + index
    
    # Charger les valeurs
    LOADW r9, r6, 0       # r9 = tableau1[index]
    LOADW r10, r7, 0      # r10 = tableau2[index]
    
    # Appliquer l'opération TMAX (maximum trit par trit)
    TMAX r11, r9, r10     # r11 = max(r9, r10) trit par trit
    
    # Stocker le résultat
    STOREW r11, r8, 0     # résultat[index] = r11
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, tmax_loop  # Continuer la boucle

# Partie 3: Utilisation de TSUM pour la somme trit par trit (sans propagation)
tsum_init:
    MOVI r5, 0            # Réinitialiser l'index
    ADDI r3, r3, ARRAY_SIZE # Décaler l'adresse de résultat

tsum_loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r5, r4
    BRANCH GE, tcmp3_init # Si index >= taille, passer à la partie suivante
    
    # Calculer les adresses des éléments courants
    ADD r6, r1, r5        # r6 = adresse1 + index
    ADD r7, r2, r5        # r7 = adresse2 + index
    ADD r8, r3, r5        # r8 = adresse_résultat + index
    
    # Charger les valeurs
    LOADW r9, r6, 0       # r9 = tableau1[index]
    LOADW r10, r7, 0      # r10 = tableau2[index]
    
    # Appliquer l'opération TSUM (somme trit par trit sans propagation)
    TSUM r11, r9, r10     # r11 = r9 + r10 trit par trit
    
    # Stocker le résultat
    STOREW r11, r8, 0     # résultat[index] = r11
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, tsum_loop  # Continuer la boucle

# Partie 4: Utilisation de TCMP3 pour la comparaison ternaire à 3 états
tcmp3_init:
    MOVI r5, 0            # Réinitialiser l'index
    ADDI r3, r3, ARRAY_SIZE # Décaler l'adresse de résultat

tcmp3_loop:
    # Vérifier si on a parcouru tout le tableau
    CMP r5, r4
    BRANCH GE, end        # Si index >= taille, terminer
    
    # Calculer les adresses des éléments courants
    ADD r6, r1, r5        # r6 = adresse1 + index
    ADD r7, r2, r5        # r7 = adresse2 + index
    ADD r8, r3, r5        # r8 = adresse_résultat + index
    
    # Charger les valeurs
    LOADW r9, r6, 0       # r9 = tableau1[index]
    LOADW r10, r7, 0      # r10 = tableau2[index]
    
    # Appliquer l'opération TCMP3 (comparaison ternaire à 3 états)
    TCMP3 r11, r9, r10    # r11[i] = -1 si r9[i] < r10[i], 0 si égaux, 1 si r9[i] > r10[i]
    
    # Stocker le résultat
    STOREW r11, r8, 0     # résultat[index] = r11
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, tcmp3_loop # Continuer la boucle

end:
    # Fin du programme
    HALT