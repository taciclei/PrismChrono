library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package prismchrono_tau_pkg is
    -- Types pour les opérations TAU
    type tau_operation_t is (
        TAU_ADD_B24,    -- Addition modulo 24
        TAU_SUB_B24,    -- Soustraction modulo 24
        TAU_MUL_B24,    -- Multiplication modulo 24
        TAU_CONV_B24_T, -- Conversion Base 24 vers ternaire
        TAU_CONV_T_B24  -- Conversion ternaire vers Base 24
    );
    
    -- Encodage des opérations TAU
    constant TAU_OP_ADD_B24    : std_logic_vector(2 downto 0) := "000";
    constant TAU_OP_SUB_B24    : std_logic_vector(2 downto 0) := "001";
    constant TAU_OP_MUL_B24    : std_logic_vector(2 downto 0) := "010";
    constant TAU_OP_CONV_B24_T : std_logic_vector(2 downto 0) := "011";
    constant TAU_OP_CONV_T_B24 : std_logic_vector(2 downto 0) := "100";
    
    -- Constantes pour la Base 24
    constant BASE_24 : natural := 24;
    constant MAX_TRYTE_VALUE : natural := 23;
    
    -- Types pour les instructions de branchement ternaire
    type branch3_condition_t is (
        BRANCH3_N,  -- Branchement si négatif
        BRANCH3_Z,  -- Branchement si zéro
        BRANCH3_P   -- Branchement si positif
    );
    
    -- Fonctions utilitaires
    function encode_tau_operation(op : tau_operation_t) return std_logic_vector;
    function decode_tau_operation(op_code : std_logic_vector(2 downto 0)) return tau_operation_t;
    
end package prismchrono_tau_pkg;

package body prismchrono_tau_pkg is
    -- Implémentation des fonctions
    function encode_tau_operation(op : tau_operation_t) return std_logic_vector is
    begin
        case op is
            when TAU_ADD_B24    => return TAU_OP_ADD_B24;
            when TAU_SUB_B24    => return TAU_OP_SUB_B24;
            when TAU_MUL_B24    => return TAU_OP_MUL_B24;
            when TAU_CONV_B24_T => return TAU_OP_CONV_B24_T;
            when TAU_CONV_T_B24 => return TAU_OP_CONV_T_B24;
        end case;
    end function;
    
    function decode_tau_operation(op_code : std_logic_vector(2 downto 0)) return tau_operation_t is
    begin
        case op_code is
            when TAU_OP_ADD_B24    => return TAU_ADD_B24;
            when TAU_OP_SUB_B24    => return TAU_SUB_B24;
            when TAU_OP_MUL_B24    => return TAU_MUL_B24;
            when TAU_OP_CONV_B24_T => return TAU_CONV_B24_T;
            when TAU_OP_CONV_T_B24 => return TAU_CONV_T_B24;
            when others            => return TAU_ADD_B24; -- Valeur par défaut
        end case;
    end function;
    
end package body prismchrono_tau_pkg;