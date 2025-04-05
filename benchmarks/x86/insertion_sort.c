/**
 * Benchmark: Insertion Sort
 * Tri d'un tableau d'entiers par la méthode d'insertion
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define ARRAY_SIZE 100

// Fonction de tri par insertion
void insertion_sort(int64_t *array, size_t size) {
    for (size_t i = 1; i < size; i++) {
        int64_t key = array[i];
        int j = i - 1;
        
        // Déplacer les éléments du tableau[0..i-1] qui sont plus grands que key
        // vers une position en avant de leur position actuelle
        while (j >= 0 && array[j] > key) {
            array[j + 1] = array[j];
            j = j - 1;
        }
        array[j + 1] = key;
    }
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
        array[i] = rand() % 1000;
    }
    
    // Exécution du benchmark
    insertion_sort(array, ARRAY_SIZE);
    
    // Vérification que le tableau est trié (pour validation)
    for (size_t i = 1; i < ARRAY_SIZE; i++) {
        if (array[i] < array[i-1]) {
            fprintf(stderr, "Erreur: Le tableau n'est pas correctement trié\n");
            free(array);
            return 1;
        }
    }
    
    // Affichage du résultat (pour vérification)
    printf("Tableau trié avec succès\n");
    
    // Libération de la mémoire
    free(array);
    
    return 0;
}