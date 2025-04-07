# Benchmark: Base60 Arithmetic (Système Sexagésimal)
# Calculs exploitant la base 60 pour les applications liées au temps
# Ce benchmark démontre les avantages de l'architecture ternaire pour les calculs temporels

# Définition des constantes
.equ OPERATIONS_COUNT, 30  # Nombre d'opérations à effectuer
.equ DATA_ADDR, 0x1000     # Adresse des données d'entrée
.equ RESULT_ADDR, 0x1200   # Adresse des résultats

# Constantes pour la base 60
.equ BASE60, 60            # Base de calcul sexagésimale (minutes, secondes)
.equ BASE24, 24            # Base pour les heures
.equ BASE12, 12            # Base pour format 12h AM/PM
.equ BASE7, 7              # Base pour les jours de la semaine
.equ BASE365, 365          # Base pour les jours de l'année
.equ BASE360, 360          # Base pour les degrés d'un cercle

# Section de données
.section .data
# Les données seront initialisées par le simulateur ou le script d'exécution

# Section de code
.section .text
.global _start

_start:
    # Initialisation des registres
    MOVI r1, DATA_ADDR      # Adresse des données
    MOVI r2, RESULT_ADDR    # Adresse des résultats
    MOVI r3, OPERATIONS_COUNT # Nombre d'opérations
    MOVI r4, 0              # Index courant

# Partie 1: Calculs en base 60 avec optimisations ternaires avancées
base60_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, time_conversion_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (représentant des heures, minutes, secondes)
    LOADW r7, r5, 0        # r7 = données[index] (premier opérande)
    LOADW r8, r5, 1        # r8 = données[index+1] (deuxième opérande)
    
    # Effectuer les calculs en base 60 avec optimisations ternaires avancées
    # 1. Extraction des composantes temporelles (heures, minutes, secondes)
    # Utilisation des propriétés ternaires pour extraire efficacement
    
    # Optimisation: Utilisation de LOADT3 pour charger 3 trits consécutifs
    # Extraction des secondes (trits 0-2)
    LOADT3 r9, 0(r7)       # Charge les 3 premiers trits (pour les secondes)
    
    # Conversion optimisée des trits en valeur décimale
    # Utilisation de TSHIFTL pour calculer les puissances de 3 plus efficacement
    MOVI r10, 1            # Valeur de base
    TSHIFTL r11, r10, 1    # r11 = 1 << 1 = 3 (en ternaire)
    TSHIFTL r12, r10, 2    # r12 = 1 << 2 = 9 (en ternaire)
    
    # Extraire les trits individuels
    TRIT_EXTRACT r13, r9, 0 # Premier trit
    TRIT_EXTRACT r14, r9, 1 # Deuxième trit
    TRIT_EXTRACT r15, r9, 2 # Troisième trit
    
    # Calculer la valeur en base 60 pour les secondes
    MUL r14, r14, r11      # r14 = deuxième trit * 3
    MUL r15, r15, r12      # r15 = troisième trit * 9
    ADD r9, r13, r14       # Combiner les valeurs
    ADD r9, r9, r15        # r9 contient maintenant les secondes
    
    # Extraction des minutes (trits 3-5) avec la même optimisation
    LOADT3 r10, 3(r7)      # Charge les trits 3-5 (pour les minutes)
    
    # Extraire les trits individuels pour les minutes
    TRIT_EXTRACT r13, r10, 0 # Premier trit (trit 3 du mot)
    TRIT_EXTRACT r14, r10, 1 # Deuxième trit (trit 4 du mot)
    TRIT_EXTRACT r15, r10, 2 # Troisième trit (trit 5 du mot)
    
    # Calculer la valeur en base 60 pour les minutes
    MUL r14, r14, r11      # r14 = deuxième trit * 3
    MUL r15, r15, r12      # r15 = troisième trit * 9
    ADD r10, r13, r14      # Combiner les valeurs
    ADD r10, r10, r15      # r10 contient maintenant les minutes
    
    # Extraction des heures (trits 6-8) avec la même optimisation
    LOADT3 r11, 6(r7)      # Charge les trits 6-8 (pour les heures)
    
    # Extraire les trits individuels pour les heures
    TRIT_EXTRACT r13, r11, 0 # Premier trit (trit 6 du mot)
    TRIT_EXTRACT r14, r11, 1 # Deuxième trit (trit 7 du mot)
    TRIT_EXTRACT r15, r11, 2 # Troisième trit (trit 8 du mot)
    
    # Calculer la valeur en base 24 pour les heures
    MUL r14, r14, r11      # r14 = deuxième trit * 3
    MUL r15, r15, r12      # r15 = troisième trit * 9
    ADD r11, r13, r14      # Combiner les valeurs
    ADD r11, r11, r15      # r11 contient maintenant les heures
    
    # Faire de même pour le deuxième opérande avec les mêmes optimisations
    # Extraction des secondes (trits 0-2)
    LOADT3 r12, 0(r8)      # Charge les 3 premiers trits (pour les secondes)
    
    # Extraire les trits individuels
    TRIT_EXTRACT r13, r12, 0 # Premier trit
    TRIT_EXTRACT r14, r12, 1 # Deuxième trit
    TRIT_EXTRACT r15, r12, 2 # Troisième trit
    
    # Calculer la valeur en base 60 pour les secondes
    MUL r14, r14, r11      # r14 = deuxième trit * 3 (r11 contient déjà 3)
    MUL r15, r15, r12      # r15 = troisième trit * 9 (r12 contient déjà 9)
    ADD r12, r13, r14      # Combiner les valeurs
    ADD r12, r12, r15      # r12 contient maintenant les secondes du deuxième opérande
    
    # Extraction des minutes (trits 3-5)
    LOADT3 r13, 3(r8)      # Charge les trits 3-5 (pour les minutes)
    
    # Extraire les trits individuels pour les minutes
    TRIT_EXTRACT r14, r13, 0 # Premier trit (trit 3 du mot)
    TRIT_EXTRACT r15, r13, 1 # Deuxième trit (trit 4 du mot)
    TRIT_EXTRACT r16, r13, 2 # Troisième trit (trit 5 du mot)
    
    # Calculer la valeur en base 60 pour les minutes
    MUL r15, r15, r11      # r15 = deuxième trit * 3
    MUL r16, r16, r12      # r16 = troisième trit * 9
    ADD r13, r14, r15      # Combiner les valeurs
    ADD r13, r13, r16      # r13 contient maintenant les minutes du deuxième opérande
    
    # Extraction des heures (trits 6-8)
    LOADT3 r14, 6(r8)      # Charge les trits 6-8 (pour les heures)
    
    # Extraire les trits individuels pour les heures
    TRIT_EXTRACT r15, r14, 0 # Premier trit (trit 6 du mot)
    TRIT_EXTRACT r16, r14, 1 # Deuxième trit (trit 7 du mot)
    TRIT_EXTRACT r17, r14, 2 # Troisième trit (trit 8 du mot)
    
    # Calculer la valeur en base 24 pour les heures
    MUL r16, r16, r11      # r16 = deuxième trit * 3
    MUL r17, r17, r12      # r17 = troisième trit * 9
    ADD r14, r15, r16      # Combiner les valeurs
    ADD r14, r14, r17      # r14 contient maintenant les heures du deuxième opérande
    
    # 2. Effectuer l'addition des composantes temporelles
    ADD r15, r9, r12       # Addition des secondes
    ADD r16, r10, r13      # Addition des minutes
    ADD r17, r11, r14      # Addition des heures
    
    # 3. Normalisation des résultats (gestion des retenues)
    # Normaliser les secondes
    MOVI r18, BASE60
    DIV r19, r15, r18      # r19 = r15 / 60 (quotient - retenue pour les minutes)
    MOD r15, r15, r18      # r15 = r15 % 60 (reste - secondes normalisées)
    
    # Ajouter la retenue aux minutes
    ADD r16, r16, r19
    
    # Normaliser les minutes
    DIV r19, r16, r18      # r19 = r16 / 60 (quotient - retenue pour les heures)
    MOD r16, r16, r18      # r16 = r16 % 60 (reste - minutes normalisées)
    
    # Ajouter la retenue aux heures
    ADD r17, r17, r19
    
    # Normaliser les heures (modulo 24)
    MOVI r18, BASE24
    MOD r17, r17, r18      # r17 = r17 % 24 (heures normalisées)
    
    # 4. Stocker les résultats
    STOREW r15, r6, 0      # Stocker les secondes
    STOREW r16, r6, 1      # Stocker les minutes
    STOREW r17, r6, 2      # Stocker les heures
    
    # Passer à l'opération suivante
    ADDI r4, r4, 3
    BRANCH AL, base60_loop

# Partie 2: Conversions temporelles spécifiques
time_conversion_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

time_conversion_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, calendar_calc_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (format 24h)
    LOADW r7, r5, 0        # r7 = heures format 24h
    
    # Conversion 24h -> 12h AM/PM
    MOVI r8, 12
    CMP r7, r8
    BRANCH LT, store_am     # Si heures < 12, c'est AM
    
    # PM: Soustraire 12 si > 12
    CMP r7, r8
    BRANCH EQ, store_pm_noon # Si heures = 12, c'est midi (12 PM)
    
    # Heures > 12, soustraire 12
    SUB r7, r7, r8
    MOVI r9, 1              # Indicateur PM (1)
    BRANCH AL, store_result
    
store_am:
    # AM: Si heures = 0, c'est minuit (12 AM)
    MOVI r10, 0
    CMP r7, r10
    BRANCH NE, am_not_midnight
    
    MOVI r7, 12            # Minuit = 12 AM
    
am_not_midnight:
    MOVI r9, 0              # Indicateur AM (0)
    BRANCH AL, store_result
    
store_pm_noon:
    # Midi = 12 PM
    MOVI r9, 1              # Indicateur PM (1)
    
store_result:
    # Stocker le résultat (heures format 12h et indicateur AM/PM)
    STOREW r7, r6, 0        # Heures format 12h
    STOREW r9, r6, 1        # Indicateur AM/PM
    
    # Passer à l'opération suivante
    ADDI r4, r4, 2
    BRANCH AL, time_conversion_loop

# Partie 3: Calculs calendaires optimisés avec logique ternaire
calendar_calc_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

calendar_calc_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, timezone_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (jour de l'année)
    LOADW r7, r5, 0        # r7 = jour de l'année (1-365)
    LOADW r8, r5, 1        # r8 = année (pour les calculs de bissextile)
    
    # Optimisation ternaire pour le calcul du jour de la semaine
    # Utilisation de la représentation ternaire pour encoder efficacement le jour
    
    # 1. Ajustement pour l'année (calcul bissextile optimisé)
    # Vérifier si l'année est bissextile avec optimisation ternaire
    MOVI r9, 4
    MOD r10, r8, r9        # r10 = année % 4
    MOVI r9, 100
    MOD r11, r8, r9        # r11 = année % 100
    MOVI r9, 400
    MOD r12, r8, r9        # r12 = année % 400
    
    # Règle bissextile: (année % 4 == 0 && année % 100 != 0) || (année % 400 == 0)
    MOVI r13, 0
    CMP r10, r13           # année % 4 == 0 ?
    BRANCH NE, not_leap_year
    
    CMP r11, r13           # année % 100 == 0 ?
    BRANCH NE, is_leap_year
    
    CMP r12, r13           # année % 400 == 0 ?
    BRANCH NE, not_leap_year
    
    # C'est une année bissextile
is_leap_year:
    MOVI r13, 1            # Indicateur d'année bissextile
    BRANCH AL, leap_year_done
    
not_leap_year:
    MOVI r13, 0            # Pas une année bissextile
    
leap_year_done:
    # 2. Ajustement du jour selon l'année bissextile
    MOVI r14, 60           # Seuil pour l'ajustement (après février)
    CMP r7, r14
    BRANCH LT, no_leap_adjustment
    
    # Si on est après février et que c'est une année bissextile, ajuster
    CMP r13, r13
    BRANCH EQ, leap_adjustment
    BRANCH AL, no_leap_adjustment
    
leap_adjustment:
    ADDI r7, r7, 1         # Ajouter un jour pour l'année bissextile
    
no_leap_adjustment:
    # 3. Calcul optimisé du jour de la semaine avec arithmétique ternaire
    # Formule de Zeller adaptée pour l'architecture ternaire
    
    # Utilisation de TRIT_EXTRACT pour décomposer le jour en base ternaire
    # Cela permet d'exploiter la structure naturelle du cycle hebdomadaire (7 jours)
    # 7 = 2*3 + 1, donc on peut représenter efficacement en ternaire
    
    # Décomposition du jour en trits
    MOVI r14, 3
    DIV r15, r7, r14       # r15 = jour / 3
    MOD r16, r7, r14       # r16 = jour % 3 (premier trit)
    
    DIV r17, r15, r14      # r17 = (jour / 3) / 3
    MOD r15, r15, r14      # r15 = (jour / 3) % 3 (deuxième trit)
    
    # Calcul optimisé du jour de la semaine
    MOVI r14, 1
    MUL r15, r15, r14      # Poids du deuxième trit (1*3)
    MOVI r14, 2
    MUL r17, r17, r14      # Poids du troisième trit (2*3^2)
    
    # Combinaison des trits avec poids optimisés pour le modulo 7
    ADD r14, r16, r15      # r14 = premier trit + (deuxième trit * 3)
    ADD r14, r14, r17      # r14 = premier trit + (deuxième trit * 3) + (troisième trit * 2*3^2)
    
    # Calcul final du jour de la semaine (0-6, 0 = dimanche)
    MOVI r15, 7
    MOD r9, r14, r15       # r9 = jour de la semaine (0-6)
    
    # Stocker les résultats
    STOREW r9, r6, 0        # Jour de la semaine
    STOREW r13, r6, 1       # Indicateur d'année bissextile
    
    # Passer à l'opération suivante
    ADDI r4, r4, 2
    BRANCH AL, calendar_calc_loop

# Partie 4: Calculs de fuseaux horaires avec optimisations ternaires
timezone_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

timezone_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, geometry_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (heure locale et décalage de fuseau horaire)
    LOADW r7, r5, 0        # r7 = heure locale (0-23)
    LOADW r8, r5, 1        # r8 = minutes locales (0-59)
    LOADW r9, r5, 2        # r9 = décalage de fuseau horaire en heures (-12 à +14)
    LOADW r10, r5, 3       # r10 = décalage de fuseau horaire en minutes (0, 15, 30, 45)
    
    # Optimisation: Utilisation de TCMP3 pour déterminer le signe du décalage
    MOVI r11, 0
    TCMP3 r12, r9, r11     # r12 = -1 si r9 < 0, 0 si r9 = 0, 1 si r9 > 0
    
    # Conversion de l'heure locale vers l'heure UTC
    # 1. Ajuster les heures
    SUB r13, r7, r9        # r13 = heure locale - décalage en heures
    
    # 2. Ajuster les minutes
    SUB r14, r8, r10       # r14 = minutes locales - décalage en minutes
    
    # 3. Normaliser les minutes (gestion des retenues négatives)
    MOVI r15, 0
    CMP r14, r15
    BRANCH GE, minutes_ok
    
    # Minutes négatives, ajuster
    ADDI r14, r14, 60      # Ajouter 60 minutes
    SUBI r13, r13, 1       # Soustraire 1 heure
    
minutes_ok:
    # 4. Normaliser les heures (modulo 24 avec gestion des valeurs négatives)
    MOVI r15, 0
    CMP r13, r15
    BRANCH GE, hours_positive
    
    # Heures négatives, ajuster
    ADDI r13, r13, 24      # Ajouter 24 heures
    
hours_positive:
    MOVI r15, 24
    MOD r13, r13, r15      # r13 = r13 % 24 (heures normalisées)
    
    # 5. Stocker les résultats (heure UTC)
    STOREW r13, r6, 0      # Heures UTC
    STOREW r14, r6, 1      # Minutes UTC
    
    # Bonus: Calcul du jour suivant/précédent
    MOVI r15, 0
    CMP r7, r13
    BRANCH EQ, same_day    # Si même heure, même jour
    BRANCH GT, check_day_change # Si heure locale > heure UTC, possible changement de jour
    BRANCH LT, check_day_change # Si heure locale < heure UTC, possible changement de jour
    
check_day_change:
    # Déterminer si on a changé de jour
    MOVI r15, 0
    CMP r12, r15
    BRANCH LT, day_forward  # Si décalage négatif, jour suivant possible
    BRANCH GT, day_backward # Si décalage positif, jour précédent possible
    BRANCH AL, same_day     # Si décalage nul, même jour
    
day_forward:
    # Vérifier si on a avancé d'un jour
    CMP r7, r13
    BRANCH GT, next_day    # Si heure locale > heure UTC, jour suivant
    BRANCH AL, same_day
    
day_backward:
    # Vérifier si on a reculé d'un jour
    CMP r7, r13
    BRANCH LT, prev_day    # Si heure locale < heure UTC, jour précédent
    BRANCH AL, same_day
    
next_day:
    MOVI r15, 1            # Indicateur jour suivant
    BRANCH AL, store_day_change
    
prev_day:
    MOVI r15, -1           # Indicateur jour précédent
    BRANCH AL, store_day_change
    
same_day:
    MOVI r15, 0            # Indicateur même jour
    
store_day_change:
    STOREW r15, r6, 2      # Stocker l'indicateur de changement de jour
    
    # Passer à l'opération suivante
    ADDI r4, r4, 4
    BRANCH AL, timezone_loop

# Partie 5: Calculs d'angles en base 60 (degrés, minutes, secondes d'angle - DMS)
angle_dms_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

angle_dms_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, trigonometry_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (angle en notation décimale)
    LOADW r7, r5, 0        # r7 = angle en degrés décimaux (ex: 45.5°)
    
    # Conversion de décimal vers DMS (degrés, minutes, secondes)
    # 1. Extraire la partie entière (degrés)
    FLOOR r8, r7           # r8 = partie entière de r7 (degrés)
    
    # 2. Calculer les minutes (partie fractionnaire * 60)
    SUB r9, r7, r8         # r9 = partie fractionnaire
    MOVI r10, 60
    MUL r9, r9, r10        # r9 = minutes (partie fractionnaire * 60)
    
    # 3. Extraire la partie entière des minutes
    FLOOR r11, r9          # r11 = partie entière de r9 (minutes)
    
    # 4. Calculer les secondes (partie fractionnaire des minutes * 60)
    SUB r12, r9, r11       # r12 = partie fractionnaire des minutes
    MUL r12, r12, r10      # r12 = secondes (partie fractionnaire * 60)
    
    # 5. Arrondir les secondes pour éviter les erreurs de précision
    ROUND r12, r12         # r12 = secondes arrondies
    
    # 6. Normaliser les secondes (si >= 60, ajuster minutes)
    CMP r12, r10
    BRANCH LT, seconds_ok
    
    # Secondes >= 60, ajuster
    SUB r12, r12, r10      # Soustraire 60 secondes
    ADDI r11, r11, 1       # Ajouter 1 minute
    
    # 7. Normaliser les minutes (si >= 60, ajuster degrés)
seconds_ok:
    CMP r11, r10
    BRANCH LT, minutes_ok
    
    # Minutes >= 60, ajuster
    SUB r11, r11, r10      # Soustraire 60 minutes
    ADDI r8, r8, 1         # Ajouter 1 degré
    
minutes_ok:
    # 8. Stocker les résultats (DMS)
    STOREW r8, r6, 0       # Degrés
    STOREW r11, r6, 1      # Minutes
    STOREW r12, r6, 2      # Secondes
    
    # Conversion inverse: DMS vers décimal
    # 1. Convertir les minutes en fraction de degré
    DIV r13, r11, r10      # r13 = minutes / 60
    
    # 2. Convertir les secondes en fraction de degré
    MOVI r14, 3600         # 60 * 60 = 3600
    DIV r15, r12, r14      # r15 = secondes / 3600
    
    # 3. Combiner pour obtenir l'angle décimal
    ADD r16, r8, r13       # r16 = degrés + (minutes/60)
    ADD r16, r16, r15      # r16 = degrés + (minutes/60) + (secondes/3600)
    
    # 4. Stocker le résultat (angle décimal reconverti)
    STOREW r16, r6, 3      # Angle décimal reconverti
    
    # Passer à l'opération suivante
    ADDI r4, r4, 4
    BRANCH AL, angle_dms_loop

# Partie 6: Calculs trigonométriques optimisés pour base 60
trigonometry_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

trigonometry_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, geo_coords_init # Si index >= nombre d'opérations, passer à la partie suivante
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (angle en DMS)
    LOADW r7, r5, 0        # r7 = degrés
    LOADW r8, r5, 1        # r8 = minutes
    LOADW r9, r5, 2        # r9 = secondes
    
    # 1. Convertir l'angle DMS en décimal pour les calculs
    MOVI r10, 60
    DIV r11, r8, r10       # r11 = minutes / 60
    MOVI r12, 3600         # 60 * 60 = 3600
    DIV r13, r9, r12       # r13 = secondes / 3600
    
    ADD r14, r7, r11       # r14 = degrés + (minutes/60)
    ADD r14, r14, r13      # r14 = degrés + (minutes/60) + (secondes/3600)
    
    # 2. Convertir en radians pour les calculs trigonométriques
    # radians = degrés * (PI / 180)
    MOVI r15, 180
    LOADF r16, PI_CONST    # Charger la constante PI
    DIV r17, r16, r15      # r17 = PI / 180
    MUL r18, r14, r17      # r18 = angle en radians
    
    # 3. Calcul optimisé du sinus avec approximation polynomiale ternaire
    # Utilisation d'une approximation polynomiale optimisée pour l'architecture ternaire
    # sin(x) ≈ x - x^3/3! + x^5/5! - x^7/7! + ...
    
    # Calcul de x^3
    MUL r19, r18, r18      # r19 = x^2
    MUL r19, r19, r18      # r19 = x^3
    
    # Calcul de x^3/3!
    MOVI r20, 6            # 3! = 6
    DIV r19, r19, r20      # r19 = x^3/3!
    
    # Calcul de x^5
    MUL r21, r19, r18      # r21 = x^4
    MUL r21, r21, r18      # r21 = x^5
    
    # Calcul de x^5/5!
    MOVI r20, 120          # 5! = 120
    DIV r21, r21, r20      # r21 = x^5/5!
    
    # Approximation du sinus avec 3 termes
    SUB r22, r18, r19      # r22 = x - x^3/3!
    ADD r22, r22, r21      # r22 = x - x^3/3! + x^5/5!
    
    # 4. Calcul optimisé du cosinus avec approximation polynomiale ternaire
    # cos(x) ≈ 1 - x^2/2! + x^4/4! - x^6/6! + ...
    
    # Calcul de x^2/2!
    MUL r23, r18, r18      # r23 = x^2
    MOVI r20, 2            # 2! = 2
    DIV r24, r23, r20      # r24 = x^2/2!
    
    # Calcul de x^4/4!
    MUL r25, r23, r23      # r25 = x^4
    MOVI r20, 24           # 4! = 24
    DIV r25, r25, r20      # r25 = x^4/4!
    
    # Approximation du cosinus avec 3 termes
    MOVI r26, 1
    SUB r26, r26, r24      # r26 = 1 - x^2/2!
    ADD r26, r26, r25      # r26 = 1 - x^2/2! + x^4/4!
    
    # 5. Calcul de la tangente (sin/cos)
    DIV r27, r22, r26      # r27 = sin(x) / cos(x) = tan(x)
    
    # 6. Stocker les résultats
    STOREW r22, r6, 0      # Sinus
    STOREW r26, r6, 1      # Cosinus
    STOREW r27, r6, 2      # Tangente
    
    # 7. Conversion des résultats en notation DMS pour l'affichage
    # Exemple avec le sinus (entre -1 et 1, donc pas directement en DMS)
    # Mais on peut convertir l'angle correspondant à l'arc sinus
    
    # Calcul de l'arc sinus (approximation)
    # arcsin(x) ≈ x + (x^3)/6 + (3*x^5)/40 + ...
    # Valable pour |x| < 0.5
    
    # Limiter à la plage valide pour l'approximation
    MOVI r28, 0.5
    ABS r29, r22           # r29 = |sin|
    CMP r29, r28
    BRANCH GT, skip_arcsin # Si |sin| > 0.5, sauter l'approximation
    
    # Calcul de x^3
    MUL r30, r22, r22      # r30 = x^2
    MUL r30, r30, r22      # r30 = x^3
    
    # Calcul de (x^3)/6
    MOVI r20, 6
    DIV r30, r30, r20      # r30 = (x^3)/6
    
    # Calcul de l'arc sinus approximatif
    ADD r31, r22, r30      # r31 = x + (x^3)/6
    
    # Convertir en degrés
    DIV r31, r31, r17      # r31 = arcsin en degrés
    
    # Convertir en DMS
    FLOOR r7, r31          # r7 = degrés (partie entière)
    SUB r8, r31, r7        # r8 = partie fractionnaire
    MUL r8, r8, r10        # r8 = minutes (partie fractionnaire * 60)
    FLOOR r8, r8           # r8 = minutes (partie entière)
    
    # Stocker le résultat de l'arc sinus en DMS
    STOREW r7, r6, 3       # Degrés de l'arc sinus
    STOREW r8, r6, 4       # Minutes de l'arc sinus
    
skip_arcsin:
    # Passer à l'opération suivante
    ADDI r4, r4, 5
    BRANCH AL, trigonometry_loop

# Partie 7: Calculs de coordonnées géographiques (latitude/longitude en DMS)
geo_coords_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

geo_coords_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, exit        # Si index >= nombre d'opérations, terminer
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les coordonnées en DMS (latitude et longitude de deux points)
    # Point 1: Latitude
    LOADW r7, r5, 0        # r7 = degrés latitude 1
    LOADW r8, r5, 1        # r8 = minutes latitude 1
    LOADW r9, r5, 2        # r9 = secondes latitude 1
    # Point 1: Longitude
    LOADW r10, r5, 3       # r10 = degrés longitude 1
    LOADW r11, r5, 4       # r11 = minutes longitude 1
    LOADW r12, r5, 5       # r12 = secondes longitude 1
    
    # Point 2: Latitude
    LOADW r13, r5, 6       # r13 = degrés latitude 2
    LOADW r14, r5, 7       # r14 = minutes latitude 2
    LOADW r15, r5, 8       # r15 = secondes latitude 2
    # Point 2: Longitude
    LOADW r16, r5, 9       # r16 = degrés longitude 2
    LOADW r17, r5, 10      # r17 = minutes longitude 2
    LOADW r18, r5, 11      # r18 = secondes longitude 2
    
    # 1. Convertir les coordonnées DMS en décimal
    # Latitude 1
    MOVI r19, 60
    DIV r20, r8, r19       # r20 = minutes / 60
    MOVI r21, 3600         # 60 * 60 = 3600
    DIV r22, r9, r21       # r22 = secondes / 3600
    ADD r23, r7, r20       # r23 = degrés + (minutes/60)
    ADD r23, r23, r22      # r23 = degrés + (minutes/60) + (secondes/3600) = latitude 1 en décimal
    
    # Longitude 1
    DIV r20, r11, r19      # r20 = minutes / 60
    DIV r22, r12, r21      # r22 = secondes / 3600
    ADD r24, r10, r20      # r24 = degrés + (minutes/60)
    ADD r24, r24, r22      # r24 = degrés + (minutes/60) + (secondes/3600) = longitude 1 en décimal
    
    # Latitude 2
    DIV r20, r14, r19      # r20 = minutes / 60
    DIV r22, r15, r21      # r22 = secondes / 3600
    ADD r25, r13, r20      # r25 = degrés + (minutes/60)
    ADD r25, r25, r22      # r25 = degrés + (minutes/60) + (secondes/3600) = latitude 2 en décimal
    
    # Longitude 2
    DIV r20, r17, r19      # r20 = minutes / 60
    DIV r22, r18, r21      # r22 = secondes / 3600
    ADD r26, r16, r20      # r26 = degrés + (minutes/60)
    ADD r26, r26, r22      # r26 = degrés + (minutes/60) + (secondes/3600) = longitude 2 en décimal
    
    # 2. Calcul de la distance entre deux points (formule de Haversine simplifiée)
    # Convertir en radians
    LOADF r27, PI_CONST    # Charger la constante PI
    MOVI r28, 180
    DIV r29, r27, r28      # r29 = PI / 180
    
    MUL r30, r23, r29      # r30 = latitude 1 en radians
    MUL r31, r24, r29      # r31 = longitude 1 en radians
    MUL r7, r25, r29       # r7 = latitude 2 en radians
    MUL r8, r26, r29       # r8 = longitude 2 en radians
    
    # Différence de latitude et longitude
    SUB r9, r7, r30        # r9 = diff latitude en radians
    SUB r10, r8, r31       # r10 = diff longitude en radians
    
    # Calcul optimisé avec formule de Haversine
    # a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlong/2)
    # Calcul de sin²(Δlat/2)
    DIV r11, r9, r19        # r11 = Δlat/2
    MUL r12, r11, r11      # r12 = sin²(Δlat/2) (approximation pour petits angles)
    
    # Calcul de sin²(Δlong/2)
    DIV r13, r10, r19       # r13 = Δlong/2
    MUL r14, r13, r13      # r14 = sin²(Δlong/2) (approximation pour petits angles)
    
    # Calcul de cos(lat1) et cos(lat2) avec approximation polynomiale
    # cos(x) ≈ 1 - x²/2! + x⁴/4!
    MUL r15, r30, r30       # r15 = lat1²
    MOVI r16, 2
    DIV r15, r15, r16      # r15 = lat1²/2
    MOVI r17, 1
    SUB r15, r17, r15      # r15 = cos(lat1) approximatif
    
    MUL r16, r7, r7        # r16 = lat2²
    MOVI r17, 2
    DIV r16, r16, r17      # r16 = lat2²/2
    MOVI r17, 1
    SUB r16, r17, r16      # r16 = cos(lat2) approximatif
    
    # Calcul de cos(lat1) * cos(lat2) * sin²(Δlong/2)
    MUL r17, r15, r16      # r17 = cos(lat1) * cos(lat2)
    MUL r17, r17, r14      # r17 = cos(lat1) * cos(lat2) * sin²(Δlong/2)
    
    # Calcul de a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlong/2)
    ADD r18, r12, r17      # r18 = a
    
    # Calcul de la distance: d = 2 * R * asin(√a)
    # où R est le rayon de la Terre (6371 km)
    SQRT r19, r18          # r19 = √a
    
    # Calcul de asin(√a) avec approximation
    # asin(x) ≈ x + (x³)/6 pour |x| < 0.5
    MUL r20, r19, r19      # r20 = (√a)²
    MUL r20, r20, r19      # r20 = (√a)³
    MOVI r21, 6
    DIV r20, r20, r21      # r20 = (√a)³/6
    ADD r20, r19, r20      # r20 = asin(√a) approximatif
    
    # Calcul de la distance finale
    MOVI r21, 6371         # Rayon de la Terre en km
    MOVI r22, 2
    MUL r22, r22, r21      # r22 = 2 * R
    MUL r22, r22, r20      # r22 = 2 * R * asin(√a) = distance en km
    
    # 3. Stocker les résultats
    STOREW r22, r6, 0      # Distance en km
    
    # 4. Calcul du cap (bearing) initial
    # θ = atan2(sin(Δlong) * cos(lat2), cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(Δlong))
    # Calcul de sin(Δlong) * cos(lat2)
    MUL r23, r10, r16      # r23 = sin(Δlong) * cos(lat2) (numérateur)
    
    # Calcul de sin(lat1) et sin(lat2) avec approximation
    # sin(x) ≈ x - x³/6 pour petits angles
    MUL r24, r30, r30      # r24 = lat1²
    MUL r24, r24, r30      # r24 = lat1³
    MOVI r25, 6
    DIV r24, r24, r25      # r24 = lat1³/6
    SUB r24, r30, r24      # r24 = sin(lat1) approximatif
    
    MUL r25, r7, r7        # r25 = lat2²
    MUL r25, r25, r7       # r25 = lat2³
    MOVI r26, 6
    DIV r25, r25, r26      # r25 = lat2³/6
    SUB r25, r7, r25       # r25 = sin(lat2) approximatif
    
    # Calcul de cos(lat1) * sin(lat2)
    MUL r26, r15, r25      # r26 = cos(lat1) * sin(lat2)
    
    # Calcul de sin(lat1) * cos(lat2)
    MUL r27, r24, r16      # r27 = sin(lat1) * cos(lat2)
    
    # Calcul de cos(Δlong) avec approximation
    MUL r28, r10, r10      # r28 = Δlong²
    MOVI r29, 2
    DIV r28, r28, r29      # r28 = Δlong²/2
    MOVI r30, 1
    SUB r28, r30, r28      # r28 = cos(Δlong) approximatif
    
    # Calcul de sin(lat1) * cos(lat2) * cos(Δlong)
    MUL r27, r27, r28      # r27 = sin(lat1) * cos(lat2) * cos(Δlong)
    
    # Calcul du dénominateur: cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(Δlong)
    SUB r26, r26, r27      # r26 = dénominateur
    
    # Calcul de l'arctangente (atan2) avec approximation
    # atan2(y, x) ≈ y/x pour x > 0 et y petit
    DIV r27, r23, r26      # r27 = cap en radians
    
    # Convertir en degrés
    DIV r27, r27, r29      # r27 = cap en degrés
    
    # Normaliser le cap entre 0 et 360 degrés
    MOVI r28, 360
    MOD r27, r27, r28      # r27 = cap normalisé
    
    # Convertir en DMS
    FLOOR r29, r27         # r29 = degrés (partie entière)
    SUB r30, r27, r29      # r30 = partie fractionnaire
    MOVI r31, 60
    MUL r30, r30, r31      # r30 = minutes (partie fractionnaire * 60)
    FLOOR r30, r30         # r30 = minutes (partie entière)
    
    # Stocker le cap en DMS
    STOREW r29, r6, 1      # Degrés du cap
    STOREW r30, r6, 2      # Minutes du cap
    
    # Passer à l'opération suivante
    ADDI r4, r4, 12        # 12 valeurs d'entrée (2 points avec lat/long en DMS)
    BRANCH AL, geo_coords_loop

# Partie 8: Calculs astronomiques en base 60
astronomy_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

astronomy_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, exit        # Si index >= nombre d'opérations, terminer
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (temps sidéral et coordonnées célestes)
    LOADW r7, r5, 0        # r7 = heures temps sidéral
    LOADW r8, r5, 1        # r8 = minutes temps sidéral
    LOADW r9, r5, 2        # r9 = secondes temps sidéral
    
    # Coordonnées célestes en ascension droite (AR)
    LOADW r10, r5, 3       # r10 = heures AR
    LOADW r11, r5, 4       # r11 = minutes AR
    LOADW r12, r5, 5       # r12 = secondes AR
    
    # Coordonnées célestes en déclinaison (DEC)
    LOADW r13, r5, 6       # r13 = degrés DEC
    LOADW r14, r5, 7       # r14 = minutes DEC
    LOADW r15, r5, 8       # r15 = secondes DEC
    
    # 1. Convertir le temps sidéral en angle horaire (en degrés)
    # Temps sidéral en décimal (heures)
    MOVI r16, 60
    DIV r17, r8, r16       # r17 = minutes / 60
    MOVI r18, 3600         # 60 * 60 = 3600
    DIV r19, r9, r18       # r19 = secondes / 3600
    
    ADD r20, r7, r17       # r20 = heures + (minutes/60)
    ADD r20, r20, r19      # r20 = heures + (minutes/60) + (secondes/3600) = temps sidéral en heures
    
    # Convertir en degrés (1 heure = 15 degrés)
    MOVI r21, 15
    MUL r22, r20, r21      # r22 = temps sidéral en degrés
    
    # 2. Convertir l'ascension droite en degrés
    # AR en décimal (heures)
    DIV r17, r11, r16      # r17 = minutes AR / 60
    DIV r19, r12, r18      # r19 = secondes AR / 3600
    
    ADD r23, r10, r17      # r23 = heures + (minutes/60)
    ADD r23, r23, r19      # r23 = heures + (minutes/60) + (secondes/3600) = AR en heures
    
    # Convertir en degrés (1 heure = 15 degrés)
    MUL r23, r23, r21      # r23 = AR en degrés
    
    # 3. Convertir la déclinaison en degrés décimaux
    DIV r17, r14, r16      # r17 = minutes DEC / 60
    DIV r19, r15, r18      # r19 = secondes DEC / 3600
    
    ADD r24, r13, r17      # r24 = degrés + (minutes/60)
    ADD r24, r24, r19      # r24 = degrés + (minutes/60) + (secondes/3600) = DEC en degrés
    
    # 4. Calculer l'angle horaire (AH = temps sidéral - AR)
    SUB r25, r22, r23      # r25 = AH en degrés
    
    # Normaliser l'angle horaire entre 0 et 360 degrés
    MOVI r26, BASE360
    MOD r25, r25, r26      # r25 = AH normalisé
    
    # 5. Convertir les coordonnées équatoriales (AH, DEC) en coordonnées horizontales (azimut, hauteur)
    # Formule simplifiée pour la hauteur:
    # sin(h) = sin(DEC) * sin(LAT) + cos(DEC) * cos(LAT) * cos(AH)
    # où LAT est la latitude de l'observateur (chargée comme paramètre)
    LOADW r27, r5, 9       # r27 = latitude de l'observateur en degrés
    
    # Convertir en radians
    LOADF r28, PI_CONST    # Charger la constante PI
    MOVI r29, 180
    DIV r30, r28, r29      # r30 = PI / 180
    
    MUL r31, r24, r30      # r31 = DEC en radians
    MUL r7, r27, r30       # r7 = LAT en radians
    MUL r8, r25, r30       # r8 = AH en radians
    
    # Calcul de sin(DEC) et sin(LAT) avec approximation
    # sin(x) ≈ x - x³/6 pour petits angles
    MUL r9, r31, r31       # r9 = DEC²
    MUL r9, r9, r31        # r9 = DEC³
    MOVI r10, 6
    DIV r9, r9, r10        # r9 = DEC³/6
    SUB r9, r31, r9        # r9 = sin(DEC) approximatif
    
    MUL r10, r7, r7        # r10 = LAT²
    MUL r10, r10, r7       # r10 = LAT³
    MOVI r11, 6
    DIV r10, r10, r11      # r10 = LAT³/6
    SUB r10, r7, r10       # r10 = sin(LAT) approximatif
    
    # Calcul de cos(DEC) et cos(LAT) avec approximation
    # cos(x) ≈ 1 - x²/2 pour petits angles
    MUL r11, r31, r31      # r11 = DEC²
    MOVI r12, 2
    DIV r11, r11, r12      # r11 = DEC²/2
    MOVI r13, 1
    SUB r11, r13, r11      # r11 = cos(DEC) approximatif
    
    MUL r12, r7, r7        # r12 = LAT²
    MOVI r13, 2
    DIV r12, r12, r13      # r12 = LAT²/2
    MOVI r13, 1
    SUB r12, r13, r12      # r12 = cos(LAT) approximatif
    
    # Calcul de cos(AH) avec approximation
    MUL r13, r8, r8        # r13 = AH²
    MOVI r14, 2
    DIV r13, r13, r14      # r13 = AH²/2
    MOVI r14, 1
    SUB r13, r14, r13      # r13 = cos(AH) approximatif
    
    # Calcul de sin(h) = sin(DEC) * sin(LAT) + cos(DEC) * cos(LAT) * cos(AH)
    MUL r14, r9, r10       # r14 = sin(DEC) * sin(LAT)
    MUL r15, r11, r12      # r15 = cos(DEC) * cos(LAT)
    MUL r15, r15, r13      # r15 = cos(DEC) * cos(LAT) * cos(AH)
    ADD r14, r14, r15      # r14 = sin(h)
    
    # Calcul de la hauteur en radians avec arcsin
    # arcsin(x) ≈ x + x³/6 pour |x| < 0.5
    MUL r15, r14, r14      # r15 = sin(h)²
    MUL r15, r15, r14      # r15 = sin(h)³
    MOVI r16, 6
    DIV r15, r15, r16      # r15 = sin(h)³/6
    ADD r15, r14, r15      # r15 = hauteur en radians
    
    # Convertir en degrés
    DIV r15, r15, r30      # r15 = hauteur en degrés
    
    # Formule simplifiée pour l'azimut:
    # sin(A) = -cos(DEC) * sin(AH) / cos(h)
    # cos(A) = (sin(DEC) - sin(h) * sin(LAT)) / (cos(h) * cos(LAT))
    # A = atan2(sin(A), cos(A))
    
    # Calcul de sin(AH) avec approximation
    # sin(x) ≈ x - x³/6 pour petits angles
    MUL r16, r8, r8        # r16 = AH²
    MUL r16, r16, r8       # r16 = AH³
    MOVI r17, 6
    DIV r16, r16, r17      # r16 = AH³/6
    SUB r16, r8, r16       # r16 = sin(AH) approximatif
    
    # Calcul de cos(h) avec approximation
    MUL r17, r15, r30      # r17 = hauteur en radians
    MUL r18, r17, r17      # r18 = h²
    MOVI r19, 2
    DIV r18, r18, r19      # r18 = h²/2
    MOVI r19, 1
    SUB r18, r19, r18      # r18 = cos(h) approximatif
    
    # Calcul de sin(A) = -cos(DEC) * sin(AH) / cos(h)
    MUL r19, r11, r16      # r19 = cos(DEC) * sin(AH)
    NEG r19, r19           # r19 = -cos(DEC) * sin(AH)
    DIV r19, r19, r18      # r19 = sin(A)
    
    # Calcul de cos(A) = (sin(DEC) - sin(h) * sin(LAT)) / (cos(h) * cos(LAT))
    MUL r20, r14, r10      # r20 = sin(h) * sin(LAT)
    SUB r20, r9, r20       # r20 = sin(DEC) - sin(h) * sin(LAT)
    MUL r21, r18, r12      # r21 = cos(h) * cos(LAT)
    DIV r20, r20, r21      # r20 = cos(A)
    
    # Calcul de l'azimut avec atan2(sin(A), cos(A))
    # Approximation: atan2(y, x) ≈ y/x pour x > 0
    DIV r21, r19, r20      # r21 = azimut en radians
    
    # Convertir en degrés et normaliser entre 0 et 360
    DIV r21, r21, r30      # r21 = azimut en degrés
    MOVI r22, BASE360
    MOD r21, r21, r22      # r21 = azimut normalisé
    
    # 6. Convertir les résultats (hauteur et azimut) en DMS
    # Hauteur en DMS
    FLOOR r23, r15         # r23 = degrés hauteur (partie entière)
    SUB r24, r15, r23      # r24 = partie fractionnaire
    MOVI r25, 60
    MUL r24, r24, r25      # r24 = minutes (partie fractionnaire * 60)
    FLOOR r24, r24         # r24 = minutes hauteur (partie entière)
    
    # Azimut en DMS
    FLOOR r26, r21         # r26 = degrés azimut (partie entière)
    SUB r27, r21, r26      # r27 = partie fractionnaire
    MUL r27, r27, r25      # r27 = minutes (partie fractionnaire * 60)
    FLOOR r27, r27         # r27 = minutes azimut (partie entière)
    
    # 7. Stocker les résultats
    STOREW r23, r6, 0      # Degrés hauteur
    STOREW r24, r6, 1      # Minutes hauteur
    STOREW r26, r6, 2      # Degrés azimut
    STOREW r27, r6, 3      # Minutes azimut
    
    # Passer à l'opération suivante
    ADDI r4, r4, 10        # 10 valeurs d'entrée (temps sidéral, AR, DEC, latitude)
    BRANCH AL, astronomy_loop

# Partie 9: Calculs géométriques en base 60 (angles dans les polygones)
geometry_init:
    MOVI r4, 0              # Réinitialiser l'index
    ADDI r2, r2, OPERATIONS_COUNT # Décaler l'adresse de résultat

geometry_loop:
    # Vérifier si on a effectué toutes les opérations
    CMP r4, r3
    BRANCH GE, exit        # Si index >= nombre d'opérations, terminer
    
    # Calculer l'adresse des opérandes
    ADD r5, r1, r4         # r5 = adresse_données + index
    ADD r6, r2, r4         # r6 = adresse_résultats + index
    
    # Charger les opérandes (angles en DMS et nombre de côtés d'un polygone)
    LOADW r7, r5, 0        # r7 = degrés angle 1
    LOADW r8, r5, 1        # r8 = minutes angle 1
    LOADW r9, r5, 2        # r9 = secondes angle 1
    
    LOADW r10, r5, 3       # r10 = degrés angle 2
    LOADW r11, r5, 4       # r11 = minutes angle 2
    LOADW r12, r5, 5       # r12 = secondes angle 2
    
    LOADW r13, r5, 6       # r13 = nombre de côtés du polygone
    
    # 1. Convertir les angles DMS en décimal
    # Angle 1
    MOVI r14, 60
    DIV r15, r8, r14       # r15 = minutes / 60
    MOVI r16, 3600         # 60 * 60 = 3600
    DIV r17, r9, r16       # r17 = secondes / 3600
    
    ADD r18, r7, r15       # r18 = degrés + (minutes/60)
    ADD r18, r18, r17      # r18 = degrés + (minutes/60) + (secondes/3600) = angle 1 en décimal
    
    # Angle 2
    DIV r15, r11, r14      # r15 = minutes / 60
    DIV r17, r12, r16      # r17 = secondes / 3600
    
    ADD r19, r10, r15      # r19 = degrés + (minutes/60)
    ADD r19, r19, r17      # r19 = degrés + (minutes/60) + (secondes/3600) = angle 2 en décimal
    
    # 2. Calcul de la somme des angles intérieurs d'un polygone
    # Somme = (n-2) * 180 degrés, où n est le nombre de côtés
    SUBI r20, r13, 2       # r20 = n - 2
    MOVI r21, 180
    MUL r22, r20, r21      # r22 = (n-2) * 180 = somme des angles intérieurs
    
    # 3. Calcul de l'angle intérieur d'un polygone régulier
    # Angle intérieur = (n-2) * 180 / n
    DIV r23, r22, r13      # r23 = (n-2) * 180 / n = angle intérieur
    
    # 4. Calcul de l'angle extérieur d'un polygone régulier
    # Angle extérieur = 360 / n
    MOVI r24, 360
    DIV r25, r24, r13      # r25 = 360 / n = angle extérieur
    
    # 5. Calcul de l'angle manquant dans un triangle
    # Angle3 = 180 - (Angle1 + Angle2)
    ADD r26, r18, r19      # r26 = Angle1 + Angle2
    SUB r27, r21, r26      # r27 = 180 - (Angle1 + Angle2) = angle manquant
    
    # 6. Convertir l'angle manquant en DMS
    FLOOR r28, r27         # r28 = degrés (partie entière)
    SUB r29, r27, r28      # r29 = partie fractionnaire
    MUL r29, r29, r14      # r29 = minutes (partie fractionnaire * 60)
    FLOOR r29, r29         # r29 = minutes (partie entière)
    
    SUB r30, r29, r29      # r30 = partie fractionnaire des minutes
    MUL r30, r30, r14      # r30 = secondes (partie fractionnaire * 60)
    ROUND r30, r30         # r30 = secondes arrondies
    
    # 7. Conversion entre unités d'angle
    # Conversion de degrés en grades (1 degré = 10/9 grades)
    MOVI r31, 10
    MOVI r7, 9
    DIV r8, r31, r7        # r8 = 10/9
    MUL r9, r18, r8        # r9 = angle 1 en grades
    
    # Conversion de degrés en radians (1 degré = π/180 radians)
    LOADF r10, PI_CONST    # Charger la constante PI
    DIV r10, r10, r21      # r10 = PI/180
    MUL r11, r18, r10      # r11 = angle 1 en radians
    
    # 8. Stocker les résultats
    STOREW r22, r6, 0      # Somme des angles intérieurs
    STOREW r23, r6, 1      # Angle intérieur du polygone régulier
    STOREW r25, r6, 2      # Angle extérieur du polygone régulier
    STOREW r28, r6, 3      # Degrés de l'angle manquant
    STOREW r29, r6, 4      # Minutes de l'angle manquant
    STOREW r30, r6, 5      # Secondes de l'angle manquant
    STOREW r9, r6, 6       # Angle 1 en grades
    STOREW r11, r6, 7      # Angle 1 en radians
    
    # Passer à l'opération suivante
    ADDI r4, r4, 7         # 7 valeurs d'entrée (2 angles en DMS + nombre de côtés)
    BRANCH AL, geometry_loop

exit:
    # Fin du benchmark
    HALT

# Constantes pour les calculs trigonométriques
.section .data
PI_CONST: .float 3.14159265358979323846