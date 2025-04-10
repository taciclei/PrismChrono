library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity mul_div_unit is
    port (
        clk         : in  std_logic;                     -- Horloge système
        rst         : in  std_logic;                     -- Reset asynchrone
        start       : in  std_logic;                     -- Signal de démarrage de l'opération
        op_type     : in  std_logic_vector(1 downto 0);  -- Type d'opération (00: MUL, 01: DIV, 10: MOD)
        op_a        : in  EncodedWord;                   -- Premier opérande (24 trits)
        op_b        : in  EncodedWord;                   -- Second opérande (24 trits)
        result      : out EncodedWord;                   -- Résultat (24 trits)
        flags       : out FlagBusType;                   -- Flags (ZF, SF, OF, CF, XF)
        done        : out std_logic                      -- Signal indiquant la fin de l'opération
    );
end entity mul_div_unit;

architecture rtl of mul_div_unit is
    -- Constantes pour les types d'opération
    constant OP_MUL : std_logic_vector(1 downto 0) := "00";
    constant OP_DIV : std_logic_vector(1 downto 0) := "01";
    constant OP_MOD : std_logic_vector(1 downto 0) := "10";
    
    -- États de la FSM interne
    type mul_div_state_type is (
        IDLE,           -- État d'attente
        MUL_INIT,       -- Initialisation de la multiplication
        MUL_COMPUTE,    -- Calcul de la multiplication
        DIV_INIT,       -- Initialisation de la division
        DIV_COMPUTE,    -- Calcul de la division
        COMPLETE        -- Opération terminée
    );
    
    -- Signaux d'état
    signal state_reg, state_next : mul_div_state_type := IDLE;
    
    -- Signaux pour la multiplication
    signal multiplicand_reg, multiplicand_next : EncodedWord := (others => '0');
    signal multiplier_reg, multiplier_next : EncodedWord := (others => '0');
    signal product_reg, product_next : EncodedWord := (others => '0');
    signal mul_count_reg, mul_count_next : integer range 0 to 24 := 0;
    
    -- Signaux pour la division
    signal dividend_reg, dividend_next : EncodedWord := (others => '0');
    signal divisor_reg, divisor_next : EncodedWord := (others => '0');
    signal quotient_reg, quotient_next : EncodedWord := (others => '0');
    signal remainder_reg, remainder_next : EncodedWord := (others => '0');
    signal div_count_reg, div_count_next : integer range 0 to 24 := 0;
    
    -- Signaux pour les flags
    signal zero_flag : std_logic := '0';
    signal sign_flag : std_logic := '0';
    signal overflow_flag : std_logic := '0';
    signal carry_flag : std_logic := '0';
    signal extended_flag : std_logic := '0';
    
    -- Fonction pour vérifier si un mot est entièrement composé de zéros
    function is_zero(word: EncodedWord) return boolean is
    begin
        for i in 0 to 23 loop
            if word(i*2+1 downto i*2) /= TRIT_Z then
                return false;
            end if;
        end loop;
        return true;
    end function;
    
    -- Fonction pour obtenir le signe d'un mot (trit le plus significatif)
    function get_sign(word: EncodedWord) return EncodedTrit is
    begin
        return word(47 downto 46);
    end function;
    
    -- Fonction pour décaler un mot d'un trit vers la gauche
    function shift_left_1t(word: EncodedWord) return EncodedWord is
        variable result : EncodedWord;
    begin
        -- Décalage de tous les trits sauf le MSB
        for i in 1 to 23 loop
            result(i*2+1 downto i*2) := word((i-1)*2+1 downto (i-1)*2);
        end loop;
        -- Le trit le moins significatif devient zéro
        result(1 downto 0) := TRIT_Z;
        return result;
    end function;
    
    -- Fonction pour décaler un mot d'un trit vers la droite
    function shift_right_1t(word: EncodedWord) return EncodedWord is
        variable result : EncodedWord;
    begin
        -- Décalage de tous les trits sauf le LSB
        for i in 0 to 22 loop
            result(i*2+1 downto i*2) := word((i+1)*2+1 downto (i+1)*2);
        end loop;
        -- Le trit le plus significatif devient zéro
        result(47 downto 46) := TRIT_Z;
        return result;
    end function;
    
    -- Fonction pour additionner deux mots ternaires
    function ternary_add(a, b: EncodedWord) return EncodedWord is
        variable result : EncodedWord;
        variable carry : EncodedTrit := TRIT_Z;
        variable sum : integer;
    begin
        for i in 0 to 23 loop
            -- Conversion des trits en entiers pour l'addition
            sum := to_integer(a(i*2+1 downto i*2)) + to_integer(b(i*2+1 downto i*2)) + to_integer(carry);
            
            -- Gestion de la retenue en base 3
            if sum > 1 then
                sum := sum - 3;
                carry := TRIT_P;
            elsif sum < -1 then
                sum := sum + 3;
                carry := TRIT_N;
            else
                carry := TRIT_Z;
            end if;
            
            -- Conversion du résultat en trit
            result(i*2+1 downto i*2) := to_encoded_trit(sum);
        end loop;
        return result;
    end function;
    
    -- Fonction pour soustraire deux mots ternaires
    function ternary_sub(a, b: EncodedWord) return EncodedWord is
        variable neg_b : EncodedWord;
    begin
        -- Négation de b
        for i in 0 to 23 loop
            case b(i*2+1 downto i*2) is
                when TRIT_N => neg_b(i*2+1 downto i*2) := TRIT_P;
                when TRIT_Z => neg_b(i*2+1 downto i*2) := TRIT_Z;
                when TRIT_P => neg_b(i*2+1 downto i*2) := TRIT_N;
                when others => neg_b(i*2+1 downto i*2) := TRIT_Z;
            end case;
        end loop;
        
        -- Addition de a et -b
        return ternary_add(a, neg_b);
    end function;
    
begin
    -- Processus synchrone pour mettre à jour les registres
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation des registres
            state_reg <= IDLE;
            multiplicand_reg <= (others => '0');
            multiplier_reg <= (others => '0');
            product_reg <= (others => '0');
            mul_count_reg <= 0;
            dividend_reg <= (others => '0');
            divisor_reg <= (others => '0');
            quotient_reg <= (others => '0');
            remainder_reg <= (others => '0');
            div_count_reg <= 0;
        elsif rising_edge(clk) then
            -- Mise à jour des registres
            state_reg <= state_next;
            multiplicand_reg <= multiplicand_next;
            multiplier_reg <= multiplier_next;
            product_reg <= product_next;
            mul_count_reg <= mul_count_next;
            dividend_reg <= dividend_next;
            divisor_reg <= divisor_next;
            quotient_reg <= quotient_next;
            remainder_reg <= remainder_next;
            div_count_reg <= div_count_next;
        end if;
    end process;
    
    -- Processus combinatoire pour calculer le prochain état et les signaux de sortie
    process(state_reg, start, op_type, op_a, op_b, 
            multiplicand_reg, multiplier_reg, product_reg, mul_count_reg,
            dividend_reg, divisor_reg, quotient_reg, remainder_reg, div_count_reg)
    begin
        -- Valeurs par défaut
        state_next <= state_reg;
        multiplicand_next <= multiplicand_reg;
        multiplier_next <= multiplier_reg;
        product_next <= product_reg;
        mul_count_next <= mul_count_reg;
        dividend_next <= dividend_reg;
        divisor_next <= divisor_reg;
        quotient_next <= quotient_reg;
        remainder_next <= remainder_reg;
        div_count_next <= div_count_reg;
        done <= '0';
        
        -- FSM pour les opérations multi-cycles
        case state_reg is
            when IDLE =>
                -- Attente du signal de démarrage
                if start = '1' then
                    case op_type is
                        when OP_MUL =>
                            state_next <= MUL_INIT;
                        when OP_DIV | OP_MOD =>
                            state_next <= DIV_INIT;
                        when others =>
                            state_next <= IDLE;
                    end case;
                end if;
                
            when MUL_INIT =>
                -- Initialisation de la multiplication
                multiplicand_next <= op_a;
                multiplier_next <= op_b;
                product_next <= (others => '0'); -- Initialisation du produit à zéro
                mul_count_next <= 24; -- Nombre de trits à traiter
                state_next <= MUL_COMPUTE;
                
            when MUL_COMPUTE =>
                -- Algorithme de multiplication ternaire par additions successives
                if mul_count_reg = 0 then
                    -- Multiplication terminée
                    state_next <= COMPLETE;
                else
                    -- Vérifier le trit actuel du multiplicateur
                    case multiplier_reg(1 downto 0) is
                        when TRIT_P =>
                            -- Si le trit est positif, ajouter le multiplicande au produit
                            product_next <= ternary_add(product_reg, multiplicand_reg);
                        when TRIT_N =>
                            -- Si le trit est négatif, soustraire le multiplicande du produit
                            product_next <= ternary_sub(product_reg, multiplicand_reg);
                        when others =>
                            -- Si le trit est zéro, ne rien faire
                            null;
                    end case;
                    
                    -- Décaler le multiplicateur vers la droite
                    multiplier_next <= shift_right_1t(multiplier_reg);
                    -- Décaler le multiplicande vers la gauche
                    multiplicand_next <= shift_left_1t(multiplicand_reg);
                    -- Décrémenter le compteur
                    mul_count_next <= mul_count_reg - 1;
                end if;
                
            when DIV_INIT =>
                -- Initialisation de la division
                dividend_next <= op_a;
                divisor_next <= op_b;
                quotient_next <= (others => '0'); -- Initialisation du quotient à zéro
                remainder_next <= (others => '0'); -- Initialisation du reste à zéro
                div_count_next <= 24; -- Nombre de trits à traiter
                
                -- Vérifier si le diviseur est zéro
                if is_zero(op_b) then
                    -- Division par zéro, on met des flags d'erreur et on termine
                    state_next <= COMPLETE;
                else
                    state_next <= DIV_COMPUTE;
                end if;
                
            when DIV_COMPUTE =>
                -- Algorithme de division ternaire (non implémenté pour l'instant)
                -- Pour le sprint 9, on se concentre sur MUL et on utilise l'option C (trap) pour DIV/MOD
                state_next <= COMPLETE;
                
            when COMPLETE =>
                -- Opération terminée
                done <= '1';
                state_next <= IDLE;
                
        end case;
    end process;
    
    -- Assignation du résultat en fonction de l'opération
    process(state_reg, op_type, product_reg, quotient_reg, remainder_reg)
    begin
        case state_reg is
            when COMPLETE =>
                case op_type is
                    when OP_MUL =>
                        result <= product_reg;
                    when OP_DIV =>
                        result <= quotient_reg;
                    when OP_MOD =>
                        result <= remainder_reg;
                    when others =>
                        result <= (others => '0');
                end case;
            when others =>
                result <= (others => '0');
        end case;
    end process;
    
    -- Calcul des flags
    process(state_reg, op_type, product_reg, quotient_reg, remainder_reg)
    begin
        -- Par défaut, tous les flags sont à zéro
        zero_flag <= '0';
        sign_flag <= '0';
        overflow_flag <= '0';
        carry_flag <= '0';
        extended_flag <= '0';
        
        if state_reg = COMPLETE then
            case op_type is
                when OP_MUL =>
                    -- ZF: 1 si le résultat est zéro
                    if is_zero(product_reg) then
                        zero_flag <= '1';
                    end if;
                    
                    -- SF: 1 si le trit le plus significatif est négatif
                    if get_sign(product_reg) = TRIT_N then
                        sign_flag <= '1';
                    end if;
                    
                    -- OF: 1 si débordement (non implémenté pour l'instant)
                    -- Pour une implémentation complète, il faudrait vérifier si le produit
                    -- dépasse la capacité de 24 trits
                    
                when OP_DIV | OP_MOD =>
                    -- ZF: 1 si le résultat est zéro
                    if op_type = OP_DIV and is_zero(quotient_reg) then
                        zero_flag <= '1';
                    elsif op_type = OP_MOD and is_zero(remainder_reg) then
                        zero_flag <= '1';
                    end if;
                    
                    -- SF: 1 si le trit le plus significatif est négatif
                    if op_type = OP_DIV and get_sign(quotient_reg) = TRIT_N then
                        sign_flag <= '1';
                    elsif op_type = OP_MOD and get_sign(remainder_reg) = TRIT_N then
                        sign_flag <= '1';
                    end if;
                    
                    -- XF: 1 si division par zéro
                    if is_zero(divisor_reg) then
                        extended_flag <= '1';
                    end if;
                    
                when others =>
                    null;
            end case;
        end if;
    end process;
    
    -- Assignation des flags
    flags(FLAG_Z_IDX) <= zero_flag;
    flags(FLAG_S_IDX) <= sign_flag;
    flags(FLAG_O_IDX) <= overflow_flag;
    flags(FLAG_C_IDX) <= carry_flag;
    flags(FLAG_X_IDX) <= extended_flag;
    
end architecture rtl;