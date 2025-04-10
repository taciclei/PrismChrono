library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;
use work.debug_pkg.all;

-- UART pour le module de débogage
-- Implémente un UART simple avec FIFO RX/TX
entity uart_debug is
  generic (
    CLK_FREQ    : integer := 100_000_000;  -- Fréquence horloge (Hz)
    BAUD_RATE   : integer := 115200;        -- Vitesse UART (bps)
    FIFO_DEPTH  : integer := 16             -- Profondeur FIFO RX/TX
  );
  port (
    -- Interface système
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    
    -- Interface UART physique
    uart_rx     : in  std_logic;
    uart_tx     : out std_logic;
    
    -- Interface FIFO RX
    rx_data     : out std_logic_vector(7 downto 0);
    rx_valid    : out std_logic;
    rx_ready    : in  std_logic;
    
    -- Interface FIFO TX
    tx_data     : in  std_logic_vector(7 downto 0);
    tx_valid    : in  std_logic;
    tx_ready    : out std_logic
  );
end entity uart_debug;

architecture rtl of uart_debug is
  -- Constantes
  constant CLKS_PER_BIT : integer := CLK_FREQ / BAUD_RATE;
  
  -- Types
  type uart_state_t is (IDLE, START, DATA, STOP);
  
  -- Signaux RX
  signal rx_state     : uart_state_t;
  signal rx_clk_count : integer range 0 to CLKS_PER_BIT-1;
  signal rx_bit_count : integer range 0 to 7;
  signal rx_shift_reg : std_logic_vector(7 downto 0);
  signal rx_fifo_we   : std_logic;
  
  -- Signaux TX
  signal tx_state     : uart_state_t;
  signal tx_clk_count : integer range 0 to CLKS_PER_BIT-1;
  signal tx_bit_count : integer range 0 to 7;
  signal tx_shift_reg : std_logic_vector(7 downto 0);
  signal tx_fifo_re   : std_logic;
  
begin

  -- Process de réception UART
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      rx_state <= IDLE;
      rx_clk_count <= 0;
      rx_bit_count <= 0;
      rx_shift_reg <= (others => '0');
      rx_fifo_we <= '0';
      
    elsif rising_edge(clk) then
      rx_fifo_we <= '0';
      
      case rx_state is
        when IDLE =>
          if uart_rx = '0' then  -- Start bit détecté
            rx_state <= START;
            rx_clk_count <= CLKS_PER_BIT/2;  -- Échantillonne au milieu du bit
          end if;
          
        when START =>
          if rx_clk_count = 0 then
            if uart_rx = '0' then  -- Vérifie start bit valide
              rx_state <= DATA;
              rx_clk_count <= CLKS_PER_BIT-1;
              rx_bit_count <= 0;
            else
              rx_state <= IDLE;
            end if;
          else
            rx_clk_count <= rx_clk_count - 1;
          end if;
          
        when DATA =>
          if rx_clk_count = 0 then
            rx_shift_reg <= uart_rx & rx_shift_reg(7 downto 1);
            if rx_bit_count = 7 then
              rx_state <= STOP;
            else
              rx_bit_count <= rx_bit_count + 1;
            end if;
            rx_clk_count <= CLKS_PER_BIT-1;
          else
            rx_clk_count <= rx_clk_count - 1;
          end if;
          
        when STOP =>
          if rx_clk_count = 0 then
            if uart_rx = '1' then  -- Vérifie stop bit
              rx_fifo_we <= '1';
            end if;
            rx_state <= IDLE;
          else
            rx_clk_count <= rx_clk_count - 1;
          end if;
      end case;
    end if;
  end process;

  -- Process de transmission UART
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      tx_state <= IDLE;
      tx_clk_count <= 0;
      tx_bit_count <= 0;
      tx_shift_reg <= (others => '1');
      uart_tx <= '1';
      tx_ready <= '0';
      
    elsif rising_edge(clk) then
      case tx_state is
        when IDLE =>
          uart_tx <= '1';
          tx_ready <= '1';
          if tx_valid = '1' then
            tx_shift_reg <= tx_data;
            tx_state <= START;
            tx_clk_count <= CLKS_PER_BIT-1;
            tx_ready <= '0';
          end if;
          
        when START =>
          uart_tx <= '0';  -- Start bit
          if tx_clk_count = 0 then
            tx_state <= DATA;
            tx_clk_count <= CLKS_PER_BIT-1;
            tx_bit_count <= 0;
          else
            tx_clk_count <= tx_clk_count - 1;
          end if;
          
        when DATA =>
          uart_tx <= tx_shift_reg(0);
          if tx_clk_count = 0 then
            tx_shift_reg <= '1' & tx_shift_reg(7 downto 1);
            if tx_bit_count = 7 then
              tx_state <= STOP;
            else
              tx_bit_count <= tx_bit_count + 1;
            end if;
            tx_clk_count <= CLKS_PER_BIT-1;
          else
            tx_clk_count <= tx_clk_count - 1;
          end if;
          
        when STOP =>
          uart_tx <= '1';  -- Stop bit
          if tx_clk_count = 0 then
            tx_state <= IDLE;
          else
            tx_clk_count <= tx_clk_count - 1;
          end if;
      end case;
    end if;
  end process;

end architecture rtl;