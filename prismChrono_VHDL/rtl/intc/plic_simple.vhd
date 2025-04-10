library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- PLIC Simplifié pour PrismChrono
-- Gère les interruptions externes avec priorités et claim/complete
entity plic_simple is
    generic (
        NUM_SOURCES : positive := 32;  -- Nombre de sources d'interruption
        NUM_TARGETS : positive := 2;   -- Nombre de cibles (coeurs CPU)
        PRIO_BITS   : positive := 3    -- Bits de priorité (0-7)
    );
    port (
        -- Signaux de base
        clk         : in  std_logic;
        rst_n       : in  std_logic;
        
        -- Sources d'interruption
        irq_sources : in  std_logic_vector(NUM_SOURCES-1 downto 0);
        
        -- Interface MMIO
        addr        : in  std_logic_vector(11 downto 0);  -- 4K espace d'adressage
        wdata       : in  std_logic_vector(31 downto 0);
        rdata       : out std_logic_vector(31 downto 0);
        we          : in  std_logic;
        re          : in  std_logic;
        
        -- Sorties interruption vers les cibles
        irq_targets : out std_logic_vector(NUM_TARGETS-1 downto 0)
    );
end entity plic_simple;

architecture rtl of plic_simple is
    -- Types et constantes
    type priority_array is array (0 to NUM_SOURCES-1) of std_logic_vector(PRIO_BITS-1 downto 0);
    type enable_array is array (0 to NUM_TARGETS-1) of std_logic_vector(NUM_SOURCES-1 downto 0);
    type threshold_array is array (0 to NUM_TARGETS-1) of std_logic_vector(PRIO_BITS-1 downto 0);
    
    -- Registres PLIC
    signal priorities  : priority_array := (others => (others => '0'));
    signal enables    : enable_array := (others => (others => '0'));
    signal thresholds : threshold_array := (others => (others => '0'));
    signal pending    : std_logic_vector(NUM_SOURCES-1 downto 0) := (others => '0');
    signal claimed    : std_logic_vector(NUM_SOURCES-1 downto 0) := (others => '0');
    
    -- Fonction utilitaire pour trouver l'interruption la plus prioritaire
    function max_priority(priorities_in : priority_array;
                         enables_in    : std_logic_vector;
                         pending_in    : std_logic_vector;
                         threshold_in  : std_logic_vector) return integer is
        variable max_prio : std_logic_vector(PRIO_BITS-1 downto 0) := (others => '0');
        variable max_idx  : integer := -1;
    begin
        for i in 0 to NUM_SOURCES-1 loop
            if enables_in(i) = '1' and pending_in(i) = '1' then
                if unsigned(priorities_in(i)) > unsigned(max_prio) and
                   unsigned(priorities_in(i)) > unsigned(threshold_in) then
                    max_prio := priorities_in(i);
                    max_idx := i;
                end if;
            end if;
        end loop;
        return max_idx;
    end function;

begin
    -- Processus de gestion des registres et des interruptions
    process(clk, rst_n)
        variable source_idx : integer;
        variable target_idx : integer;
    begin
        if rst_n = '0' then
            priorities  <= (others => (others => '0'));
            enables     <= (others => (others => '0'));
            thresholds  <= (others => (others => '0'));
            pending     <= (others => '0');
            claimed     <= (others => '0');
            rdata       <= (others => '0');
        elsif rising_edge(clk) then
            -- Mise à jour du registre pending
            for i in 0 to NUM_SOURCES-1 loop
                if irq_sources(i) = '1' and claimed(i) = '0' then
                    pending(i) <= '1';
                end if;
            end loop;
            
            -- Lecture/écriture MMIO
            if we = '1' then
                case addr(11 downto 8) is
                    when x"0" =>  -- Priorités (0x000-0x0FF)
                        source_idx := to_integer(unsigned(addr(7 downto 2)));
                        if source_idx < NUM_SOURCES then
                            priorities(source_idx) <= wdata(PRIO_BITS-1 downto 0);
                        end if;
                    
                    when x"2" =>  -- Enable bits (0x200-0x2FF)
                        target_idx := to_integer(unsigned(addr(7 downto 5)));
                        source_idx := to_integer(unsigned(addr(4 downto 2)));
                        if target_idx < NUM_TARGETS and source_idx < NUM_SOURCES then
                            enables(target_idx)(source_idx) <= wdata(0);
                        end if;
                    
                    when x"3" =>  -- Threshold (0x300-0x3FF)
                        target_idx := to_integer(unsigned(addr(7 downto 2)));
                        if target_idx < NUM_TARGETS then
                            thresholds(target_idx) <= wdata(PRIO_BITS-1 downto 0);
                        end if;
                    
                    when x"4" =>  -- Claim/Complete (0x400-0x4FF)
                        target_idx := to_integer(unsigned(addr(7 downto 2)));
                        if target_idx < NUM_TARGETS then
                            source_idx := to_integer(unsigned(wdata(5 downto 0)));
                            if source_idx < NUM_SOURCES then
                                pending(source_idx) <= '0';
                                claimed(source_idx) <= '1';
                            end if;
                        end if;
                    
                    when others => null;
                end case;
            elsif re = '1' then
                case addr(11 downto 8) is
                    when x"0" =>  -- Priorités
                        source_idx := to_integer(unsigned(addr(7 downto 2)));
                        if source_idx < NUM_SOURCES then
                            rdata <= (PRIO_BITS-1 downto 0 => priorities(source_idx),
                                     others => '0');
                        end if;
                    
                    when x"2" =>  -- Enable bits
                        target_idx := to_integer(unsigned(addr(7 downto 5)));
                        source_idx := to_integer(unsigned(addr(4 downto 2)));
                        if target_idx < NUM_TARGETS and source_idx < NUM_SOURCES then
                            rdata <= (0 => enables(target_idx)(source_idx),
                                     others => '0');
                        end if;
                    
                    when x"3" =>  -- Threshold
                        target_idx := to_integer(unsigned(addr(7 downto 2)));
                        if target_idx < NUM_TARGETS then
                            rdata <= (PRIO_BITS-1 downto 0 => thresholds(target_idx),
                                     others => '0');
                        end if;
                    
                    when x"4" =>  -- Claim/Complete
                        target_idx := to_integer(unsigned(addr(7 downto 2)));
                        if target_idx < NUM_TARGETS then
                            -- Retourne l'ID de l'interruption la plus prioritaire
                            source_idx := max_priority(priorities, enables(target_idx),
                                                      pending, thresholds(target_idx));
                            if source_idx >= 0 then
                                rdata <= std_logic_vector(to_unsigned(source_idx, 32));
                                pending(source_idx) <= '0';
                                claimed(source_idx) <= '1';
                            else
                                rdata <= (others => '0');
                            end if;
                        end if;
                    
                    when others =>
                        rdata <= (others => '0');
                end case;
            end if;
        end if;
    end process;
    
    -- Génération des interruptions pour chaque cible
    process(all)
    begin
        for i in 0 to NUM_TARGETS-1 loop
            if max_priority(priorities, enables(i), pending, thresholds(i)) >= 0 then
                irq_targets(i) <= '1';
            else
                irq_targets(i) <= '0';
            end if;
        end loop;
    end process;
    
end architecture rtl;