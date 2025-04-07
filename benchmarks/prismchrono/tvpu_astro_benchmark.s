# Benchmark: TVPU Astronomical Operations
# Évaluation des performances des instructions vectorielles ternaires pour les calculs astronomiques
# Ce benchmark compare les opérations vectorielles optimisées aux opérations scalaires équivalentes

# Définition des constantes
.equ VECTOR_SIZE, 8       # Nombre d'éléments dans un vecteur ternaire
.equ ARRAY_SIZE, 32       # Nombre total d'éléments à traiter
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ VECTOR_A_ADDR, 0x1200 # Adresse du vecteur A (coordonnées)
.equ VECTOR_B_ADDR, 0x1300 # Adresse du vecteur B (temps)
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

# Partie 1: Traitement vectoriel avec TVPU optimisé pour l'astronomie
vector_processing:
    # Vérifier si on a traité tous les éléments
    CMP r6, r5
    BRANCH GE, scalar_init # Si index >= nombre d'éléments, passer à la partie suivante
    
    # Charger les vecteurs A et B depuis la mémoire
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
    # Effectuer les opérations vectorielles astronomiques
    # 1. Conversion DMS (Degrés, Minutes, Secondes)
    TVBASE60_ENCODE V0, V1  # V0 = encode_base60(V1)
    
    # 2. Addition en base 60 (pour les coordonnées)
    TVBASE60_ADD V1, V1, V2  # V1 = V1 + V2 (addition en base 60)
    
    # 3. Calcul de l'angle horaire (temps sidéral - ascension droite)
    TVBASE60_SUB V2, V1, V2  # V2 = V1 - V2 (soustraction en base 60)
    
    # 4. Calcul de la précession (correction astronomique)
    # Simuler un calcul de précession avec une valeur constante
    MOVI r12, 50           # 50.3 secondes d'arc par an
    MOVI r13, 10           # 10 ans
    MUL r14, r12, r13      # r14 = 50 * 10 = 500 secondes d'arc
    
    # Créer un vecteur de précession
    MOVI r15, 0            # Degrés
    MOVI r16, 8            # Minutes (8 minutes et 20 secondes = 500 secondes)
    MOVI r17, 20           # Secondes
    
    # Appliquer la précession
    TVBASE60_ENCODE V3, r15, r16, r17  # Encoder la précession en base 60
    TVBASE60_ADD V0, V0, V3            # Ajouter la précession aux coordonnées
    
    # 5. Calcul de la réfraction atmosphérique
    # Simuler un calcul de réfraction avec une valeur dépendant de l'altitude
    TVMIN r18, V0          # r18 = altitude minimale
    MOVI r19, 34           # 34 minutes d'arc (réfraction maximale à l'horizon)
    
    # Appliquer la réfraction
    MOVI r20, 0            # Degrés
    MOV r21, r19           # Minutes (valeur calculée)
    MOVI r22, 0            # Secondes
    
    TVBASE60_ENCODE V4, r20, r21, r22  # Encoder la réfraction en base 60
    TVBASE60_ADD V0, V0, V4            # Ajouter la réfraction aux coordonnées
    
    # Stocker les résultats
    ADD r23, r4, r6        # r23 = adresse_résultats + index_global
    
    # Stocker les différents résultats des calculs astronomiques
    STOREW V0, r23, 0      # Coordonnées avec précession et réfraction
    STOREW V1, r23, 8      # Coordonnées additionnées
    STOREW V2, r23, 16     # Angle horaire
    
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
    
    # Charger les données
    ADD r7, r1, r6         # r7 = adresse_données + index
    LOADW r8, r7, 0        # r8 = données[index] (coordonnée)
    LOADW r9, r7, VECTOR_SIZE # r9 = données[index + VECTOR_SIZE] (temps)
    
    # 1. Conversion en DMS (scalaire)
    # Extraire les composantes de r8
    ANDI r10, r8, 0xFF     # r10 = secondes
    SHIFTR r11, r8, 8
    ANDI r11, r11, 0xFF    # r11 = minutes
    SHIFTR r12, r8, 16
    ANDI r12, r12, 0xFF    # r12 = degrés
    
    # 2. Addition en base 60 (scalaire)
    # Extraire les composantes de r9
    ANDI r13, r9, 0xFF     # r13 = secondes
    SHIFTR r14, r9, 8
    ANDI r14, r14, 0xFF    # r14 = minutes
    SHIFTR r15, r9, 16
    ANDI r15, r15, 0xFF    # r15 = degrés
    
    # Additionner les secondes
    ADD r16, r10, r13      # r16 = secondes_totales
    MOVI r20, 60
    DIV r17, r16, r20      # r17 = retenue_minutes
    MOD r16, r16, r20      # r16 = secondes_résultat
    
    # Additionner les minutes avec la retenue
    ADD r18, r11, r14      # r18 = minutes_totales
    ADD r18, r18, r17      # Ajouter la retenue
    DIV r19, r18, r20      # r19 = retenue_degrés
    MOD r18, r18, r20      # r18 = minutes_résultat
    
    # Additionner les degrés avec la retenue
    ADD r20, r12, r15      # r20 = degrés_totaux
    ADD r20, r20, r19      # Ajouter la retenue
    
    # Recombiner le résultat
    SHIFTL r20, r20, 16    # Positionner les degrés
    SHIFTL r18, r18, 8     # Positionner les minutes
    OR r21, r20, r18       # Combiner degrés et minutes
    OR r21, r21, r16       # Ajouter les secondes
    
    # 3. Soustraction en base 60 (scalaire) - Angle horaire
    # Réutiliser les composantes extraites précédemment
    
    # Soustraire les secondes avec emprunt si nécessaire
    CMP r10, r13
    BRANCH GE, no_borrow_seconds
    SUBI r11, r11, 1       # Emprunter une minute
    ADDI r10, r10, 60      # Ajouter 60 secondes
    
no_borrow_seconds:
    SUB r22, r10, r13      # r22 = secondes_résultat
    
    # Soustraire les minutes avec emprunt si nécessaire
    CMP r11, r14
    BRANCH GE, no_borrow_minutes
    SUBI r12, r12, 1       # Emprunter un degré
    ADDI r11, r11, 60      # Ajouter 60 minutes
    
no_borrow_minutes:
    SUB r23, r11, r14      # r23 = minutes_résultat
    
    # Soustraire les degrés
    SUB r24, r12, r15      # r24 = degrés_résultat
    
    # Recombiner le résultat
    SHIFTL r24, r24, 16    # Positionner les degrés
    SHIFTL r23, r23, 8     # Positionner les minutes
    OR r25, r24, r23       # Combiner degrés et minutes
    OR r25, r25, r22       # Ajouter les secondes
    
    # 4. Calcul de la précession (scalaire)
    MOVI r26, 500          # 500 secondes d'arc (50.3 * 10 ans)
    MOVI r27, 0            # Degrés
    MOVI r28, 8            # Minutes
    MOVI r29, 20           # Secondes
    
    # Additionner la précession aux coordonnées (réutiliser le code d'addition)
    # Pour simplifier, on ajoute directement au résultat précédent
    ADD r16, r22, r29      # Ajouter les secondes
    MOVI r20, 60
    DIV r17, r16, r20      # Calculer la retenue
    MOD r16, r16, r20      # Secondes résultat
    
    ADD r18, r23, r28      # Ajouter les minutes
    ADD r18, r18, r17      # Ajouter la retenue
    DIV r19, r18, r20      # Calculer la retenue
    MOD r18, r18, r20      # Minutes résultat
    
    ADD r20, r24, r27      # Ajouter les degrés
    ADD r20, r20, r19      # Ajouter la retenue
    
    # Recombiner le résultat
    SHIFTL r20, r20, 16    # Positionner les degrés
    SHIFTL r18, r18, 8     # Positionner les minutes
    OR r30, r20, r18       # Combiner degrés et minutes
    OR r30, r30, r16       # Ajouter les secondes
    
    # Stocker les résultats
    ADD r31, r4, r6        # r31 = adresse_résultats_scalaires + index
    STOREW r21, r31, 0     # Stocker le résultat de l'addition
    STOREW r25, r31, 1     # Stocker le résultat de la soustraction
    STOREW r30, r31, 2     # Stocker le résultat avec précession
    
    # Passer à l'élément suivant
    ADDI r6, r6, 1
    BRANCH AL, scalar_processing

end:
    # Fin du programme
    HALT