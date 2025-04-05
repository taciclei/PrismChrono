/**
 * Benchmark: Special States
 * Implémentation d'un automate à états finis utilisant la logique ternaire
 * Ce benchmark est conçu pour mettre en évidence les avantages de la logique ternaire
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define INPUT_SIZE 100

// États ternaires
#define STATE_NEGATIVE -1
#define STATE_ZERO 0
#define STATE_POSITIVE 1

// Structure pour l'automate
typedef struct {
    int8_t current_state;
} StateMachine;

// Fonction de transition d'état
int8_t transition(int8_t current_state, int8_t input) {
    // Table de transition simplifiée pour démontrer la logique ternaire
    if (current_state == STATE_NEGATIVE) {
        if (input == STATE_NEGATIVE) return STATE_NEGATIVE;
        if (input == STATE_ZERO) return STATE_ZERO;
        if (input == STATE_POSITIVE) return STATE_ZERO;
    } 
    else if (current_state == STATE_ZERO) {
        if (input == STATE_NEGATIVE) return STATE_NEGATIVE;
        if (input == STATE_ZERO) return STATE_ZERO;
        if (input == STATE_POSITIVE) return STATE_POSITIVE;
    }
    else if (current_state == STATE_POSITIVE) {
        if (input == STATE_NEGATIVE) return STATE_ZERO;
        if (input == STATE_ZERO) return STATE_POSITIVE;
        if (input == STATE_POSITIVE) return STATE_POSITIVE;
    }
    
    // État par défaut en cas d'erreur
    return STATE_ZERO;
}

// Fonction principale du benchmark
int8_t process_inputs(const int8_t *inputs, size_t size) {
    StateMachine machine = {STATE_ZERO}; // État initial
    
    for (size_t i = 0; i < size; i++) {
        machine.current_state = transition(machine.current_state, inputs[i]);
    }
    
    return machine.current_state;
}

int main() {
    // Allocation et initialisation des entrées
    int8_t *inputs = (int8_t *)malloc(INPUT_SIZE * sizeof(int8_t));
    if (!inputs) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        return 1;
    }
    
    // Initialisation avec des valeurs ternaires aléatoires
    for (size_t i = 0; i < INPUT_SIZE; i++) {
        int random_value = rand() % 3 - 1; // -1, 0, ou 1
        inputs[i] = (int8_t)random_value;
    }
    
    // Exécution du benchmark
    int8_t final_state = process_inputs(inputs, INPUT_SIZE);
    
    // Affichage du résultat (pour vérification)
    printf("État final: %d\n", final_state);
    
    // Libération de la mémoire
    free(inputs);
    
    return 0;
}