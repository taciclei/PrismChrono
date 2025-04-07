# Benchmark: Ternary Data Compression
# Évaluation des performances des instructions de compression de données ternaires
# Ce benchmark compare les opérations de compression/décompression ternaires aux approches conventionnelles

# Définition des constantes
.equ DATA_SIZE, 256       # Taille des données à compresser
.equ COMPRESSED_SIZE, 128 # Taille maximale des données compressées
.equ DATA_ADDR, 0x1000    # Adresse des données d'entrée
.equ COMPRESSED_ADDR, 0x1200  # Adresse des données compressées
.equ DECOMPRESSED_ADDR, 0x1400  # Adresse des données décompressées
.equ RESULT_ADDR, 0x1600  # Adresse des résultats de performance
.equ ITERATIONS, 10       # Nombre d'itérations pour les tests

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR         # Adresse des données
    MOVI r2, COMPRESSED_ADDR   # Adresse des données compressées
    MOVI r3, DECOMPRESSED_ADDR # Adresse des données décompressées
    MOVI r4, RESULT_ADDR       # Adresse des résultats
    MOVI r5, DATA_SIZE         # Taille des données
    MOVI r6, COMPRESSED_SIZE   # Taille maximale des données compressées
    MOVI r7, ITERATIONS        # Nombre d'itérations
    MOVI r8, 0                 # Compteur d'itérations

# Partie 1: Compression de données avec instructions ternaires spécialisées
ternary_compression:
    # Vérifier si on a effectué toutes les itérations
    CMP r8, r7
    BRANCH GE, decompression_init  # Si compteur >= itérations, passer à la partie suivante
    
    # Calculer les adresses pour l'itération courante
    MUL r9, r8, r5             # r9 = itération * taille_données
    ADD r10, r1, r9            # r10 = adresse_données + offset
    
    MUL r11, r8, r6            # r11 = itération * taille_compressée
    ADD r12, r2, r11           # r12 = adresse_compressée + offset
    
    # Utiliser l'instruction TCOMPRESS pour compresser les données
    # Cette instruction compresse les données en exploitant la représentation ternaire
    TCOMPRESS r12, r10, r5     # Compression ternaire (destination, source, taille)
    
    # Stocker la taille des données compressées dans les résultats
    MUL r13, r8, 4             # r13 = itération * 4 (taille d'un mot)
    ADD r14, r4, r13           # r14 = adresse_résultats + offset
    
    # La taille compressée est retournée dans r0
    STOREW r0, r14, 0          # résultats[itération] = taille_compressée
    
    # Incrémenter le compteur d'itérations
    ADDI r8, r8, 1
    BRANCH AL, ternary_compression  # Continuer la boucle

# Partie 2: Décompression de données avec instructions ternaires spécialisées
decompression_init:
    # Réinitialiser le compteur d'itérations
    MOVI r8, 0

ternary_decompression:
    # Vérifier si on a effectué toutes les itérations
    CMP r8, r7
    BRANCH GE, text_compression_init  # Si compteur >= itérations, passer à la partie suivante
    
    # Calculer les adresses pour l'itération courante
    MUL r9, r8, r6             # r9 = itération * taille_compressée
    ADD r10, r2, r9            # r10 = adresse_compressée + offset
    
    MUL r11, r8, r5            # r11 = itération * taille_données
    ADD r12, r3, r11           # r12 = adresse_décompressée + offset
    
    # Charger la taille des données compressées
    MUL r13, r8, 4             # r13 = itération * 4 (taille d'un mot)
    ADD r14, r4, r13           # r14 = adresse_résultats + offset
    LOADW r15, r14, 0          # r15 = taille_compressée
    
    # Utiliser l'instruction TDECOMPRESS pour décompresser les données
    # Cette instruction décompresse les données compressées en format ternaire
    TDECOMPRESS r12, r10, r15  # Décompression ternaire (destination, source, taille_compressée)
    
    # Incrémenter le compteur d'itérations
    ADDI r8, r8, 1
    BRANCH AL, ternary_decompression  # Continuer la boucle

# Partie 3: Compression de texte avec instructions ternaires spécialisées
text_compression_init:
    # Réinitialiser le compteur d'itérations
    MOVI r8, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats
    MOVI r9, RESULT_ADDR
    ADDI r9, r9, ITERATIONS * 4  # Décaler pour ne pas écraser les résultats précédents

text_compression:
    # Vérifier si on a effectué toutes les itérations
    CMP r8, r7
    BRANCH GE, image_compression_init  # Si compteur >= itérations, passer à la partie suivante
    
    # Calculer les adresses pour l'itération courante
    MUL r10, r8, r5            # r10 = itération * taille_données
    ADD r11, r1, r10           # r11 = adresse_données + offset
    
    MUL r12, r8, r6            # r12 = itération * taille_compressée
    ADD r13, r2, r12           # r13 = adresse_compressée + offset
    
    # Utiliser l'instruction TCOMPRESS avec mode texte
    # Cette instruction est optimisée pour la compression de texte en ternaire
    MOVI r14, 1                # Mode 1 = compression de texte
    TCOMPRESS r13, r11, r5, r14  # Compression ternaire de texte
    
    # Stocker la taille des données compressées dans les résultats
    MUL r15, r8, 4             # r15 = itération * 4 (taille d'un mot)
    ADD r16, r9, r15           # r16 = adresse_résultats_texte + offset
    STOREW r0, r16, 0          # résultats_texte[itération] = taille_compressée
    
    # Incrémenter le compteur d'itérations
    ADDI r8, r8, 1
    BRANCH AL, text_compression  # Continuer la boucle

# Partie 4: Compression d'image avec instructions ternaires spécialisées
image_compression_init:
    # Réinitialiser le compteur d'itérations
    MOVI r8, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats
    MOVI r9, RESULT_ADDR
    ADDI r9, r9, ITERATIONS * 8  # Décaler pour ne pas écraser les résultats précédents

image_compression:
    # Vérifier si on a effectué toutes les itérations
    CMP r8, r7
    BRANCH GE, conventional_init  # Si compteur >= itérations, passer à la partie suivante
    
    # Calculer les adresses pour l'itération courante
    MUL r10, r8, r5            # r10 = itération * taille_données
    ADD r11, r1, r10           # r11 = adresse_données + offset
    
    MUL r12, r8, r6            # r12 = itération * taille_compressée
    ADD r13, r2, r12           # r13 = adresse_compressée + offset
    
    # Utiliser l'instruction TCOMPRESS avec mode image
    # Cette instruction est optimisée pour la compression d'image en ternaire
    MOVI r14, 2                # Mode 2 = compression d'image
    TCOMPRESS r13, r11, r5, r14  # Compression ternaire d'image
    
    # Stocker la taille des données compressées dans les résultats
    MUL r15, r8, 4             # r15 = itération * 4 (taille d'un mot)
    ADD r16, r9, r15           # r16 = adresse_résultats_image + offset
    STOREW r0, r16, 0          # résultats_image[itération] = taille_compressée
    
    # Incrémenter le compteur d'itérations
    ADDI r8, r8, 1
    BRANCH AL, image_compression  # Continuer la boucle

# Partie 5: Approche conventionnelle pour comparaison
conventional_init:
    # Réinitialiser le compteur d'itérations
    MOVI r8, 0
    
    # Calculer la nouvelle adresse de destination pour les résultats conventionnels
    MOVI r9, RESULT_ADDR
    ADDI r9, r9, ITERATIONS * 12  # Décaler pour ne pas écraser les résultats précédents

conventional_compression:
    # Vérifier si on a effectué toutes les itérations
    CMP r8, r7
    BRANCH GE, done        # Si compteur >= itérations, terminer
    
    # Calculer les adresses pour l'itération courante
    MUL r10, r8, r5            # r10 = itération * taille_données
    ADD r11, r1, r10           # r11 = adresse_données + offset
    
    MUL r12, r8, r6            # r12 = itération * taille_compressée
    ADD r13, r2, r12           # r13 = adresse_compressée + offset
    
    # Simuler une compression conventionnelle (RLE simplifié)
    MOVI r14, 0                # Index source
    MOVI r15, 0                # Index destination
    MOVI r16, 0                # Compteur de répétitions
    MOVI r17, 0                # Valeur précédente
    MOVI r18, 1                # Indicateur de première itération

conv_compress_loop:
    # Vérifier si on a parcouru toutes les données
    CMP r14, r5
    BRANCH GE, conv_compress_end  # Si index >= taille des données, terminer
    
    # Charger la valeur courante
    ADD r19, r11, r14          # r19 = adresse_données + index
    LOADW r20, r19, 0          # r20 = données[index]
    
    # Vérifier si c'est la première itération
    CMP r18, 1
    BRANCH EQ, conv_compress_first
    
    # Vérifier si la valeur est identique à la précédente
    CMP r20, r17
    BRANCH EQ, conv_compress_same
    
    # Valeur différente, stocker le compteur et la valeur précédente
    ADD r19, r13, r15          # r19 = adresse_compressée + index_dest
    STOREW r16, r19, 0         # compressées[index_dest] = compteur
    ADDI r15, r15, 1           # Incrémenter index_dest
    
    ADD r19, r13, r15          # r19 = adresse_compressée + index_dest
    STOREW r17, r19, 0         # compressées[index_dest] = valeur_précédente
    ADDI r15, r15, 1           # Incrémenter index_dest
    
    # Réinitialiser le compteur et mettre à jour la valeur précédente
    MOVI r16, 1                # Compteur = 1
    MOV r17, r20               # Valeur précédente = valeur courante
    BRANCH AL, conv_compress_next

conv_compress_first:
    # Première itération, initialiser les valeurs
    MOVI r16, 1                # Compteur = 1
    MOV r17, r20               # Valeur précédente = valeur courante
    MOVI r18, 0                # Plus la première itération
    BRANCH AL, conv_compress_next

conv_compress_same:
    # Valeur identique, incrémenter le compteur
    ADDI r16, r16, 1

conv_compress_next:
    # Passer à la donnée suivante
    ADDI r14, r14, 1
    BRANCH AL, conv_compress_loop

conv_compress_end:
    # Stocker le dernier groupe
    ADD r19, r13, r15          # r19 = adresse_compressée + index_dest
    STOREW r16, r19, 0         # compressées[index_dest] = compteur
    ADDI r15, r15, 1           # Incrémenter index_dest
    
    ADD r19, r13, r15          # r19 = adresse_compressée + index_dest
    STOREW r17, r19, 0         # compressées[index_dest] = valeur_précédente
    ADDI r15, r15, 1           # Incrémenter index_dest
    
    # Stocker la taille des données compressées dans les résultats
    MUL r19, r8, 4             # r19 = itération * 4 (taille d'un mot)
    ADD r20, r9, r19           # r20 = adresse_résultats_conv + offset
    STOREW r15, r20, 0         # résultats_conv[itération] = taille_compressée
    
    # Incrémenter le compteur d'itérations
    ADDI r8, r8, 1
    BRANCH AL, conventional_compression  # Continuer la boucle

done:
    # Fin du benchmark
    HALT