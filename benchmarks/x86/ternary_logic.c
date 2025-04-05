/**
 * Benchmark: Ternary Logic
 * Implémentation d'un système de vote à trois états (Positif/Zéro/Négatif)
 * Ce benchmark est conçu pour mettre en évidence les avantages de la logique ternaire
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define ARRAY_SIZE 50

// Valeurs ternaires
#define NEGATIVE -1
#define ZERO 0
#define POSITIVE 1

// Fonction principale du benchmark
int ternary_vote(const int8_t *votes, size_t size) {
    int positive_count = 0;
    int negative_count = 0;
    int zero_count = 0;
    
    // Compter les différents types de votes
    for (size_t i = 0; i < size; i++) {
        if (votes[i] == POSITIVE) {
            positive_count++;
        } else if (votes[i] == NEGATIVE) {
            negative_count++;
        } else { // ZERO ou autre valeur
            zero_count++;
        }
    }
    
    // Déterminer le résultat du vote
    // Règle: majorité simple (plus de votes positifs que négatifs = accepté)
    if (positive_count > negative_count) {
        return POSITIVE;
    } else if (positive_count < negative_count) {
        return NEGATIVE;
    } else {
        return ZERO; // Égalité
    }
}

int main() {
    // Allocation et initialisation du tableau de votes
    int8_t *votes = (int8_t *)malloc(ARRAY_SIZE * sizeof(int8_t));
    if (!votes) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        return 1;
    }
    
    // Initialisation avec des votes aléatoires (-1, 0, 1)
    for (size_t i = 0; i < ARRAY_SIZE; i++) {
        votes[i] = (rand() % 3) - 1; // Valeurs: -1, 0, 1
    }
    
    // Exécution du benchmark
    int result = ternary_vote(votes, ARRAY_SIZE);
    
    // Compter les votes pour vérification
    int positive_count = 0;
    int negative_count = 0;
    int zero_count = 0;
    
    for (size_t i = 0; i < ARRAY_SIZE; i++) {
        if (votes[i] == POSITIVE) {
            positive_count++;
        } else if (votes[i] == NEGATIVE) {
            negative_count++;
        } else {
            zero_count++;
        }
    }
    
    // Affichage du résultat (pour vérification)
    printf("Résultat du vote: %d\n", result);
    printf("Votes positifs: %d\n", positive_count);
    printf("Votes négatifs: %d\n", negative_count);
    printf("Abstentions: %d\n", zero_count);
    
    // Libération de la mémoire
    free(votes);
    
    return 0;
}