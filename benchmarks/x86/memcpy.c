/**
 * Benchmark: Memcpy
 * Copie un bloc de mémoire d'une zone source vers une zone destination
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define BLOCK_SIZE 100

// Fonction de copie mémoire
void *my_memcpy(void *dest, const void *src, size_t n) {
    int64_t *d = (int64_t *)dest;
    const int64_t *s = (const int64_t *)src;
    
    // Copie Word par Word (équivalent à la version PrismChrono)
    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
    
    return dest;
}

int main() {
    // Allocation des blocs source et destination
    int64_t *src = (int64_t *)malloc(BLOCK_SIZE * sizeof(int64_t));
    int64_t *dest = (int64_t *)malloc(BLOCK_SIZE * sizeof(int64_t));
    
    if (!src || !dest) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        return 1;
    }
    
    // Initialisation du bloc source avec des valeurs de test
    for (size_t i = 0; i < BLOCK_SIZE; i++) {
        src[i] = i + 1; // Valeurs de 1 à BLOCK_SIZE
    }
    
    // Exécution du benchmark
    my_memcpy(dest, src, BLOCK_SIZE);
    
    // Vérification (optionnelle)
    int valid = 1;
    for (size_t i = 0; i < BLOCK_SIZE; i++) {
        if (dest[i] != src[i]) {
            valid = 0;
            break;
        }
    }
    
    printf("Copie %s\n", valid ? "réussie" : "échouée");
    
    // Libération de la mémoire
    free(src);
    free(dest);
    
    return 0;
}