# Benchmark: Neural Network Ternary
# Évaluation des performances des instructions de réseaux de neurones ternaires
# Ce benchmark compare les opérations de réseaux de neurones ternaires aux approches conventionnelles

# Définition des constantes
.equ INPUT_SIZE, 16       # Taille du vecteur d'entrée
.equ HIDDEN_SIZE, 8       # Taille de la couche cachée
.equ OUTPUT_SIZE, 4       # Taille de la couche de sortie
.equ BATCH_SIZE, 10       # Nombre d'échantillons à traiter
.equ FILTER_SIZE, 3       # Taille du filtre de convolution
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ WEIGHTS_ADDR, 0x1200 # Adresse des poids
.equ RESULT_ADDR, 0x1400  # Adresse des résultats
.equ CONV_RESULT_ADDR, 0x1600  # Adresse des résultats conventionnels

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR     # Adresse des données
    MOVI r2, WEIGHTS_ADDR  # Adresse des poids
    MOVI r3, RESULT_ADDR   # Adresse des résultats
    MOVI r4, INPUT_SIZE    # Taille de l'entrée
    MOVI r5, HIDDEN_SIZE   # Taille de la couche cachée
    MOVI r6, OUTPUT_SIZE   # Taille de la couche de sortie
    MOVI r7, BATCH_SIZE    # Nombre d'échantillons
    MOVI r8, 0             # Index d'échantillon courant

# Partie 1: Inférence de réseau de neurones avec instructions ternaires spécialisées
ternary_nn_inference:
    # Vérifier si on a traité tous les échantillons
    CMP r8, r7
    BRANCH GE, conv2d_init  # Si index >= nombre d'échantillons, passer à la partie suivante
    
    # Calculer les adresses pour l'échantillon courant
    MUL r9, r8, r4         # r9 = index * taille_entrée
    ADD r10, r1, r9        # r10 = adresse_données + offset (adresse de l'échantillon courant)
    
    # Calculer l'adresse de destination pour les résultats
    MUL r11, r8, r6        # r11 = index * taille_sortie
    ADD r12, r3, r11       # r12 = adresse_résultats + offset
    
    # Couche cachée - Utiliser TNEURON pour calculer les activations
    MOVI r13, 0            # Index pour la couche cachée
    
hidden_layer_loop:
    CMP r13, r5
    BRANCH GE, output_layer  # Si index >= taille de la couche cachée, passer à la couche de sortie
    
    # Calculer l'adresse des poids pour le neurone courant
    MUL r14, r13, r4       # r14 = index_neurone * taille_entrée
    ADD r15, r2, r14       # r15 = adresse_poids + offset
    
    # Utiliser l'instruction TNEURON pour calculer l'activation du neurone
    # Cette instruction effectue la somme pondérée et applique la fonction d'activation
    TNEURON r16, r10, r15  # r16 = activation du neurone (entrées, poids)
    
    # Stocker le résultat dans une zone temporaire
    ADD r17, r12, r13      # r17 = adresse_résultats + index_neurone
    STOREW r16, r17, 0     # résultats_temp[index_neurone] = activation
    
    # Incrémenter l'index
    ADDI r13, r13, 1
    BRANCH AL, hidden_layer_loop  # Continuer la boucle

output_layer:
    # Couche de sortie - Utiliser TNEURON pour calculer les sorties finales
    MOVI r13, 0            # Index pour la couche de sortie
    
output_layer_loop:
    CMP r13, r6
    BRANCH GE, next_sample  # Si index >= taille de la couche de sortie, passer à l'échantillon suivant
    
    # Calculer l'adresse des poids pour le neurone de sortie courant
    MUL r14, r13, r5       # r14 = index_neurone * taille_couche_cachée
    ADD r14, r14, r4 * r5  # Ajouter l'offset pour les poids de la couche cachée
    ADD r15, r2, r14       # r15 = adresse_poids + offset
    
    # Utiliser l'instruction TNEURON pour calculer l'activation du neurone de sortie
    TNEURON r16, r12, r15  # r16 = activation du neurone de sortie (entrées de la couche cachée, poids)
    
    # Stocker le résultat final
    ADD r17, r12, r13      # r17 = adresse_résultats + index_neurone
    STOREW r16, r17, 0     # résultats[index_neurone] = activation
    
    # Incrémenter l'index
    ADDI r13, r13, 1
    BRANCH AL, output_layer_loop  # Continuer la boucle

next_sample:
    # Passer à l'échantillon suivant
    ADDI r8, r8, 1
    BRANCH AL, ternary_nn_inference  # Continuer avec l'échantillon suivant

# Partie 2: Convolution 2D avec instructions ternaires spécialisées
conv2d_init:
    # Réinitialiser l'index d'échantillon
    MOVI r8, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats de convolution
    MOVI r9, RESULT_ADDR
    ADDI r9, r9, BATCH_SIZE * OUTPUT_SIZE  # Décaler pour ne pas écraser les résultats précédents

conv2d_loop:
    # Vérifier si on a traité tous les échantillons
    CMP r8, r7
    BRANCH GE, attention_init  # Si index >= nombre d'échantillons, passer à la partie suivante
    
    # Calculer les adresses pour l'échantillon courant
    MUL r10, r8, r4        # r10 = index * taille_entrée
    ADD r11, r1, r10       # r11 = adresse_données + offset
    
    # Calculer l'adresse de destination pour les résultats
    MUL r12, r8, r4        # r12 = index * taille_entrée (même taille pour simplifier)
    ADD r13, r9, r12       # r13 = adresse_résultats_conv + offset
    
    # Utiliser l'instruction TCONV2D pour effectuer la convolution 2D
    # Cette instruction applique un filtre de convolution à une entrée 2D
    TCONV2D r13, r11, r2   # Convolution 2D ternaire (destination, source, filtre)
    
    # Incrémenter l'index d'échantillon
    ADDI r8, r8, 1
    BRANCH AL, conv2d_loop  # Continuer avec l'échantillon suivant

# Partie 3: Mécanisme d'attention avec instructions ternaires spécialisées
attention_init:
    # Réinitialiser l'index d'échantillon
    MOVI r8, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats d'attention
    MOVI r9, RESULT_ADDR
    ADDI r9, r9, BATCH_SIZE * (OUTPUT_SIZE + INPUT_SIZE)  # Décaler pour ne pas écraser les résultats précédents

attention_loop:
    # Vérifier si on a traité tous les échantillons
    CMP r8, r7
    BRANCH GE, conventional_init  # Si index >= nombre d'échantillons, passer à la partie suivante
    
    # Calculer les adresses pour l'échantillon courant
    MUL r10, r8, r4        # r10 = index * taille_entrée
    ADD r11, r1, r10       # r11 = adresse_données + offset
    
    # Calculer l'adresse de destination pour les résultats
    MUL r12, r8, r6        # r12 = index * taille_sortie
    ADD r13, r9, r12       # r13 = adresse_résultats_attn + offset
    
    # Utiliser l'instruction TATTN pour appliquer le mécanisme d'attention
    # Cette instruction implémente un mécanisme d'attention pour transformers
    # Les paramètres sont: destination, query, key, value
    TATTN r13, r11, r2, r11  # Attention ternaire (destination, query, key, value)
    
    # Incrémenter l'index d'échantillon
    ADDI r8, r8, 1
    BRANCH AL, attention_loop  # Continuer avec l'échantillon suivant

# Partie 4: Approche conventionnelle pour comparaison
conventional_init:
    # Réinitialiser l'index d'échantillon
    MOVI r8, 0
    MOVI r9, CONV_RESULT_ADDR  # Adresse des résultats conventionnels

conv_nn_inference:
    # Vérifier si on a traité tous les échantillons
    CMP r8, r7
    BRANCH GE, done        # Si index >= nombre d'échantillons, terminer
    
    # Calculer les adresses pour l'échantillon courant
    MUL r10, r8, r4        # r10 = index * taille_entrée
    ADD r11, r1, r10       # r11 = adresse_données + offset
    
    # Calculer l'adresse de destination pour les résultats
    MUL r12, r8, r6        # r12 = index * taille_sortie
    ADD r13, r9, r12       # r13 = adresse_résultats_conv + offset
    
    # Couche cachée - Implémentation conventionnelle
    MOVI r14, 0            # Index pour la couche cachée
    
conv_hidden_layer_loop:
    CMP r14, r5
    BRANCH GE, conv_output_layer  # Si index >= taille de la couche cachée, passer à la couche de sortie
    
    # Calculer la somme pondérée manuellement
    MOVI r15, 0            # Index pour les entrées
    MOVI r16, 0            # Accumulateur pour la somme pondérée
    
conv_weighted_sum_loop:
    CMP r15, r4
    BRANCH GE, conv_activation  # Si index >= taille de l'entrée, appliquer l'activation
    
    # Calculer les adresses
    ADD r17, r11, r15      # r17 = adresse_entrée + index
    
    # Calculer l'adresse du poids
    MUL r18, r14, r4       # r18 = index_neurone * taille_entrée
    ADD r18, r18, r15      # r18 += index_entrée
    ADD r18, r2, r18       # r18 = adresse_poids + offset
    
    # Charger les valeurs
    LOADW r19, r17, 0      # r19 = entrée[index]
    LOADW r20, r18, 0      # r20 = poids[index_neurone][index_entrée]
    
    # Multiplier et accumuler
    MUL r19, r19, r20      # r19 = entrée * poids
    ADD r16, r16, r19      # Accumuler
    
    # Incrémenter l'index
    ADDI r15, r15, 1
    BRANCH AL, conv_weighted_sum_loop  # Continuer la boucle
    
conv_activation:
    # Appliquer une fonction d'activation simple (ReLU)
    MOVI r17, 0
    CMP r16, r17
    BRANCH LT, conv_relu_zero  # Si somme < 0, mettre à 0
    BRANCH AL, conv_store_activation  # Sinon, garder la valeur
    
conv_relu_zero:
    MOVI r16, 0
    
conv_store_activation:
    # Stocker l'activation dans une zone temporaire
    ADD r17, r13, r14      # r17 = adresse_résultats_temp + index_neurone
    STOREW r16, r17, 0     # résultats_temp[index_neurone] = activation
    
    # Incrémenter l'index
    ADDI r14, r14, 1
    BRANCH AL, conv_hidden_layer_loop  # Continuer la boucle

conv_output_layer:
    # Couche de sortie - Implémentation conventionnelle
    MOVI r14, 0            # Index pour la couche de sortie
    
conv_output_layer_loop:
    CMP r14, r6
    BRANCH GE, conv_next_sample  # Si index >= taille de la couche de sortie, passer à l'échantillon suivant
    
    # Calculer la somme pondérée manuellement
    MOVI r15, 0            # Index pour les entrées de la couche cachée
    MOVI r16, 0            # Accumulateur pour la somme pondérée
    
conv_output_weighted_sum_loop:
    CMP r15, r5
    BRANCH GE, conv_output_activation  # Si index >= taille de la couche cachée, appliquer l'activation
    
    # Calculer les adresses
    ADD r17, r13, r15      # r17 = adresse_résultats_temp + index
    
    # Calculer l'adresse du poids
    MUL r18, r14, r5       # r18 = index_neurone * taille_couche_cachée
    ADD r18, r18, r15      # r18 += index_entrée
    ADD r18, r18, r4 * r5  # Ajouter l'offset pour les poids de la couche cachée
    ADD r18, r2, r18       # r18 = adresse_poids + offset
    
    # Charger les valeurs
    LOADW r19, r17, 0      # r19 = entrée_cachée[index]
    LOADW r20, r18, 0      # r20 = poids[index_neurone][index_entrée]
    
    # Multiplier et accumuler
    MUL r19, r19, r20      # r19 = entrée * poids
    ADD r16, r16, r19      # Accumuler
    
    # Incrémenter l'index
    ADDI r15, r15, 1
    BRANCH AL, conv_output_weighted_sum_loop  # Continuer la boucle
    
conv_output_activation:
    # Appliquer une fonction d'activation simple (ReLU)
    MOVI r17, 0
    CMP r16, r17
    BRANCH LT, conv_output_relu_zero  # Si somme < 0, mettre à 0
    BRANCH AL, conv_store_output  # Sinon, garder la valeur
    
conv_output_relu_zero:
    MOVI r16, 0
    
conv_store_output:
    # Stocker le résultat final
    ADD r17, r13, r14      # r17 = adresse_résultats_conv + index_neurone
    STOREW r16, r17, 0     # résultats_conv[index_neurone] = activation
    
    # Incrémenter l'index
    ADDI r14, r14, 1
    BRANCH AL, conv_output_layer_loop  # Continuer la boucle

conv_next_sample:
    # Passer à l'échantillon suivant
    ADDI r8, r8, 1
    BRANCH AL, conv_nn_inference  # Continuer avec l'échantillon suivant

done:
    # Fin du benchmark
    HALT