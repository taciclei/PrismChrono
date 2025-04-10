library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Module de réception UART
entity uart_rx is
    generic (
        CLK_FREQ    : integer := 25000000;  -- Fréquence d'horloge en Hz
        BAUD_RATE   : integer := 115200      -- Débit en bauds
    );
    port (
        clk         : in  std_logic;                     -- Horloge système
        rst         : in  std_logic;                     -- Reset asynchrone
        rx_serial   : in  std_logic;                     -- Entrée série
        rx_data     : out std_logic_vector(7 downto 0);  -- Données reçues (8 bits)
        rx_valid    : out std_logic;                     -- Signal indiquant que des données valides sont disponibles
        rx_error    : out std_logic                      -- Signal indiquant une erreur de réception
    );
end entity uart_rx;

architecture rtl of uart_rx is
    -- Constantes
    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    constant HALF_BIT   : integer := BIT_PERIOD / 2;
    
    -- Types pour la FSM
    type RxStateType is (
        IDLE,       -- État d'attente
        START_BIT,  -- Détection du bit de start
        DATA_BITS,  -- Réception des bits de données
        STOP_BIT,   -- Vérification du bit de stop
        DONE        -- Réception terminée
    );
    
    -- Signaux internes
    signal state_reg    : RxStateType := IDLE;
    signal state_next   : RxStateType := IDLE;
    signal bit_counter  : integer range 0 to 7 := 0;
    signal bit_timer    : integer range 0 to BIT_PERIOD-1 := 0;
    signal shift_reg    : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid_reg : std_logic := '0';
    signal rx_error_reg : std_logic := '0';
    signal rx_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Synchronisation de l'entrée série (pour éviter les métastabilités)
    signal rx_sync1     : std_logic := '1';
    signal rx_sync2     : std_logic := '1';
    
begin
    -- Processus de synchronisation de l'entrée série
    process(clk, rst)
    begin
        if rst = '1' then
            rx_sync1 <= '1';
            rx_sync2 <= '1';
        elsif rising_edge(clk) then
            rx_sync1 <= rx_serial;
            rx_sync2 <= rx_sync1;
        end if;
    end process;
    
    -- Processus synchrone pour mettre à jour l'état
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état
            state_reg <= IDLE;
            bit_counter <= 0;
            bit_timer <= 0;
            shift_reg <= (others => '0');
            rx_valid_reg <= '0';
            rx_error_reg <= '0';
            rx_data_reg <= (others => '0');
        elsif rising_edge(clk) then
            -- Par défaut, on maintient les valeurs
            rx_valid_reg <= '0';  -- Pulse d'un cycle
            rx_error_reg <= '0';  -- Pulse d'un cycle
            
            case state_reg is
                when IDLE =>
                    -- Détection du bit de start (transition de 1 à 0)
                    if rx_sync2 = '0' then
                        state_reg <= START_BIT;
                        bit_timer <= 0;
                    end if;
                    
                when START_BIT =>
                    -- Échantillonnage au milieu du bit de start pour confirmer
                    if bit_timer = HALF_BIT then
                        if rx_sync2 = '0' then
                            -- Start bit valide, préparation pour les bits de données
                            state_reg <= DATA_BITS;
                            bit_timer <= 0;
                            bit_counter <= 0;
                        else
                            -- Faux start bit, retour à IDLE
                            state_reg <= IDLE;
                        end if;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
                    
                when DATA_BITS =>
                    -- Échantillonnage au milieu de chaque bit de données
                    if bit_timer = BIT_PERIOD then
                        bit_timer <= 0;
                        -- Décalage du registre et capture du bit
                        shift_reg <= rx_sync2 & shift_reg(7 downto 1);
                        
                        if bit_counter = 7 then
                            -- Tous les bits de données reçus, passage au bit de stop
                            state_reg <= STOP_BIT;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
                    
                when STOP_BIT =>
                    -- Échantillonnage au milieu du bit de stop
                    if bit_timer = BIT_PERIOD then
                        if rx_sync2 = '1' then
                            -- Stop bit valide, données valides
                            state_reg <= DONE;
                            rx_data_reg <= shift_reg;
                            rx_valid_reg <= '1';
                        else
                            -- Erreur de framing (stop bit invalide)
                            state_reg <= IDLE;
                            rx_error_reg <= '1';
                        end if;
                    else
                        bit_timer <= bit_timer + 1;
                    end if;
                    
                when DONE =>
                    -- Réception terminée, retour à IDLE
                    state_reg <= IDLE;
                    
                when others =>
                    state_reg <= IDLE;
            end case;
        end if;
    end process;
    
    -- Assignation des sorties
    rx_data <= rx_data_reg;
    rx_valid <= rx_valid_reg;
    rx_error <= rx_error_reg;
    
end architecture rtl;