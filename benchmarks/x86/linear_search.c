/**
 * Benchmark: Linear Search
 * Recherche de la première occurrence d'une valeur dans un tableau
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define ARRAY_SIZE 100
#define SEARCH_VALUE 42

// Fonction principale du benchmark
int linear_search(int64_t *array, size_t size, int64_t value) {
    for (size_t i = 0; i < size; i++) {
        if (array[i] == value) {
            return i;
        }
    }
    
    return -1; // Valeur non trouvée
}

int main() {
    // Allocation et initialisation du tableau
    int64_t *array = (int64_t *)malloc(ARRAY_SIZE * sizeof(int64_t));
    if (!array) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        return 1;
    }
    
    // Initialisation du tableau avec des valeurs aléatoires
    for (size_t i = 0; i < ARRAY_SIZE; i++) {
        array[i] = i * 2; // Valeurs paires
    }
    
    // Placer la valeur recherchée à un index aléatoire
    int random_index = rand() % ARRAY_SIZE;
    array[random_index] = SEARCH_VALUE;
    
    // Exécution du benchmark
    int result = linear_search(array, ARRAY_SIZE, SEARCH_VALUE);
    
    // Affichage du résultat (pour vérification)
    printf("Valeur %ld trouvée à l'index %d\n", (int64_t)SEARCH_VALUE, result);
    
    // Libération de la mémoire
    free(array);
    
    return 0;
}