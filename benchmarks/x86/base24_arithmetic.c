/**
 * Benchmark: Base24 Arithmetic
 * Implémentation d'opérations arithmétiques en base 24
 * Ce benchmark est conçu pour mettre en évidence les avantages de la logique ternaire
 * dans les calculs avec des bases non conventionnelles
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Définition des constantes
#define OPERATIONS_COUNT 1000
#define BASE 24

// Structure pour représenter un nombre en base 24
typedef struct {
    uint8_t digits[8]; // 8 chiffres en base 24
    size_t size;        // Nombre de chiffres utilisés
} Base24Number;

// Initialiser un nombre en base 24 à partir d'un entier
void init_base24(Base24Number *number, uint32_t value) {
    size_t i = 0;
    
    // Convertir en base 24
    while (value > 0 && i < 8) {
        number->digits[i] = value % BASE;
        value /= BASE;
        i++;
    }
    
    number->size = (i > 0) ? i : 1; // Au moins un chiffre
    
    // Remplir le reste avec des zéros
    while (i < 8) {
        number->digits[i] = 0;
        i++;
    }
}

// Addition de deux nombres en base 24
Base24Number add_base24(const Base24Number *a, const Base24Number *b) {
    Base24Number result;
    uint8_t carry = 0;
    size_t max_size = (a->size > b->size) ? a->size : b->size;
    
    for (size_t i = 0; i < max_size; i++) {
        uint8_t sum = a->digits[i] + b->digits[i] + carry;
        if (sum >= BASE) {
            result.digits[i] = sum - BASE;
            carry = 1;
        } else {
            result.digits[i] = sum;
            carry = 0;
        }
    }
    
    // Gérer la retenue finale
    if (carry && max_size < 8) {
        result.digits[max_size] = 1;
        result.size = max_size + 1;
    } else {
        result.size = max_size;
    }
    
    // Remplir le reste avec des zéros
    for (size_t i = result.size; i < 8; i++) {
        result.digits[i] = 0;
    }
    
    return result;
}

// Multiplication de deux nombres en base 24
Base24Number multiply_base24(const Base24Number *a, const Base24Number *b) {
    Base24Number result;
    
    // Initialiser le résultat à zéro
    for (size_t i = 0; i < 8; i++) {
        result.digits[i] = 0;
    }
    result.size = 1;
    
    // Multiplication chiffre par chiffre
    for (size_t i = 0; i < a->size; i++) {
        for (size_t j = 0; j < b->size && i + j < 8; j++) {
            uint16_t product = a->digits[i] * b->digits[j];
            uint8_t carry = 0;
            
            // Ajouter le produit au résultat
            size_t pos = i + j;
            while (product > 0 || carry > 0) {
                if (pos >= 8) break; // Éviter le débordement
                
                uint16_t sum = result.digits[pos] + product % BASE + carry;
                result.digits[pos] = sum % BASE;
                carry = sum / BASE;
                product /= BASE;
                pos++;
                
                if (pos > result.size) {
                    result.size = pos;
                }
            }
        }
    }
    
    return result;
}

// Convertir un nombre en base 24 en entier
uint32_t base24_to_int(const Base24Number *number) {
    uint32_t result = 0;
    uint32_t multiplier = 1;
    
    for (size_t i = 0; i < number->size; i++) {
        result += number->digits[i] * multiplier;
        multiplier *= BASE;
    }
    
    return result;
}

int main() {
    // Initialiser les nombres pour les opérations
    Base24Number a, b, result_add, result_mul;
    init_base24(&a, 42);
    init_base24(&b, 24);
    
    // Exécuter les opérations plusieurs fois pour le benchmark
    for (int i = 0; i < OPERATIONS_COUNT; i++) {
        // Addition
        result_add = add_base24(&a, &b);
        
        // Multiplication
        result_mul = multiply_base24(&a, &b);
        
        // Utiliser les résultats pour éviter l'optimisation
        a = result_add;
        b = result_mul;
    }
    
    // Afficher les résultats finaux (pour vérification)
    printf("Résultat final addition: %u\n", base24_to_int(&result_add));
    printf("Résultat final multiplication: %u\n", base24_to_int(&result_mul));
    
    return 0;
}