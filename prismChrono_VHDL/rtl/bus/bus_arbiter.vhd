library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.prismchrono_types_pkg.all;

entity bus_arbiter is
  generic (
    N_MASTERS : integer := 4  -- Nombre de maîtres (2 cœurs + MMU + DMA)
  );
  port (
    -- Signaux de contrôle
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    
    -- Interface maîtres
    m_req         : in  std_logic_vector(N_MASTERS-1 downto 0);
    m_addr        : in  std_logic_vector(N_MASTERS*24-1 downto 0);
    m_wr          : in  std_logic_vector(N_MASTERS-1 downto 0);
    m_wdata       : in  std_logic_vector(N_MASTERS*24-1 downto 0);
    m_valid       : out std_logic_vector(N_MASTERS-1 downto 0);
    m_rdata       : out std_logic_vector(N_MASTERS*24-1 downto 0);
    
    -- Interface esclave (DDR)
    s_req         : out std_logic;
    s_addr        : out std_logic_vector(23 downto 0);
    s_wr          : out std_logic;
    s_wdata       : out std_logic_vector(23 downto 0);
    s_valid       : in  std_logic;
    s_rdata       : in  std_logic_vector(23 downto 0)
  );
end entity bus_arbiter;

architecture rtl of bus_arbiter is
  -- États de l'arbitre
  type state_t is (IDLE, GRANT, WAIT_RESP);
  signal state : state_t;
  
  -- Signaux internes
  signal current_master : integer range 0 to N_MASTERS-1;
  signal next_master   : integer range 0 to N_MASTERS-1;
  signal grant_mask    : std_logic_vector(N_MASTERS-1 downto 0);
  
begin
  -- Processus d'arbitrage round-robin
  process(clk, rst_n)
  begin
    if rst_n = '0' then
      state <= IDLE;
      current_master <= 0;
      next_master <= 0;
      grant_mask <= (others => '0');
      s_req <= '0';
      m_valid <= (others => '0');
      
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          -- Chercher le prochain maître qui demande l'accès
          for i in 0 to N_MASTERS-1 loop
            if m_req(i) = '1' then
              state <= GRANT;
              current_master <= i;
              -- Préparer le masque pour le prochain cycle
              grant_mask <= (others => '0');
              grant_mask(i) <= '1';
              exit;
            end if;
          end loop;
          
        when GRANT =>
          -- Transmettre la requête du maître sélectionné
          s_req <= '1';
          s_addr <= m_addr(current_master*24+23 downto current_master*24);
          s_wr <= m_wr(current_master);
          s_wdata <= m_wdata(current_master*24+23 downto current_master*24);
          state <= WAIT_RESP;
          
        when WAIT_RESP =>
          if s_valid = '1' then
            -- Transmettre la réponse au maître
            m_valid <= grant_mask;
            m_rdata(current_master*24+23 downto current_master*24) <= s_rdata;
            s_req <= '0';
            state <= IDLE;
            
            -- Mettre à jour le prochain maître (round-robin)
            if current_master = N_MASTERS-1 then
              next_master <= 0;
            else
              next_master <= current_master + 1;
            end if;
          end if;
          
      end case;
    end if;
  end process;
  
end architecture rtl;