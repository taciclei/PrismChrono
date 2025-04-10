library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

-- Contrôleur UART avec interface MMIO
entity uart_controller is
    generic (
        CLK_FREQ    : integer := 25000000;  -- Fréquence d'horloge en Hz
        BAUD_RATE   : integer := 115200      -- Débit en bauds
    );
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        
        -- Interface MMIO
        addr            : in  EncodedAddress;                -- Adresse relative (offset depuis UART_BASE_ADDR)
        data_in         : in  EncodedWord;                   -- Données à écrire (depuis le CPU)
        data_out        : out EncodedWord;                   -- Données à lire (vers le CPU)
        read_en         : in  std_logic;                     -- Signal de lecture
        write_en        : in  std_logic;                     -- Signal d'écriture
        
        -- Interface série
        uart_tx_serial  : out std_logic;                     -- Sortie série TX
        uart_rx_serial  : in  std_logic                      -- Entrée série RX
    );
end entity uart_controller;

architecture rtl of uart_controller is
    -- Composant de transmission UART
    component uart_tx is
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
    end component;
    
    -- Composant de réception UART
    component uart_rx is
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
    end component;
    
    -- Registres MMIO
    signal tx_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_data_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal status_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal control_reg  : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Bits du registre de statut
    constant STATUS_TX_READY_BIT : integer := 0;  -- '1' si prêt à transmettre
    constant STATUS_TX_BUSY_BIT  : integer := 1;  -- '1' si en cours de transmission
    constant STATUS_RX_READY_BIT : integer := 2;  -- '1' si données disponibles
    constant STATUS_RX_ERROR_BIT : integer := 3;  -- '1' si erreur de réception
    
    -- Signaux pour la transmission
    signal tx_start     : std_logic := '0';
    signal tx_busy      : std_logic := '0';
    signal tx_done      : std_logic := '0';
    
    -- Signaux pour la réception
    signal rx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_valid     : std_logic := '0';
    signal rx_error     : std_logic := '0';
    
    -- Fonction pour convertir un octet binaire en tryte ternaire
    function binary_to_ternary(bin : std_logic_vector(7 downto 0)) return EncodedTryte is
        variable result : EncodedTryte := (others => '0');
    begin
        -- Conversion simple: chaque groupe de 3 bits devient un trit
        -- Cette implémentation est simplifiée et pourrait être améliorée
        -- pour une conversion plus précise entre binaire et ternaire
        
        -- Premier trit (bits 7-6-5)
        if bin(7) = '1' then
            result(5 downto 4) := TRIT_P;  -- Positif
        elsif bin(6) = '1' then
            result(5 downto 4) := TRIT_Z;  -- Zéro
        else
            result(5 downto 4) := TRIT_N;  -- Négatif
        end if;
        
        -- Deuxième trit (bits 4-3-2)
        if bin(4) = '1' then
            result(3 downto 2) := TRIT_P;  -- Positif
        elsif bin(3) = '1' then
            result(3 downto 2) := TRIT_Z;  -- Zéro
        else
            result(3 downto 2) := TRIT_N;  -- Négatif
        end if;
        
        -- Troisième trit (bits 1-0 + padding)
        if bin(1) = '1' then
            result(1 downto 0) := TRIT_P;  -- Positif
        elsif bin(0) = '1' then
            result(1 downto 0) := TRIT_Z;  -- Zéro
        else
            result(1 downto 0) := TRIT_N;  -- Négatif
        end if;
        
        return result;
    end function;
    
    -- Fonction pour convertir un tryte ternaire en octet binaire
    function ternary_to_binary(tern : EncodedTryte) return std_logic_vector is
        variable result : std_logic_vector(7 downto 0) := (others => '0');
    begin
        -- Conversion simple: chaque trit devient un groupe de bits
        -- Cette implémentation est simplifiée et pourrait être améliorée
        
        -- Premier trit -> bits 7-6-5
        case tern(5 downto 4) is
            when TRIT_P => result(7) := '1';
            when TRIT_Z => result(6) := '1';
            when TRIT_N => result(5) := '1';
            when others => null;
        end case;
        
        -- Deuxième trit -> bits 4-3-2
        case tern(3 downto 2) is
            when TRIT_P => result(4) := '1';
            when TRIT_Z => result(3) := '1';
            when TRIT_N => result(2) := '1';
            when others => null;
        end case;
        
        -- Troisième trit -> bits 1-0
        case tern(1 downto 0) is
            when TRIT_P => result(1) := '1';
            when TRIT_Z => result(0) := '1';
            when TRIT_N => -- Pas de bit à mettre à 1
            when others => null;
        end case;
        
        return result;
    end function;
    
begin
    -- Instanciation du module de transmission
    inst_uart_tx : uart_tx
        generic map (
            CLK_FREQ => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            tx_data => tx_data_reg,
            tx_start => tx_start,
            tx_busy => tx_busy,
            tx_done => tx_done,
            tx_serial => uart_tx_serial
        );
    
    -- Instanciation du module de réception
    inst_uart_rx : uart_rx
        generic map (
            CLK_FREQ => CLK_FREQ,
            BAUD_RATE => BAUD_RATE
        )
        port map (
            clk => clk,
            rst => rst,
            rx_serial => uart_rx_serial,
            rx_data => rx_data,
            rx_valid => rx_valid,
            rx_error => rx_error
        );
    
    -- Processus pour gérer les accès MMIO
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation des registres
            tx_data_reg <= (others => '0');
            status_reg <= (others => '0');
            control_reg <= (others => '0');
            tx_start <= '0';
        elsif rising_edge(clk) then
            -- Par défaut, on maintient les valeurs
            tx_start <= '0';  -- Pulse d'un cycle
            
            -- Mise à jour du registre de statut
            status_reg(STATUS_TX_READY_BIT) <= not tx_busy;
            status_reg(STATUS_TX_BUSY_BIT) <= tx_busy;
            status_reg(STATUS_RX_READY_BIT) <= '0';  -- Par défaut, pas de données
            status_reg(STATUS_RX_ERROR_BIT) <= '0';  -- Par défaut, pas d'erreur
            
            -- Gestion de la réception
            if rx_valid = '1' then
                rx_data_reg <= rx_data;
                status_reg(STATUS_RX_READY_BIT) <= '1';
            end if;
            
            if rx_error = '1' then
                status_reg(STATUS_RX_ERROR_BIT) <= '1';
            end if;
            
            -- Gestion des accès en écriture
            if write_en = '1' then
                -- Décodage de l'adresse
                if addr = UART_TX_DATA_OFFSET then
                    -- Écriture dans le registre TX_DATA
                    -- Conversion du tryte ternaire en octet binaire
                    tx_data_reg <= ternary_to_binary(data_in(5 downto 0));
                    tx_start <= '1';  -- Démarrage de la transmission
                elsif addr = UART_CONTROL_OFFSET then
                    -- Écriture dans le registre de contrôle
                    control_reg <= ternary_to_binary(data_in(5 downto 0));
                end if;
            end if;
            
            -- Gestion des accès en lecture
            if read_en = '1' then
                -- Initialisation de la sortie
                data_out <= (others => '0');
                
                -- Décodage de l'adresse
                if addr = UART_RX_DATA_OFFSET then
                    -- Lecture du registre RX_DATA
                    -- Conversion de l'octet binaire en tryte ternaire
                    data_out(5 downto 0) <= binary_to_ternary(rx_data_reg);
                    -- Réinitialisation du flag RX_READY
                    status_reg(STATUS_RX_READY_BIT) <= '0';
                elsif addr = UART_STATUS_OFFSET then
                    -- Lecture du registre de statut
                    data_out(5 downto 0) <= binary_to_ternary(status_reg);
                elsif addr = UART_CONTROL_OFFSET then
                    -- Lecture du registre de contrôle
                    data_out(5 downto 0) <= binary_to_ternary(control_reg);
                end if;
            end if;
        end if;
    end process;
    
end architecture rtl;