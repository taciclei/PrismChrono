library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import des packages personnalisés
library work;
use work.prismchrono_types_pkg.all;

-- Contrôleur I²C maître pour PrismChrono
-- Supporte les opérations de base I²C (START, STOP, ACK/NACK)
-- Interface MMIO pour configuration et données
entity i2c_controller is
    port (
        -- Signaux système
        clk         : in  std_logic;  -- Horloge système
        rst_n       : in  std_logic;  -- Reset asynchrone actif bas
        
        -- Interface MMIO
        addr        : in  std_logic_vector(3 downto 0);   -- Adresse registre
        data_in     : in  std_logic_vector(23 downto 0);  -- Données entrantes
        data_out    : out std_logic_vector(23 downto 0);  -- Données sortantes
        we          : in  std_logic;                      -- Write enable
        re          : in  std_logic;                      -- Read enable
        ready       : out std_logic;                      -- Prêt pour transaction
        
        -- Interface I²C
        i2c_scl     : inout std_logic;  -- Serial Clock Line
        i2c_sda     : inout std_logic   -- Serial Data Line
    );
end entity i2c_controller;

architecture rtl of i2c_controller is
    -- Registres de configuration et contrôle
    type registers_t is record
        ctrl    : std_logic_vector(23 downto 0);  -- Registre de contrôle
        status  : std_logic_vector(23 downto 0);  -- Registre de statut
        divider : std_logic_vector(23 downto 0);  -- Diviseur d'horloge
        addr    : std_logic_vector(7 downto 0);   -- Adresse esclave
        tx_data : std_logic_vector(7 downto 0);   -- Données à transmettre
        rx_data : std_logic_vector(7 downto 0);   -- Données reçues
    end record;
    
    signal regs : registers_t := (
        ctrl    => (others => '0'),
        status  => (others => '0'),
        divider => (others => '0'),
        addr    => (others => '0'),
        tx_data => (others => '0'),
        rx_data => (others => '0')
    );
    
    -- Bits du registre de contrôle
    constant CTRL_ENABLE    : integer := 0;  -- Active le contrôleur
    constant CTRL_START     : integer := 1;  -- Générer START
    constant CTRL_STOP      : integer := 2;  -- Générer STOP
    constant CTRL_RW        : integer := 3;  -- 0=Write, 1=Read
    constant CTRL_ACK       : integer := 4;  -- Générer ACK
    constant CTRL_IE        : integer := 5;  -- Interrupt enable
    
    -- Bits du registre de statut
    constant STAT_BUSY      : integer := 0;  -- Transaction en cours
    constant STAT_RX_VALID  : integer := 1;  -- Données reçues valides
    constant STAT_ACK_ERROR : integer := 2;  -- Erreur ACK
    constant STAT_ARB_LOST  : integer := 3;  -- Arbitrage perdu
    
    -- États de la machine d'états
    type state_t is (IDLE, START, SEND_ADDR, SEND_DATA, 
                     RECV_DATA, WAIT_ACK, SEND_ACK, STOP);
    signal state : state_t := IDLE;
    
    -- Signaux internes
    signal bit_counter   : integer range 0 to 8 := 0;
    signal clk_counter   : integer range 0 to 1023 := 0;
    signal shift_reg     : std_logic_vector(8 downto 0);
    signal scl_internal  : std_logic := '1';
    signal sda_internal  : std_logic := '1';
    signal scl_oen       : std_logic := '1';  -- '1' = high-Z
    signal sda_oen       : std_logic := '1';  -- '1' = high-Z
    
begin
    -- Processus de lecture/écriture des registres MMIO
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            regs <= (
                ctrl    => (others => '0'),
                status  => (others => '0'),
                divider => (others => '0'),
                addr    => (others => '0'),
                tx_data => (others => '0'),
                rx_data => (others => '0')
            );
        elsif rising_edge(clk) then
            -- Écriture registres
            if we = '1' then
                case addr is
                    when "0000" => regs.ctrl    <= data_in;
                    when "0001" => regs.divider <= data_in;
                    when "0010" => regs.addr    <= data_in(7 downto 0);
                    when "0011" => regs.tx_data <= data_in(7 downto 0);
                    when others => null;
                end case;
            end if;
            
            -- Mise à jour statut
            regs.status(STAT_BUSY) <= '0' when state = IDLE else '1';
            
            -- Lecture données reçues
            if state = IDLE and regs.status(STAT_RX_VALID) = '1' then
                if re = '1' and addr = "0100" then
                    regs.status(STAT_RX_VALID) <= '0';
                end if;
            end if;
        end if;
    end process;
    
    -- Processus de génération d'horloge I²C
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            clk_counter <= 0;
            scl_internal <= '1';
        elsif rising_edge(clk) then
            if state /= IDLE then
                if clk_counter = 0 then
                    clk_counter <= to_integer(unsigned(regs.divider));
                    scl_internal <= not scl_internal;
                else
                    clk_counter <= clk_counter - 1;
                end if;
            else
                scl_internal <= '1';
            end if;
        end if;
    end process;
    
    -- Machine d'états principale
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            bit_counter <= 0;
            shift_reg <= (others => '1');
            sda_internal <= '1';
            scl_oen <= '1';
            sda_oen <= '1';
            regs.status(STAT_ACK_ERROR) <= '0';
            regs.status(STAT_ARB_LOST) <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if regs.ctrl(CTRL_ENABLE) = '1' and regs.ctrl(CTRL_START) = '1' then
                        state <= START;
                        sda_internal <= '0';
                        sda_oen <= '0';
                        -- Préparer l'adresse + bit R/W
                        shift_reg <= regs.addr & regs.ctrl(CTRL_RW) & '0';
                    end if;
                
                when START =>
                    if scl_internal = '0' then
                        state <= SEND_ADDR;
                        bit_counter <= 8;
                        scl_oen <= '0';
                    end if;
                
                when SEND_ADDR =>
                    if scl_internal'event then
                        if scl_internal = '0' then
                            if bit_counter = 0 then
                                state <= WAIT_ACK;
                                sda_oen <= '1';  -- Relâcher SDA pour ACK
                            else
                                bit_counter <= bit_counter - 1;
                                sda_internal <= shift_reg(8);
                                shift_reg <= shift_reg(7 downto 0) & '1';
                            end if;
                        end if;
                    end if;
                
                when WAIT_ACK =>
                    if scl_internal'event and scl_internal = '1' then
                        if i2c_sda = '1' then  -- NACK reçu
                            regs.status(STAT_ACK_ERROR) <= '1';
                            state <= STOP;
                        else  -- ACK reçu
                            if regs.ctrl(CTRL_RW) = '0' then
                                state <= SEND_DATA;
                                shift_reg <= regs.tx_data & '0';
                                bit_counter <= 8;
                                sda_oen <= '0';
                            else
                                state <= RECV_DATA;
                                bit_counter <= 8;
                            end if;
                        end if;
                    end if;
                
                when SEND_DATA =>
                    if scl_internal'event then
                        if scl_internal = '0' then
                            if bit_counter = 0 then
                                state <= WAIT_ACK;
                                sda_oen <= '1';
                            else
                                bit_counter <= bit_counter - 1;
                                sda_internal <= shift_reg(8);
                                shift_reg <= shift_reg(7 downto 0) & '1';
                            end if;
                        end if;
                    end if;
                
                when RECV_DATA =>
                    if scl_internal'event then
                        if scl_internal = '1' then
                            shift_reg <= shift_reg(7 downto 0) & i2c_sda;
                            if bit_counter = 0 then
                                state <= SEND_ACK;
                                sda_oen <= '0';
                                sda_internal <= not regs.ctrl(CTRL_ACK);
                                regs.rx_data <= shift_reg(7 downto 0);
                                regs.status(STAT_RX_VALID) <= '1';
                            else
                                bit_counter <= bit_counter - 1;
                            end if;
                        end if;
                    end if;
                
                when SEND_ACK =>
                    if scl_internal'event and scl_internal = '0' then
                        if regs.ctrl(CTRL_STOP) = '1' then
                            state <= STOP;
                        else
                            state <= RECV_DATA;
                            bit_counter <= 8;
                            sda_oen <= '1';
                        end if;
                    end if;
                
                when STOP =>
                    if scl_internal = '1' then
                        sda_internal <= '0';
                        sda_oen <= '0';
                        if clk_counter = 0 then
                            sda_internal <= '1';
                            state <= IDLE;
                            regs.ctrl(CTRL_START) <= '0';
                            regs.ctrl(CTRL_STOP) <= '0';
                        end if;
                    end if;
            end case;
            
            -- Détection perte d'arbitrage
            if state /= IDLE and state /= STOP and sda_oen = '0' then
                if i2c_sda /= sda_internal then
                    regs.status(STAT_ARB_LOST) <= '1';
                    state <= IDLE;
                    scl_oen <= '1';
                    sda_oen <= '1';
                end if;
            end if;
        end if;
    end process;
    
    -- Sorties
    ready <= '1' when state = IDLE else '0';
    data_out <= x"0000" & regs.rx_data when addr = "0100" else
                regs.status when addr = "0101" else
                (others => '0');
    
    -- Interface I²C
    i2c_scl <= '0' when scl_oen = '0' and scl_internal = '0' else 'Z';
    i2c_sda <= '0' when sda_oen = '0' and sda_internal = '0' else 'Z';
    
end architecture rtl;