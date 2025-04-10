library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity alu_24t is
    port (
        clk     : in  std_logic;       -- Horloge système (pour opérations multi-cycles)
        rst     : in  std_logic;       -- Reset asynchrone
        op_a    : in  EncodedWord;     -- Premier opérande (24 trits)
        op_b    : in  EncodedWord;     -- Second opérande (24 trits)
        alu_op  : in  AluOpType;       -- Opération à effectuer
        c_in    : in  EncodedTrit;     -- Retenue d'entrée
        start   : in  std_logic;       -- Signal de démarrage pour opérations multi-cycles
        result  : out EncodedWord;     -- Résultat (24 trits)
        flags   : out FlagBusType;     -- Flags (ZF, SF, OF, CF, XF)
        c_out   : out EncodedTrit;     -- Retenue de sortie
        done    : out std_logic        -- Signal indiquant la fin d'une opération multi-cycles
    );
end entity alu_24t;

architecture rtl of alu_24t is
    -- Composant additionneur 1-trit
    component ternary_full_adder_1t is
        port (
            a_in    : in  EncodedTrit;
            b_in    : in  EncodedTrit;
            c_in    : in  EncodedTrit;
            sum_out : out EncodedTrit;
            c_out   : out EncodedTrit
        );
    end component;
    
    -- Composant inverseur de trit
    component trit_inverter is
        port (
            trit_in  : in  EncodedTrit;
            trit_out : out EncodedTrit
        );
    end component;
    
    -- Composant unité de multiplication/division
    component mul_div_unit is
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
    end component;
    
    -- Signaux internes pour l'addition/soustraction
    signal adder_b_in : EncodedWord;  -- Entrée B modifiée pour la soustraction
    signal adder_c_in : EncodedTrit;  -- Retenue d'entrée modifiée pour la soustraction
    signal adder_result : EncodedWord; -- Résultat de l'addition/soustraction
    signal adder_c_out : EncodedTrit;  -- Retenue de sortie de l'addition/soustraction
    
    -- Type pour le tableau de trits encodés
    type EncodedTrit_array is array (natural range <>) of EncodedTrit;
    
    -- Signaux internes pour les retenues intermédiaires
    signal carry_chain : EncodedTrit_array(0 to 24);
    
    -- Signaux internes pour les opérations logiques
    signal tmin_result : EncodedWord;
    signal tmax_result : EncodedWord;
    signal tinv_result : EncodedWord;
    signal tcmp3_result : EncodedWord;
    signal abs_t_result : EncodedWord;
    signal signum_t_result : EncodedWord;
    
    -- Signaux internes pour les opérations de multiplication/division
    signal mul_div_op_type : std_logic_vector(1 downto 0);
    signal mul_div_result : EncodedWord;
    signal mul_div_flags : FlagBusType;
    signal mul_div_done : std_logic;
    
    -- Signaux internes pour le résultat final
    signal result_internal : EncodedWord;
    
    -- Signaux pour le calcul des flags
    signal zero_flag : std_logic;
    signal sign_flag : std_logic;
    signal overflow_flag : std_logic;
    signal carry_flag : std_logic;
    signal extended_flag : std_logic;
    
    -- Constantes pour les types d'opération de multiplication/division
    constant MUL_OP : std_logic_vector(1 downto 0) := "00";
    constant DIV_OP : std_logic_vector(1 downto 0) := "01";
    constant MOD_OP : std_logic_vector(1 downto 0) := "10";
    
    -- Fonction pour extraire un trit d'un mot
    function get_trit(word: EncodedWord; index: natural) return EncodedTrit is
    begin
        return word(index*2+1 downto index*2);
    end function;
    
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
    
begin
    -- Logique pour la sélection de l'entrée B et de la retenue d'entrée pour l'addition/soustraction
    process(op_b, c_in, alu_op)
    begin
        if alu_op = OP_SUB then
            -- Pour la soustraction, on inverse B et on force c_in à P
            for i in 0 to 23 loop
                case op_b(i*2+1 downto i*2) is
                    when TRIT_N => adder_b_in(i*2+1 downto i*2) <= TRIT_P;
                    when TRIT_Z => adder_b_in(i*2+1 downto i*2) <= TRIT_Z;
                    when TRIT_P => adder_b_in(i*2+1 downto i*2) <= TRIT_N;
                    when others => adder_b_in(i*2+1 downto i*2) <= TRIT_Z;
                end case;
            end loop;
            adder_c_in <= TRIT_P;
        else
            -- Pour l'addition, on utilise B et c_in tels quels
            adder_b_in <= op_b;
            adder_c_in <= c_in;
        end if;
    end process;
    
    -- Initialisation de la chaîne de retenue
    carry_chain(0) <= adder_c_in;
    
    -- Génération des 24 additionneurs 1-trit pour l'addition/soustraction
    GEN_ADDERS: for i in 0 to 23 generate
        ADDER_i: ternary_full_adder_1t
            port map (
                a_in    => op_a(i*2+1 downto i*2),
                b_in    => adder_b_in(i*2+1 downto i*2),
                c_in    => carry_chain(i),
                sum_out => adder_result(i*2+1 downto i*2),
                c_out   => carry_chain(i+1)
            );
    end generate;
    
    -- Retenue de sortie de l'addition/soustraction
    adder_c_out <= carry_chain(24);
    
    -- Processus pour les opérations logiques de base et spécialisées
    -- Processus pour la comparaison ternaire (TCMP3)
    process(op_a, op_b)
    variable trit_a, trit_b : EncodedTrit;
    variable result_trit : EncodedTrit;
    begin
    -- Initialisation du résultat à zéro
    tcmp3_result <= (others => TRIT_Z);
    
    -- Compare les trits de poids fort vers poids faible
    for i in 23 downto 0 loop
    trit_a := op_a((i*2)+1 downto i*2);
    trit_b := op_b((i*2)+1 downto i*2);
    
    if trit_a /= trit_b then
    if (trit_a = TRIT_P and (trit_b = TRIT_Z or trit_b = TRIT_N)) or
    (trit_a = TRIT_Z and trit_b = TRIT_N) then
    tcmp3_result(1 downto 0) <= TRIT_P;
    else
    tcmp3_result(1 downto 0) <= TRIT_N;
    end if;
    exit;
    end if;
    end loop;
    end process;
    
    -- Processus pour la valeur absolue ternaire (ABS_T)
    process(op_a)
    variable sign_trit : EncodedTrit;
    begin
    -- Détermine le signe en examinant le trit de poids fort
    sign_trit := op_a(47 downto 46);
    
    if sign_trit = TRIT_N then
    -- Si négatif, inverse tous les trits
    for i in 0 to 23 loop
    if op_a((i*2)+1 downto i*2) = TRIT_N then
    abs_t_result((i*2)+1 downto i*2) <= TRIT_P;
    elsif op_a((i*2)+1 downto i*2) = TRIT_P then
    abs_t_result((i*2)+1 downto i*2) <= TRIT_N;
    else
    abs_t_result((i*2)+1 downto i*2) <= TRIT_Z;
    end if;
    end loop;
    else
    -- Si positif ou zéro, copie directe
    abs_t_result <= op_a;
    end if;
    end process;
    
    -- Processus pour l'extraction de signe ternaire (SIGNUM_T)
    process(op_a)
    variable is_zero : boolean := true;
    variable found_nonzero : EncodedTrit := TRIT_Z;
    begin
    -- Initialise le résultat à zéro
    signum_t_result <= (others => TRIT_Z);
    
    -- Vérifie si tous les trits sont zéro
    for i in 23 downto 0 loop
    if op_a((i*2)+1 downto i*2) /= TRIT_Z then
    is_zero := false;
    found_nonzero := op_a((i*2)+1 downto i*2);
    exit;
    end if;
    end loop;
    
    if not is_zero then
    if found_nonzero = TRIT_N then
    signum_t_result(1 downto 0) <= TRIT_N;
    else
    signum_t_result(1 downto 0) <= TRIT_P;
    end if;
    end if;
    end process;
    
    -- Multiplexeur pour le résultat final
    process(alu_op, adder_result, tmin_result, tmax_result, tinv_result, tcmp3_result, abs_t_result, signum_t_result, mul_div_result)
    begin
    case alu_op is
    when OP_ADD => result_internal <= adder_result;
    when OP_SUB => result_internal <= adder_result;
    when OP_TMIN => result_internal <= tmin_result;
    when OP_TMAX => result_internal <= tmax_result;
    when OP_TINV => result_internal <= tinv_result;
    when OP_TCMP3 => result_internal <= tcmp3_result;
    when OP_ABS_T => result_internal <= abs_t_result;
    when OP_SIGNUM_T => result_internal <= signum_t_result;
    when OP_MUL | OP_DIV | OP_MOD => result_internal <= mul_div_result;
    when others => result_internal <= (others => '0');
    end case;
    end process;
    
    -- Calcul des flags
    -- ZF: 1 si le résultat est zéro
    zero_flag <= '1' when is_zero(result_internal) else '0';
    
    -- SF: 1 si le trit le plus significatif est négatif
    sign_flag <= '1' when result_internal(47 downto 46) = TRIT_N else '0';
    
    -- CF: 1 si la retenue de sortie est positive (pour ADD/SUB)
    carry_flag <= '1' when (alu_op = OP_ADD or alu_op = OP_SUB) and adder_c_out = TRIT_P else '0';
    
    -- OF: 1 si débordement signé (pour ADD/SUB)
    -- Débordement si les signes des opérandes sont identiques et différents du signe du résultat
    process(op_a, op_b, result_internal, alu_op)
        variable op_a_sign, op_b_sign, result_sign : EncodedTrit;
    begin
        op_a_sign := op_a(47 downto 46);
        op_b_sign := op_b(47 downto 46);
        result_sign := result_internal(47 downto 46);
        
        if alu_op = OP_ADD then
            -- Débordement si les signes des opérandes sont identiques et différents du signe du résultat
            if (op_a_sign = op_b_sign) and (op_a_sign /= result_sign) then
                overflow_flag <= '1';
            else
                overflow_flag <= '0';
            end if;
        elsif alu_op = OP_SUB then
            -- Pour la soustraction, on considère l'opérande B inversé
            if op_b_sign = TRIT_N then
                op_b_sign := TRIT_P;
            elsif op_b_sign = TRIT_P then
                op_b_sign := TRIT_N;
            end if;
            
            -- Débordement si les signes des opérandes sont identiques et différents du signe du résultat
            if (op_a_sign = op_b_sign) and (op_a_sign /= result_sign) then
                overflow_flag <= '1';
            else
                overflow_flag <= '0';
            end if;
        else
            overflow_flag <= '0';
        end if;
    end process;
    
    -- XF: 0 pour l'instant (à définir pour les états spéciaux)
    extended_flag <= '0';
    
    -- Assemblage des flags
    flags(FLAG_Z_IDX) <= zero_flag;
    flags(FLAG_S_IDX) <= sign_flag;
    flags(FLAG_O_IDX) <= overflow_flag;
    flags(FLAG_C_IDX) <= carry_flag;
    flags(FLAG_X_IDX) <= extended_flag;
    
    -- Affectation des sorties
    result <= result_internal;
    
    -- Multiplexeur pour les flags en fonction de l'opération
    process(alu_op, zero_flag, sign_flag, overflow_flag, carry_flag, extended_flag, mul_div_flags)
    begin
        if alu_op = OP_MUL or alu_op = OP_DIV or alu_op = OP_MOD then
            -- Utiliser les flags de l'unité MUL/DIV
            flags <= mul_div_flags;
        else
            -- Utiliser les flags calculés par l'ALU standard
            flags(FLAG_Z_IDX) <= zero_flag;
            flags(FLAG_S_IDX) <= sign_flag;
            flags(FLAG_O_IDX) <= overflow_flag;
            flags(FLAG_C_IDX) <= carry_flag;
            flags(FLAG_X_IDX) <= extended_flag;
        end if;
    end process;
    
    -- Signal de fin d'opération
    done <= mul_div_done when (alu_op = OP_MUL or alu_op = OP_DIV or alu_op = OP_MOD) else '1';
    
    c_out <= adder_c_out;
    
end architecture rtl;