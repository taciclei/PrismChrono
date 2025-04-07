# Benchmark: Predictive Cache
# Évaluation des performances du cache prédictif ternaire
# Ce benchmark compare les accès mémoire avec cache prédictif ternaire aux approches conventionnelles

# Définition des constantes
.equ ARRAY_SIZE, 1024     # Taille du tableau principal
.equ ACCESS_COUNT, 100    # Nombre d'accès mémoire à effectuer
.equ DATA_ADDR, 0x1000    # Adresse des données
.equ PATTERN_ADDR, 0x2000 # Adresse des motifs d'accès
.equ RESULT_ADDR, 0x3000  # Adresse des résultats
.equ CACHE_SIZE, 64       # Taille du cache simulé

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR     # Adresse des données
    MOVI r2, PATTERN_ADDR  # Adresse des motifs d'accès
    MOVI r3, RESULT_ADDR   # Adresse des résultats
    MOVI r4, ACCESS_COUNT  # Nombre d'accès à effectuer
    MOVI r5, 0             # Index courant

# Partie 1: Accès mémoire avec cache prédictif ternaire
predictive_cache_access:
    # Vérifier si on a effectué tous les accès
    CMP r5, r4
    BRANCH GE, tree_traversal_init  # Si index >= nombre d'accès, passer à la partie suivante
    
    # Charger le motif d'accès courant
    ADD r6, r2, r5         # r6 = adresse_motifs + index
    LOADW r7, r6, 0        # r7 = motif d'accès
    
    # Calculer l'adresse à accéder
    ADD r8, r1, r7         # r8 = adresse_données + offset
    
    # Activer le mode cache prédictif ternaire
    # Dans un cas réel, cela serait fait via un registre de contrôle spécial
    # Ici, on simule l'activation avec une instruction spéciale
    SETCACHEMODE r0, 1     # Activer le mode cache prédictif
    
    # Effectuer l'accès mémoire avec prédiction ternaire
    # Le cache prédictif va anticiper les accès futurs en utilisant la logique ternaire
    LOADW r9, r8, 0        # r9 = données[offset]
    
    # Stocker le résultat
    ADD r10, r3, r5        # r10 = adresse_résultats + index
    STOREW r9, r10, 0      # résultats[index] = valeur
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, predictive_cache_access  # Continuer la boucle

# Partie 2: Traversée d'arbre avec cache prédictif
tree_traversal_init:
    # Réinitialiser l'index
    MOVI r5, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats
    MOVI r6, RESULT_ADDR
    ADDI r6, r6, ACCESS_COUNT  # Décaler pour ne pas écraser les résultats précédents
    
    # Adresse de la racine de l'arbre (simulée dans la zone de données)
    MOVI r7, DATA_ADDR
    ADDI r7, r7, ARRAY_SIZE / 2  # Milieu du tableau comme racine

tree_traversal_loop:
    # Vérifier si on a effectué tous les accès
    CMP r5, r4
    BRANCH GE, graph_traversal_init  # Si index >= nombre d'accès, passer à la partie suivante
    
    # Charger le motif d'accès courant (direction de traversée)
    ADD r8, r2, r5         # r8 = adresse_motifs + index
    LOADW r9, r8, 0        # r9 = motif d'accès
    
    # Activer le mode cache prédictif ternaire
    SETCACHEMODE r0, 1     # Activer le mode cache prédictif
    
    # Traverser l'arbre en fonction de la direction
    # r9 < 0: aller à gauche, r9 = 0: rester, r9 > 0: aller à droite
    MOVI r10, 0
    CMP r9, r10
    BRANCH3 r9, go_left, stay_node, go_right

go_left:
    # Calculer l'adresse du nœud enfant gauche
    LOADW r11, r7, 0       # r11 = adresse du nœud courant
    SUBI r11, r11, 1       # r11 -= 1 (aller à gauche)
    ADD r7, r1, r11        # r7 = adresse_données + offset
    BRANCH AL, process_node

stay_node:
    # Rester au nœud courant
    BRANCH AL, process_node

go_right:
    # Calculer l'adresse du nœud enfant droit
    LOADW r11, r7, 0       # r11 = adresse du nœud courant
    ADDI r11, r11, 1       # r11 += 1 (aller à droite)
    ADD r7, r1, r11        # r7 = adresse_données + offset

process_node:
    # Charger la valeur du nœud
    LOADW r12, r7, 0       # r12 = valeur du nœud
    
    # Stocker le résultat
    ADD r13, r6, r5        # r13 = adresse_résultats + index
    STOREW r12, r13, 0     # résultats[index] = valeur
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, tree_traversal_loop  # Continuer la boucle

# Partie 3: Parcours de graphe avec cache prédictif
graph_traversal_init:
    # Réinitialiser l'index
    MOVI r5, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats
    MOVI r6, RESULT_ADDR
    ADDI r6, r6, ACCESS_COUNT * 2  # Décaler pour ne pas écraser les résultats précédents
    
    # Adresse du premier nœud du graphe
    MOVI r7, DATA_ADDR

graph_traversal_loop:
    # Vérifier si on a effectué tous les accès
    CMP r5, r4
    BRANCH GE, conventional_init  # Si index >= nombre d'accès, passer à la partie suivante
    
    # Activer le mode cache prédictif ternaire avec niveau de confiance
    # Le niveau de confiance est utilisé pour prédire les accès futurs
    # -1: improbable, 0: incertain, 1: probable
    SETCACHEMODE r0, 2     # Activer le mode cache prédictif avec niveau de confiance
    
    # Charger le nœud courant
    LOADW r8, r7, 0        # r8 = valeur du nœud
    
    # Charger les adresses des voisins (simulées)
    LOADW r9, r7, 1        # r9 = adresse du voisin 1
    LOADW r10, r7, 2       # r10 = adresse du voisin 2
    LOADW r11, r7, 3       # r11 = adresse du voisin 3
    
    # Charger le motif d'accès courant (choix du voisin)
    ADD r12, r2, r5        # r12 = adresse_motifs + index
    LOADW r13, r12, 0      # r13 = motif d'accès
    
    # Choisir le voisin en fonction du motif
    MOVI r14, 3
    MOD r13, r13, r14      # r13 = r13 % 3 (pour avoir une valeur entre 0 et 2)
    
    MOVI r14, 0
    CMP r13, r14
    BRANCH EQ, choose_neighbor1
    
    MOVI r14, 1
    CMP r13, r14
    BRANCH EQ, choose_neighbor2
    
    # Sinon, choisir le voisin 3
    ADD r7, r1, r11        # r7 = adresse_données + offset_voisin3
    BRANCH AL, store_graph_result

choose_neighbor1:
    ADD r7, r1, r9         # r7 = adresse_données + offset_voisin1
    BRANCH AL, store_graph_result

choose_neighbor2:
    ADD r7, r1, r10        # r7 = adresse_données + offset_voisin2

store_graph_result:
    # Stocker le résultat
    ADD r14, r6, r5        # r14 = adresse_résultats + index
    STOREW r8, r14, 0      # résultats[index] = valeur du nœud
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, graph_traversal_loop  # Continuer la boucle

# Partie 4: Approche conventionnelle pour comparaison
conventional_init:
    # Réinitialiser l'index
    MOVI r5, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats conventionnels
    MOVI r6, RESULT_ADDR
    ADDI r6, r6, ACCESS_COUNT * 3  # Décaler pour ne pas écraser les résultats précédents

conventional_access:
    # Vérifier si on a effectué tous les accès
    CMP r5, r4
    BRANCH GE, done        # Si index >= nombre d'accès, terminer
    
    # Désactiver le cache prédictif
    SETCACHEMODE r0, 0     # Désactiver le mode cache prédictif
    
    # Charger le motif d'accès courant
    ADD r7, r2, r5         # r7 = adresse_motifs + index
    LOADW r8, r7, 0        # r8 = motif d'accès
    
    # Calculer l'adresse à accéder
    ADD r9, r1, r8         # r9 = adresse_données + offset
    
    # Effectuer l'accès mémoire conventionnel
    LOADW r10, r9, 0       # r10 = données[offset]
    
    # Stocker le résultat
    ADD r11, r6, r5        # r11 = adresse_résultats_conv + index
    STOREW r10, r11, 0     # résultats_conv[index] = valeur
    
    # Incrémenter l'index
    ADDI r5, r5, 1
    BRANCH AL, conventional_access  # Continuer la boucle

done:
    # Fin du benchmark
    HALT