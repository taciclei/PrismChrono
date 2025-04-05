/**
 * Benchmark: Sum Array
 * Calcule la somme des éléments d'un tableau d'entiers
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define ARRAY_SIZE 100

// Fonction principale du benchmark
int64_t sum_array(int64_t *array, size_t size) {
    int64_t sum = 0;
    
    for (size_t i = 0; i < size; i++) {
        sum += array[i];
    }
    
    return sum;
}

int main() {
    // Allocation et initialisation du tableau
    int64_t *array = (int64_t *)malloc(ARRAY_SIZE * sizeof(int64_t));
    if (!array) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        return 1;
    }
    
    // Initialisation avec les mêmes valeurs que dans la version PrismChrono
    for (size_t i = 0; i < ARRAY_SIZE; i++) {
        array[i] = i + 1; // Valeurs de 1 à ARRAY_SIZE
    }
    
    // Exécution du benchmark
    int64_t result = sum_array(array, ARRAY_SIZE);
    
    // Affichage du résultat (pour vérification)
    printf("Somme: %ld\n", result);
    
    // Libération de la mémoire
    free(array);
    
    return 0;
}