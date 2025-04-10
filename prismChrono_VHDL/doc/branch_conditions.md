# Documentation des Conditions de Branchement pour PrismChrono

## Introduction

Ce document décrit les différentes conditions de branchement supportées par le processeur PrismChrono et leur mapping sur les flags générés par l'ALU. Les instructions de branchement conditionnel (BRANCH) utilisent ces conditions pour déterminer si le branchement doit être pris ou non.

## Tableau des Conditions de Branchement

Le tableau suivant présente les différentes conditions de branchement, leur encodage ternaire, leur mnémonique assembleur, et leur évaluation basée sur les flags de l'ALU :

| Condition | Encodage Ternaire | Mnémonique | Description | Évaluation des Flags |
|-----------|-------------------|------------|-------------|---------------------|
| Equal | ZZZ (000) | BEQ | Branchement si égal | ZF = 1 |
| Not Equal | NZZ (-4) | BNE | Branchement si différent | ZF = 0 |
| Less Than | NZN (-5) | BLT | Branchement si inférieur | SF = 1 & ZF = 0 |
| Greater or Equal | PZN (4) | BGE | Branchement si supérieur ou égal | SF = 0 \| ZF = 1 |
| Branch Always | PZP (13) | B | Branchement inconditionnel | Toujours pris (1) |

## Flags de l'ALU

Les flags générés par l'ALU sont utilisés pour évaluer les conditions de branchement :

- **ZF (Zero Flag)** : Indique si le résultat de l'opération est zéro.
  - ZF = 1 si le résultat est zéro.
  - ZF = 0 si le résultat est non-zéro.

- **SF (Sign Flag)** : Indique si le résultat de l'opération est négatif.
  - SF = 1 si le résultat est négatif.
  - SF = 0 si le résultat est positif ou zéro.

- **OF (Overflow Flag)** : Indique si l'opération a généré un dépassement de capacité.
  - OF = 1 si un dépassement s'est produit.
  - OF = 0 si aucun dépassement ne s'est produit.

- **CF (Carry Flag)** : Indique si l'opération a généré une retenue.
  - CF = 1 si une retenue a été générée.
  - CF = 0 si aucune retenue n'a été générée.

- **XF (Extended Flag)** : Flag spécial pour les états ternaires étendus.
  - XF = 1 si l'opération implique un état ternaire étendu.
  - XF = 0 sinon.

## Implémentation dans le Contrôleur

L'évaluation des conditions de branchement est réalisée dans l'unité de contrôle par un processus combinatoire qui prend en entrée les flags de l'ALU et la condition de branchement extraite de l'instruction. Le résultat de cette évaluation est le signal `branch_taken` qui indique si le branchement doit être pris ou non.

```vhdl
process(branch_cond, flags)
begin
    -- Par défaut, le branchement n'est pas pris
    branch_taken_internal <= '0';
    
    -- Évaluation de la condition en fonction des flags
    case branch_cond is
        when COND_EQ =>
            -- Equal (Zero Flag = 1)
            if flags(FLAG_Z_IDX) = '1' then
                branch_taken_internal <= '1';
            end if;
            
        when COND_NE =>
            -- Not Equal (Zero Flag = 0)
            if flags(FLAG_Z_IDX) = '0' then
                branch_taken_internal <= '1';
            end if;
            
        when COND_LT =>
            -- Less Than (Sign Flag = 1 & Zero Flag = 0)
            if flags(FLAG_S_IDX) = '1' and flags(FLAG_Z_IDX) = '0' then
                branch_taken_internal <= '1';
            end if;
            
        when COND_GE =>
            -- Greater or Equal (Sign Flag = 0 | Zero Flag = 1)
            if flags(FLAG_S_IDX) = '0' or flags(FLAG_Z_IDX) = '1' then
                branch_taken_internal <= '1';
            end if;
            
        when COND_B =>
            -- Branch Always (Unconditional)
            branch_taken_internal <= '1';
            
        when others =>
            -- Condition non reconnue, branchement non pris
            branch_taken_internal <= '0';
    end case;
end process;
```

## Séquence d'Exécution

La séquence typique pour l'exécution d'un branchement conditionnel est la suivante :

1. Exécution d'une instruction `CMP` qui compare deux registres et met à jour les flags de l'ALU.
2. Exécution d'une instruction `BRANCH` qui évalue la condition de branchement en fonction des flags.
3. Si la condition est vraie (`branch_taken = '1'`), le PC est chargé avec l'adresse cible calculée.
4. Si la condition est fausse (`branch_taken = '0'`), le PC est simplement incrémenté pour passer à l'instruction suivante.

## Extensions Futures

Des conditions de branchement supplémentaires pourront être ajoutées dans les versions futures du processeur PrismChrono, notamment :

- **XS (Extended State)** : Branchement si l'état ternaire étendu est actif (XF = 1).
- **XN (Not Extended State)** : Branchement si l'état ternaire étendu n'est pas actif (XF = 0).
- **OV (Overflow)** : Branchement si un dépassement s'est produit (OF = 1).
- **NV (No Overflow)** : Branchement si aucun dépassement ne s'est produit (OF = 0).

Ces extensions permettront d'exploiter pleinement les capacités du système ternaire de PrismChrono.