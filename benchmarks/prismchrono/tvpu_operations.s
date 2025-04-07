# Benchmark: TVPU Operations
# Évaluation des performances des instructions vectorielles ternaires
# Ce benchmark compare les opérations vectorielles aux opérations scalaires équivalentes

# Définition des constantes
.equ VECTOR_SIZE, 8       # Nombre d'éléments dans un vecteur ternaire
.equ ARRAY_SIZE, 32       # Nombre total d'éléments à traiter
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ VECTOR_A_ADDR, 0x1200 # Adresse du vecteur A
.equ VECTOR_B_ADDR, 0x1300 # Adresse du vecteur B
.equ RESULT_ADDR, 0x1400  # Adresse des résultats

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR     # Adresse des données
    MOVI r2, VECTOR_A_ADDR # Adresse du vecteur A
    MOVI r3, VECTOR_B_ADDR # Adresse du vecteur B
    MOVI r4, RESULT_ADDR   # Adresse des résultats
    MOVI r5, ARRAY_SIZE    # Nombre total d'éléments
    MOVI r6, 0             # Index courant

# Partie 1: Traitement vectoriel avec TVPU
vector_processing:
    # Vérifier si on a traité tous les éléments
    CMP r6, r5
    BRANCH GE, scalar_init # Si index >= nombre d'éléments, passer à la partie suivante
    
    # Charger les vecteurs A et B depuis la mémoire
    # Dans un cas réel, on utiliserait des instructions spécifiques pour charger des vecteurs
    # Ici, on simule le chargement en copiant les données
    MOVI r7, 0             # Index de vecteur
    
load_vectors:
    CMP r7, VECTOR_SIZE
    BRANCH GE, process_vectors
    
    # Calculer les adresses source
    ADD r8, r1, r6         # r8 = adresse_données + index_global
    ADD r8, r8, r7         # r8 += index_vecteur
    
    # Calculer les adresses destination
    ADD r9, r2, r7         # r9 = adresse_vecteur_A + index_vecteur
    ADD r10, r3, r7        # r10 = adresse_vecteur_B + index_vecteur
    
    # Charger les données
    LOADW r11, r8, 0       # r11 = données[index_global + index_vecteur]
    STOREW r11, r9, 0      # vecteur_A[index_vecteur] = r11
    
    # Pour le vecteur B, on utilise les données suivantes
    LOADW r11, r8, VECTOR_SIZE  # r11 = données[index_global + index_vecteur + VECTOR_SIZE]
    STOREW r11, r10, 0     # vecteur_B[index_vecteur] = r11
    
    ADDI r7, r7, 1         # Incrémenter l'index de vecteur
    BRANCH AL, load_vectors

process_vectors:
    # Effectuer les opérations vectorielles
    # 1. Addition vectorielle (TVADD)
    TVADD V0, V1, V2       # V0 = V1 + V2 (registres vectoriels)
    
    # 2. Produit scalaire (TVDOT)
    TVDOT r12, V1, V2      # r12 = V1 · V2
    
    # 3. Somme des éléments (TVSUM)
    TVSUM r13, V0          # r13 = somme des éléments de V0
    
    # 4. Minimum et maximum (TVMIN, TVMAX)
    TVMIN r14, V1          # r14 = min(V1)
    TVMAX r15, V2          # r15 = max(V2)
    
    # 5. Moyenne (TVAVG)
    TVAVG r16, V0          # r16 = moyenne(V0)
    
    # Stocker les résultats
    ADD r17, r4, r6        # r17 = adresse_résultats + index_global
    STOREW r12, r17, 0     # résultat[index] = produit_scalaire
    STOREW r13, r17, 1     # résultat[index+1] = somme
    STOREW r14, r17, 2     # résultat[index+2] = minimum
    STOREW r15, r17, 3     # résultat[index+3] = maximum
    STOREW r16, r17, 4     # résultat[index+4] = moyenne
    
    # Passer aux éléments suivants
    ADDI r6, r6, VECTOR_SIZE
    BRANCH AL, vector_processing

# Partie 2: Traitement scalaire équivalent pour comparaison
scalar_init:
    MOVI r6, 0             # Réinitialiser l'index
    ADDI r4, r4, ARRAY_SIZE # Décaler l'adresse de résultat

scalar_processing:
    # Vérifier si on a traité tous les éléments
    CMP r6, r5
    BRANCH GE, end         # Si index >= nombre d'éléments, terminer
    
    # Initialiser les accumulateurs pour les opérations scalaires
    MOVI r7, 0             # Index de vecteur
    MOVI r12, 0            # Accumulateur pour le produit scalaire
    MOVI r13, 0            # Accumulateur pour la somme
    MOVI r14, 0            # Valeur pour le minimum (sera initialisée au premier élément)
    MOVI r15, 0            # Valeur pour le maximum (sera initialisée au premier élément)
    MOVI r18, 1            # Indicateur d'initialisation pour min/max
    
scalar_loop:
    CMP r7, VECTOR_SIZE
    BRANCH GE, store_scalar_results
    
    # Calculer les adresses source
    ADD r8, r1, r6         # r8 = adresse_données + index_global
    ADD r8, r8, r7         # r8 += index_vecteur
    
    # Charger les données A et B
    LOADW r9, r8, 0                # r9 = données[index_global + index_vecteur]
    LOADW r10, r8, VECTOR_SIZE     # r10 = données[index_global + index_vecteur + VECTOR_SIZE]
    
    # 1. Addition scalaire
    ADD r11, r9, r10       # r11 = A + B
    
    # 2. Produit scalaire (multiplication puis accumulation)
    MUL r19, r9, r10       # r19 = A * B
    ADD r12, r12, r19      # Accumuler le produit
    
    # 3. Somme des éléments (accumulation de A + B)
    ADD r13, r13, r11      # Accumuler la somme
    
    # 4. Minimum et maximum
    CMP r18, 0
    BRANCH EQ, update_min_max
    
    # Initialiser min et max au premier élément
    MOV r14, r9            # min = premier élément de A
    MOV r15, r9            # max = premier élément de A
    MOVI r18, 0            # Désactiver l'indicateur d'initialisation
    BRANCH AL, continue_scalar
    
update_min_max:
    # Mettre à jour le minimum
    CMP r9, r14
    BRANCH GE, check_max
    MOV r14, r9            # Nouveau minimum trouvé
    
check_max:
    # Mettre à jour le maximum
    CMP r9, r15
    BRANCH LE, continue_scalar
    MOV r15, r9            # Nouveau maximum trouvé
    
continue_scalar:
    ADDI r7, r7, 1         # Incrémenter l'index de vecteur
    BRANCH AL, scalar_loop

store_scalar_results:
    # Calculer la moyenne
    DIV r16, r13, VECTOR_SIZE  # r16 = somme / taille
    
    # Stocker les résultats
    ADD r17, r4, r6        # r17 = adresse_résultats + index_global
    STOREW r12, r17, 0     # résultat[index] = produit_scalaire
    STOREW r13, r17, 1     # résultat[index+1] = somme
    STOREW r14, r17, 2     # résultat[index+2] = minimum
    STOREW r15, r17, 3     # résultat[index+3] = maximum
    STOREW r16, r17, 4     # résultat[index+4] = moyenne
    
    # Passer aux éléments suivants
    ADDI r6, r6, VECTOR_SIZE
    BRANCH AL, scalar_processing

end:
    HALT