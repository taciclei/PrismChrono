# Améliorations du Pipeline et Prédiction de Branchement

## 1. Optimisations du Pipeline

### 1.1 Réduction des Stalls
- Implémentation d'une détection plus fine des dépendances
- Optimisation du bypass pour réduire les bulles dans le pipeline
- Support des instructions multi-cycles avec gestion dynamique des stalls

### 1.2 Optimisation du Chemin Critique
- Réorganisation des étages pour équilibrer la charge
- Réduction de la latence des opérations critiques
- Amélioration du timing des signaux de contrôle

## 2. Prédiction de Branchement

### 2.1 Prédicteur à Deux Bits
- État initial : Faiblement Pris
- Quatre états possibles :
  * Fortement Non Pris (00)
  * Faiblement Non Pris (01)
  * Faiblement Pris (10)
  * Fortement Pris (11)
- Mise à jour basée sur le résultat réel du branchement

### 2.2 Table de Prédiction
- Indexation par les bits de poids faible de l'adresse
- Entrées contenant :
  * Compteur à deux bits
  * Adresse cible prédite
  * Tag pour validation

### 2.3 Gestion des Mauvaises Prédictions
- Détection en étage EX
- Mécanisme de flush optimisé
- Restauration du contexte correct

## 3. Implémentation

### 3.1 Modifications du Pipeline
```vhdl
-- Nouveaux signaux pour la prédiction
type branch_prediction_state is (STRONGLY_NOT_TAKEN, WEAKLY_NOT_TAKEN,
                               WEAKLY_TAKEN, STRONGLY_TAKEN);
signal branch_predictor : array(0 to 255) of branch_prediction_state;
signal predicted_target : array(0 to 255) of std_logic_vector(31 downto 0);

-- Logique de prédiction en IF
process(clk)
begin
    if rising_edge(clk) then
        if branch_valid = '1' then
            case branch_predictor(pc(9 downto 2)) is
                when STRONGLY_NOT_TAKEN | WEAKLY_NOT_TAKEN =>
                    prediction <= '0';
                when WEAKLY_TAKEN | STRONGLY_TAKEN =>
                    prediction <= '1';
            end case;
        end if;
    end if;
end process;
```

### 3.2 Mise à Jour du Prédicteur
```vhdl
-- Mise à jour en étage EX
process(clk)
begin
    if rising_edge(clk) then
        if branch_resolved = '1' then
            case branch_predictor(branch_pc(9 downto 2)) is
                when STRONGLY_NOT_TAKEN =>
                    if branch_taken = '1' then
                        branch_predictor(branch_pc(9 downto 2)) <= WEAKLY_NOT_TAKEN;
                    end if;
                when WEAKLY_NOT_TAKEN =>
                    if branch_taken = '1' then
                        branch_predictor(branch_pc(9 downto 2)) <= WEAKLY_TAKEN;
                    else
                        branch_predictor(branch_pc(9 downto 2)) <= STRONGLY_NOT_TAKEN;
                    end if;
                when WEAKLY_TAKEN =>
                    if branch_taken = '1' then
                        branch_predictor(branch_pc(9 downto 2)) <= STRONGLY_TAKEN;
                    else
                        branch_predictor(branch_pc(9 downto 2)) <= WEAKLY_NOT_TAKEN;
                    end if;
                when STRONGLY_TAKEN =>
                    if branch_taken = '0' then
                        branch_predictor(branch_pc(9 downto 2)) <= WEAKLY_TAKEN;
                    end if;
            end case;
        end if;
    end if;
end process;
```

## 4. Performances Attendues

### 4.1 Réduction des Cycles de Pénalité
- Diminution de 2 cycles à 1 cycle pour les branchements bien prédits
- Pénalité de 3 cycles pour les mauvaises prédictions

### 4.2 Taux de Succès
- Objectif de taux de prédiction correct > 85%
- Amélioration progressive avec l'apprentissage
- Impact positif sur les performances globales

## 5. Tests et Validation

### 5.1 Scénarios de Test
- Boucles avec nombre d'itérations variable
- Branchements conditionnels imbriqués
- Cas limites de prédiction

### 5.2 Métriques de Performance
- Taux de prédiction correct
- Cycles perdus sur mauvaise prédiction
- Impact sur les performances globales