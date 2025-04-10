library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_alu_24t is
    -- Testbench n'a pas de ports
end entity tb_alu_24t;

architecture sim of tb_alu_24t is
    -- Composant à tester
    component alu_24t is
        port (
            op_a    : in  EncodedWord;     -- Premier opérande (24 trits)
            op_b    : in  EncodedWord;     -- Second opérande (24 trits)
            alu_op  : in  AluOpType;       -- Opération à effectuer
            c_in    : in  EncodedTrit;     -- Retenue d'entrée
            result  : out EncodedWord;     -- Résultat (24 trits)
            flags   : out FlagBusType;     -- Flags (ZF, SF, OF, CF, XF)
            c_out   : out EncodedTrit      -- Retenue de sortie
        );
    end component;
    
    -- Signaux pour les tests
    signal op_a_s    : EncodedWord := (others => '0');
    signal op_b_s    : EncodedWord := (others => '0');
    signal alu_op_s  : AluOpType := OP_ADD;
    signal c_in_s    : EncodedTrit := TRIT_Z;
    signal result_s  : EncodedWord;
    signal flags_s   : FlagBusType;
    signal c_out_s   : EncodedTrit;
    
    -- Constante pour le délai entre les tests
    constant T : time := 10 ns;
    
    -- Fonction pour initialiser un mot avec une valeur ternaire spécifique
    function init_word(value: EncodedTrit) return EncodedWord is
        variable word : EncodedWord;
    begin
        for i in 0 to 23 loop
            word(i*2+1 downto i*2) := value;
        end loop;
        return word;
    end function;
    
    -- Fonction pour définir un trit spécifique dans un mot
    procedure set_trit(signal word: out EncodedWord; index: natural; trit: EncodedTrit) is
    begin
        word(index*2+1 downto index*2) <= trit;
    end procedure;
    
    -- Fonction pour obtenir un trit spécifique d'un mot
    function get_trit(word: EncodedWord; index: natural) return EncodedTrit is
    begin
        return word(index*2+1 downto index*2);
    end function;
    
    -- Fonction pour convertir un flag en chaîne de caractères
    function flag_to_string(flag: std_logic) return string is
    begin
        if flag = '1' then
            return "1";
        else
            return "0";
        end if;
    end function;
    
    -- Fonction pour convertir un trit en chaîne de caractères
    function trit_to_string(t: EncodedTrit) return string is
    begin
        if t = TRIT_N then
            return "N";
        elsif t = TRIT_Z then
            return "Z";
        elsif t = TRIT_P then
            return "P";
        else
            return "?";
        end if;
    end function;
    
begin
    -- Instanciation du composant à tester
    UUT: alu_24t
        port map (
            op_a    => op_a_s,
            op_b    => op_b_s,
            alu_op  => alu_op_s,
            c_in    => c_in_s,
            result  => result_s,
            flags   => flags_s,
            c_out   => c_out_s
        );
    
    -- Process de test
    STIM_PROC: process
        -- Variables pour les tests
        variable expected_result : EncodedWord;
        variable expected_flags : FlagBusType;
        variable expected_cout : EncodedTrit;
    begin
        report "Début des tests pour l'ALU 24 trits";
        
        -- Test 1: Addition de zéros
        report "Test 1: Addition de zéros";
        op_a_s <= init_word(TRIT_Z);
        op_b_s <= init_word(TRIT_Z);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_Z;
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_Z);
        expected_flags := (FLAG_Z_IDX => '1', others => '0');
        expected_cout := TRIT_Z;
        
        assert result_s = expected_result
            report "Test 1 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 1 échoué: Flags incorrects. Attendu: Z=1, S=0, O=0, C=0, X=0. Obtenu: Z=" & 
                   flag_to_string(flags_s(FLAG_Z_IDX)) & ", S=" & 
                   flag_to_string(flags_s(FLAG_S_IDX)) & ", O=" & 
                   flag_to_string(flags_s(FLAG_O_IDX)) & ", C=" & 
                   flag_to_string(flags_s(FLAG_C_IDX)) & ", X=" & 
                   flag_to_string(flags_s(FLAG_X_IDX))
            severity error;
        assert c_out_s = expected_cout
            report "Test 1 échoué: Retenue incorrecte" severity error;
        
        -- Test 2: Addition de positifs
        report "Test 2: Addition de positifs";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_P);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_Z;
        wait for T;
        
        -- Vérification du résultat (P+P=N avec retenue P)
        expected_result := init_word(TRIT_N);
        expected_flags := (FLAG_Z_IDX => '0', FLAG_S_IDX => '1', FLAG_C_IDX => '1', others => '0');
        expected_cout := TRIT_P;
        
        assert result_s = expected_result
            report "Test 2 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 2 échoué: Flags incorrects" severity error;
        assert c_out_s = expected_cout
            report "Test 2 échoué: Retenue incorrecte" severity error;
        
        -- Test 3: Addition avec retenue d'entrée
        report "Test 3: Addition avec retenue d'entrée";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_Z);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_P;
        wait for T;
        
        -- Vérification du résultat (P+Z+P=N avec retenue P)
        expected_result := init_word(TRIT_N);
        expected_flags := (FLAG_Z_IDX => '0', FLAG_S_IDX => '1', FLAG_C_IDX => '1', others => '0');
        expected_cout := TRIT_P;
        
        assert result_s = expected_result
            report "Test 3 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 3 échoué: Flags incorrects" severity error;
        assert c_out_s = expected_cout
            report "Test 3 échoué: Retenue incorrecte" severity error;
        
        -- Test 4: Soustraction (P - P = Z)
        report "Test 4: Soustraction (P - P = Z)";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_P);
        alu_op_s <= OP_SUB;
        c_in_s <= TRIT_Z;  -- Ignoré pour SUB car on force c_in à P
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_Z);
        expected_flags := (FLAG_Z_IDX => '1', others => '0');
        expected_cout := TRIT_P;
        
        assert result_s = expected_result
            report "Test 4 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 4 échoué: Flags incorrects" severity error;
        assert c_out_s = expected_cout
            report "Test 4 échoué: Retenue incorrecte" severity error;
        
        -- Test 5: Soustraction (P - N = P)
        report "Test 5: Soustraction (P - N = P)";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_N);
        alu_op_s <= OP_SUB;
        c_in_s <= TRIT_Z;  -- Ignoré pour SUB
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_P);
        expected_flags := (FLAG_Z_IDX => '0', others => '0');
        expected_cout := TRIT_P;
        
        assert result_s = expected_result
            report "Test 5 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 5 échoué: Flags incorrects" severity error;
        assert c_out_s = expected_cout
            report "Test 5 échoué: Retenue incorrecte" severity error;
        
        -- Test 6: TMIN (N, P) = N
        report "Test 6: TMIN (N, P) = N";
        op_a_s <= init_word(TRIT_N);
        op_b_s <= init_word(TRIT_P);
        alu_op_s <= OP_TMIN;
        c_in_s <= TRIT_Z;  -- Ignoré pour TMIN
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_N);
        expected_flags := (FLAG_Z_IDX => '0', FLAG_S_IDX => '1', others => '0');
        
        assert result_s = expected_result
            report "Test 6 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 6 échoué: Flags incorrects" severity error;
        
        -- Test 7: TMAX (N, P) = P
        report "Test 7: TMAX (N, P) = P";
        op_a_s <= init_word(TRIT_N);
        op_b_s <= init_word(TRIT_P);
        alu_op_s <= OP_TMAX;
        c_in_s <= TRIT_Z;  -- Ignoré pour TMAX
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_P);
        expected_flags := (FLAG_Z_IDX => '0', others => '0');
        
        assert result_s = expected_result
            report "Test 7 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 7 échoué: Flags incorrects" severity error;
        
        -- Test 8: TINV (P) = N
        report "Test 8: TINV (P) = N";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_Z);  -- Ignoré pour TINV
        alu_op_s <= OP_TINV;
        c_in_s <= TRIT_Z;  -- Ignoré pour TINV
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_N);
        expected_flags := (FLAG_Z_IDX => '0', FLAG_S_IDX => '1', others => '0');
        
        assert result_s = expected_result
            report "Test 8 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 8 échoué: Flags incorrects" severity error;
        
        -- Test 9: TINV (N) = P
        report "Test 9: TINV (N) = P";
        op_a_s <= init_word(TRIT_N);
        op_b_s <= init_word(TRIT_Z);  -- Ignoré pour TINV
        alu_op_s <= OP_TINV;
        c_in_s <= TRIT_Z;  -- Ignoré pour TINV
        wait for T;
        
        -- Vérification du résultat
        expected_result := init_word(TRIT_P);
        expected_flags := (FLAG_Z_IDX => '0', others => '0');
        
        assert result_s = expected_result
            report "Test 9 échoué: Résultat incorrect" severity error;
        assert flags_s = expected_flags
            report "Test 9 échoué: Flags incorrects" severity error;
        
        -- Test 10: Vérification du flag de zéro (ZF)
        report "Test 10: Vérification du flag de zéro (ZF)";
        op_a_s <= init_word(TRIT_Z);
        op_b_s <= init_word(TRIT_Z);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_Z;
        wait for T;
        
        assert flags_s(FLAG_Z_IDX) = '1'
            report "Test 10 échoué: Flag ZF incorrect" severity error;
        
        -- Test 11: Vérification du flag de signe (SF)
        report "Test 11: Vérification du flag de signe (SF)";
        op_a_s <= init_word(TRIT_N);
        op_b_s <= init_word(TRIT_Z);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_Z;
        wait for T;
        
        assert flags_s(FLAG_S_IDX) = '1'
            report "Test 11 échoué: Flag SF incorrect" severity error;
        
        -- Test 12: Vérification du flag de retenue (CF)
        report "Test 12: Vérification du flag de retenue (CF)";
        op_a_s <= init_word(TRIT_P);
        op_b_s <= init_word(TRIT_P);
        alu_op_s <= OP_ADD;
        c_in_s <= TRIT_Z;
        wait for T;
        
        assert flags_s(FLAG_C_IDX) = '1'
            report "Test 12 échoué: Flag CF incorrect" severity error;
        
        -- Fin des tests
        report "Tous les tests ont été exécutés avec succès";
        wait;
    end process;
    
end architecture sim;