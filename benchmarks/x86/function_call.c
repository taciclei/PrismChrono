/**
 * Benchmark: Function Call
 * Mesure les performances des appels de fonction
 */

#include <stdio.h>
#include <stdint.h>

// Définition des constantes
#define CALL_COUNT 1000

// Fonction simple à appeler
int64_t simple_function(int64_t a, int64_t b) {
    return a + b;
}

// Fonction qui appelle une autre fonction plusieurs fois
int64_t call_function_multiple_times(int64_t a, int64_t b, int count) {
    int64_t result = 0;
    
    for (int i = 0; i < count; i++) {
        result += simple_function(a, b);
    }
    
    return result;
}

int main() {
    // Paramètres pour les appels de fonction
    int64_t a = 5;
    int64_t b = 10;
    
    // Exécution du benchmark
    int64_t result = call_function_multiple_times(a, b, CALL_COUNT);
    
    // Affichage du résultat (pour vérification)
    printf("Résultat après %d appels: %ld\n", CALL_COUNT, result);
    
    return 0;
}