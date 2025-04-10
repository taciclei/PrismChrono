library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.prismchrono_types_pkg.all;

-- Tryte Arithmetic Unit (TAU)
-- Unité spécialisée pour les opérations en Base 24/60
entity tryte_arithmetic_unit is
    port (
        -- Signaux de contrôle
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        operation   : in  std_logic_vector(2 downto 0);  -- Type d'opération
        valid_in    : in  std_logic;                     -- Données d'entrée valides
        
        -- Données d'entrée
        operand_a   : in  std_logic_vector(23 downto 0); -- 4 trytes (6 bits chacun)
        operand_b   : in  std_logic_vector(23 downto 0); -- 4 trytes (6 bits chacun)
        
        -- Sorties
        result      : out std_logic_vector(23 downto 0); -- Résultat (4 trytes)
        valid_out   : out std_logic;                     -- Résultat valide
        overflow    : out std_logic                      -- Indicateur de dépassement
    );
end entity tryte_arithmetic_unit;

architecture rtl of tryte_arithmetic_unit is
    -- Constantes pour les opérations
    constant OP_ADD_B24    : std_logic_vector(2 downto 0) := "000";
    constant OP_SUB_B24    : std_logic_vector(2 downto 0) := "001";
    constant OP_MUL_B24    : std_logic_vector(2 downto 0) := "010";
    constant OP_CONV_B24_T : std_logic_vector(2 downto 0) := "011";
    constant OP_CONV_T_B24 : std_logic_vector(2 downto 0) := "100";
    constant OP_ADD_B24_VEC: std_logic_vector(2 downto 0) := "101";
    
    -- Constantes pour la Base 24
    constant BASE_24 : unsigned(7 downto 0) := to_unsigned(24, 8);
    
    -- Signaux internes
    type tryte_array is array (0 to 3) of unsigned(5 downto 0);
    signal trytes_a, trytes_b : tryte_array;
    signal result_trytes : tryte_array;
    signal temp_overflow : std_logic;
    signal parallel_overflow : std_logic_vector(3 downto 0);
    
    -- Fonction pour convertir un tryte en valeur ternaire équilibrée (-13 à +13)
    function tryte_to_balanced(tryte : unsigned(5 downto 0)) return signed is
        variable result : signed(5 downto 0);
    begin
        if tryte < 13 then
            result := signed(resize(tryte, 6));
        else
            result := signed(resize(tryte - 13, 6));
        end if;
        return result;
    end function;
    
    -- Fonction pour convertir une valeur ternaire équilibrée en tryte
    function balanced_to_tryte(value : signed(5 downto 0)) return unsigned is
        variable result : unsigned(5 downto 0);
    begin
        if value < 0 then
            result := unsigned(resize(value + 13, 6));
        else
            result := unsigned(resize(value, 6));
        end if;
        return result;
    end function;
    
    -- Fonction pour l'addition parallèle de trytes en Base 24
    function add_trytes_parallel(
        a, b : tryte_array;
        overflow : out std_logic_vector(3 downto 0)
    ) return tryte_array is
        variable result : tryte_array;
        variable sum : unsigned(6 downto 0);
    begin
        for i in 0 to 3 loop
            sum := resize(a(i), 7) + resize(b(i), 7);
            if sum >= BASE_24 then
                result(i) := resize(sum - BASE_24, 6);
                overflow(i) := '1';
            else
                result(i) := resize(sum, 6);
                overflow(i) := '0';
            end if;
        end loop;
        return result;
    end function;
    begin
        if tryte < 13 then
            result := signed(resize(tryte, 6));
        else
            result := signed(resize(tryte - 24, 6));
        end if;
        return result;
    end function;
    
    -- Fonction pour convertir une valeur ternaire équilibrée en tryte
    function balanced_to_tryte(value : signed(5 downto 0)) return unsigned is
        variable result : unsigned(5 downto 0);
    begin
        if value >= 0 then
            result := unsigned(value);
        else
            result := unsigned(value + 24);
        end if;
        return result;
    end function;
    
begin
    -- Découpage des opérandes en trytes individuels
    process(operand_a, operand_b)
    begin
        for i in 0 to 3 loop
            trytes_a(i) <= unsigned(operand_a((i+1)*6-1 downto i*6));
            trytes_b(i) <= unsigned(operand_b((i+1)*6-1 downto i*6));
        end loop;
    end process;
    
    -- Logique principale
    process(clk)
        variable temp_result : unsigned(11 downto 0);
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                result_trytes <= (others => (others => '0'));
                valid_out <= '0';
                overflow <= '0';
            elsif valid_in = '1' then
                temp_overflow <= '0';
                
                case operation is
                    when OP_ADD_B24 =>
                        -- Addition modulo 24 pour chaque tryte
                        for i in 0 to 3 loop
                            temp_result := resize(trytes_a(i), 12) + resize(trytes_b(i), 12);
                            if temp_result >= BASE_24 then
                                result_trytes(i) <= resize(temp_result - BASE_24, 6);
                                temp_overflow <= '1';
                            else
                                result_trytes(i) <= resize(temp_result, 6);
                            end if;
                        end loop;
                        
                    when OP_SUB_B24 =>
                        -- Soustraction modulo 24
                        for i in 0 to 3 loop
                            if trytes_a(i) >= trytes_b(i) then
                                result_trytes(i) <= trytes_a(i) - trytes_b(i);
                            else
                                result_trytes(i) <= resize(BASE_24 + trytes_a(i) - trytes_b(i), 6);
                                temp_overflow <= '1';
                            end if;
                        end loop;
                        
                    when OP_MUL_B24 =>
                        -- Multiplication modulo 24
                        for i in 0 to 3 loop
                            temp_result := resize(trytes_a(i) * trytes_b(i), 12);
                            result_trytes(i) <= resize(temp_result mod BASE_24, 6);
                            if temp_result >= BASE_24 then
                                temp_overflow <= '1';
                            end if;
                        end loop;
                        
                    when OP_CONV_B24_T =>
                        -- Conversion Base 24 vers ternaire équilibré
                        for i in 0 to 3 loop
                            result_trytes(i) <= unsigned(tryte_to_balanced(trytes_a(i)));
                        end loop;
                        
                    when OP_CONV_T_B24 =>
                        -- Conversion ternaire équilibré vers Base 24
                        for i in 0 to 3 loop
                            result_trytes(i) <= balanced_to_tryte(signed(trytes_a(i)));
                        end loop;
                        
                    when others =>
                        result_trytes <= (others => (others => '0'));
                end case;
                
                valid_out <= '1';
                overflow <= temp_overflow;
            else
                valid_out <= '0';
            end if;
        end if;
    end process;
    
    -- Assemblage du résultat final
    process(result_trytes)
    begin
        for i in 0 to 3 loop
            result((i+1)*6-1 downto i*6) <= std_logic_vector(result_trytes(i));
        end loop;
    end process;
    
end architecture rtl;