/**
 * Benchmark: Factorial
 * Calcule la factorielle d'un nombre de manière itérative
 */

#include <stdio.h>
#include <stdint.h>

// Définition des constantes
#define N 10

// Fonction de calcul de factorielle
int64_t factorial(int n) {
    int64_t result = 1;
    
    for (int i = 1; i <= n; i++) {
        result *= i;
    }
    
    return result;
}

int main() {
    // Exécution du benchmark
    int64_t result = factorial(N);
    
    // Affichage du résultat (pour vérification)
    printf("%d! = %ld\n", N, result);
    
    return 0;
}