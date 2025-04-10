library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;

-- Module d'accélération pour réseaux neuronaux ternaires (TNN)
entity tnn_unit is
    generic (
        -- Nombre d'éléments pour le produit scalaire
        VECTOR_SIZE : positive := 8;
        -- Largeur des accumulateurs internes
        ACC_WIDTH : positive := 16
    );
    port (
        -- Interface globale
        clk     : in std_logic;
        rst_n   : in std_logic;
        
        -- Interface de contrôle
        start   : in std_logic;  -- Signal de démarrage d'une opération
        busy    : out std_logic; -- Indique que l'unité est occupée
        done    : out std_logic; -- Indique que l'opération est terminée
        op_type : in std_logic_vector(1 downto 0); -- Type d'opération (00: MAC, 01: Activation, etc)
        
        -- Interface données
        operand1 : in std_logic_vector(2*VECTOR_SIZE-1 downto 0);  -- Premier vecteur ternaire
        operand2 : in std_logic_vector(2*VECTOR_SIZE-1 downto 0);  -- Second vecteur ternaire
        result  : out std_logic_vector(8 downto 0)  -- Résultat ternaire
    );
end entity tnn_unit;

architecture rtl of tnn_unit is
    -- Types pour les opérations ternaires
    type ternary_value is (NEG, ZERO, POS);
    
    -- Fonction pour convertir un std_logic_vector en valeur ternaire
    function to_ternary(input: std_logic_vector(1 downto 0)) return ternary_value is
    begin
        case input is
            when "00" => return NEG;
            when "01" => return ZERO;
            when "10" => return POS;
            when others => return ZERO;
        end case;
    end function;
    
    -- Fonction pour la multiplication ternaire
    function ternary_multiply(a, b: ternary_value) return integer is
    begin
        case a is
            when NEG =>
                case b is
                    when NEG => return 1;
                    when ZERO => return 0;
                    when POS => return -1;
                end case;
            when ZERO =>
                return 0;
            when POS =>
                case b is
                    when NEG => return -1;
                    when ZERO => return 0;
                    when POS => return 1;
                end case;
        end case;
    end function;
    
    -- Signaux internes
    type state_type is (IDLE, COMPUTING, ACTIVATION, DONE);
    signal state : state_type;
    signal accumulator : signed(ACC_WIDTH-1 downto 0);
    signal cycle_count : natural range 0 to VECTOR_SIZE;
    
begin
    -- Process principal
    process(clk, rst_n)
        variable temp_product : integer;
        variable op1_trit, op2_trit : ternary_value;
    begin
        if rst_n = '0' then
            state <= IDLE;
            busy <= '0';
            done <= '0';
            accumulator <= (others => '0');
            cycle_count <= 0;
            result <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= COMPUTING;
                        busy <= '1';
                        done <= '0';
                        accumulator <= (others => '0');
                        cycle_count <= 0;
                    end if;
                    
                when COMPUTING =>
                    if cycle_count < VECTOR_SIZE then
                        -- Extraction des trits
                        op1_trit := to_ternary(operand1((cycle_count*2+1) downto cycle_count*2));
                        op2_trit := to_ternary(operand2((cycle_count*2+1) downto cycle_count*2));
                        
                        -- Multiplication et accumulation
                        temp_product := ternary_multiply(op1_trit, op2_trit);
                        accumulator <= accumulator + temp_product;
                        
                        cycle_count <= cycle_count + 1;
                    else
                        state <= ACTIVATION;
                    end if;
                    
                when ACTIVATION =>
                    -- Fonction d'activation ternaire simple (seuil)
                    if accumulator > 2 then
                        result <= "000000010"; -- POS
                    elsif accumulator < -2 then
                        result <= "000000000"; -- NEG
                    else
                        result <= "000000001"; -- ZERO
                    end if;
                    state <= DONE;
                    
                when DONE =>
                    busy <= '0';
                    done <= '1';
                    if start = '0' then
                        state <= IDLE;
                        done <= '0';
                    end if;
            end case;
        end if;
    end process;
    
end architecture rtl;