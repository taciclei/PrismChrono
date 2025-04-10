library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Unité de gestion des instructions atomiques
-- Implémente LR.T/SC.T pour PrismChrono
entity atomic_unit is
    port (
        -- Signaux de base
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Interface avec le pipeline
        op_atomic   : in  std_logic;                     -- Indique une instruction atomique
        op_lr       : in  std_logic;                     -- Load Reserved
        op_sc       : in  std_logic;                     -- Store Conditional
        addr        : in  std_logic_vector(31 downto 0); -- Adresse mémoire
        data_in     : in  std_logic_vector(11 downto 0); -- Données à écrire (4 trits)
        data_out    : out std_logic_vector(11 downto 0); -- Données lues
        
        -- Interface avec le cache L1
        cache_ready : in  std_logic;
        cache_valid : in  std_logic;
        cache_we    : out std_logic;
        cache_addr  : out std_logic_vector(31 downto 0);
        cache_wdata : out std_logic_vector(11 downto 0);
        cache_rdata : in  std_logic_vector(11 downto 0);
        
        -- Contrôle et status
        busy        : out std_logic;                    -- Unité occupée
        success     : out std_logic                     -- SC.T réussi
    );
end entity atomic_unit;

architecture rtl of atomic_unit is
    -- Registres pour la réservation
    signal reserved_valid : std_logic;
    signal reserved_addr  : std_logic_vector(31 downto 0);
    
    -- États de la FSM
    type state_type is (IDLE, LR_READ, SC_CHECK, SC_WRITE);
    signal state : state_type;
    
begin
    -- FSM pour la gestion des opérations atomiques
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            reserved_valid <= '0';
            reserved_addr <= (others => '0');
            busy <= '0';
            success <= '0';
            cache_we <= '0';
            cache_addr <= (others => '0');
            cache_wdata <= (others => '0');
            data_out <= (others => '0');
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if op_atomic = '1' then
                        busy <= '1';
                        if op_lr = '1' then
                            state <= LR_READ;
                            cache_addr <= addr;
                            cache_we <= '0';
                        elsif op_sc = '1' then
                            state <= SC_CHECK;
                        end if;
                    else
                        busy <= '0';
                    end if;
                    
                when LR_READ =>
                    if cache_ready = '1' and cache_valid = '1' then
                        data_out <= cache_rdata;
                        reserved_valid <= '1';
                        reserved_addr <= addr;
                        state <= IDLE;
                        busy <= '0';
                    end if;
                    
                when SC_CHECK =>
                    if reserved_valid = '1' and reserved_addr = addr then
                        state <= SC_WRITE;
                        cache_addr <= addr;
                        cache_wdata <= data_in;
                        cache_we <= '1';
                    else
                        success <= '0';
                        state <= IDLE;
                        busy <= '0';
                    end if;
                    
                when SC_WRITE =>
                    if cache_ready = '1' then
                        success <= '1';
                        reserved_valid <= '0';
                        state <= IDLE;
                        busy <= '0';
                        cache_we <= '0';
                    end if;
            end case;
        end if;
    end process;
    
    -- Invalidation de la réservation sur écriture concurrente
    -- Cette logique devrait être étendue pour gérer les écritures
    -- depuis d'autres cœurs dans un système multi-cœur
    process(clk)
    begin
        if rising_edge(clk) then
            if reserved_valid = '1' and
               cache_valid = '1' and
               cache_we = '1' and
               cache_addr = reserved_addr then
                reserved_valid <= '0';
            end if;
        end if;
    end process;
    
end architecture rtl;