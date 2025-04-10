library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Module de transmission UART
entity uart_tx is
    generic (
        CLK_FREQ    : integer := 25000000;  -- Fréquence d'horloge en Hz
        BAUD_RATE   : integer := 115200      -- Débit en bauds
    );
    port (
        clk         : in  std_logic;                     -- Horloge système
        rst         : in  std_logic;                     -- Reset asynchrone
        tx_data     : in  std_logic_vector(7 downto 0);  -- Données à transmettre (8 bits)
        tx_start    : in  std_logic;                     -- Signal de démarrage de transmission
        tx_busy     : out std_logic;                     -- Signal indiquant que le transmetteur est occupé
        tx_done     : out std_logic;                     -- Signal indiquant que la transmission est terminée
        tx_serial   : out std_logic                      -- Sortie série
    );
end entity uart_tx;

architecture rtl of uart_tx is
    -- Constantes
    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    
    -- Types pour la FSM
    type TxStateType is (
        IDLE,       -- État d'attente
        START_BIT,  -- Envoi du bit de start
        DATA_BITS,  -- Envoi des bits de données
        STOP_BIT,   -- Envoi du bit de stop
        DONE        -- Transmission terminée
    );
    
    -- Signaux internes
    signal state_reg    : TxStateType := IDLE;
    signal state_next   : TxStateType := IDLE;
    signal bit_counter  : integer range 0 to 7 := 0;
    signal bit_timer    : integer range 0 to BIT_PERIOD-1 := 0;
    signal shift_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy_reg  : std_logic := '0';
    signal tx_done_reg  : std_logic := '0';
    signal tx_serial_reg: std_logic := '1';  -- Ligne au repos à '1'
    
begin
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état
            state_reg <= IDLE;
            bit_counter <= 0;
            bit_timer <= 0;
            shift_reg <= (others => '0');
            tx_busy_reg <= '0';
            tx_done_reg <= '0';
            tx_serial_reg <= '1';
        elsif rising_edge(clk) then
            -- Par défaut, on maintient les valeurs
            tx_done_reg <= '0';  -- Pulse d'un cycle
            
            -- Gestion du timer de bit
            if state_reg /= IDLE then
                if bit_timer < BIT_PERIOD-1 then
                    bit_timer <= bit_timer + 1;
                else
                    bit_timer <= 0;
                    
                    -- Transition d'état basée sur le compteur de bits
                    case state_reg is
                        when START_BIT =>
                            state_reg <= DATA_BITS;
                            bit_counter <= 0;
                            tx_serial_reg <= shift_reg(0);  -- Premier bit de données
                            
                        when DATA_BITS =>
                            if bit_counter < 7 then
                                bit_counter <= bit_counter + 1;
                                -- Décalage du registre et envoi du bit suivant
                                shift_reg <= '0' & shift_reg(7 downto 1);
                                tx_serial_reg <= shift_reg(1);  -- Prochain bit
                            else
                                state_reg <= STOP_BIT;
                                tx_serial_reg <= '1';  -- Bit de stop
                            end if;
                            
                        when STOP_BIT =>
                            state_reg <= DONE;
                            
                        when DONE =>
                            state_reg <= IDLE;
                            tx_busy_reg <= '0';
                            tx_done_reg <= '1';
                            
                        when others =>
                            state_reg <= IDLE;
                    end case;
                end if;
            end if;
            
            -- Démarrage d'une nouvelle transmission
            if state_reg = IDLE and tx_start = '1' then
                state_reg <= START_BIT;
                shift_reg <= tx_data;
                bit_timer <= 0;
                tx_busy_reg <= '1';
                tx_serial_reg <= '0';  -- Bit de start (0)
            end if;
        end if;
    end process;
    
    -- Assignation des sorties
    tx_busy <= tx_busy_reg;
    tx_done <= tx_done_reg;
    tx_serial <= tx_serial_reg;
    
end architecture rtl;