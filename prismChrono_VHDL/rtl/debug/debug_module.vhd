library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.prismchrono_pkg.all;

-- Module de débogage amélioré pour PrismChrono
-- Supporte les points d'arrêt sur adresse et l'accès mémoire facilité
entity debug_module is
  generic (
    NUM_BREAKPOINTS : positive := 4   -- Nombre de points d'arrêt supportés
  );
  port (
    -- Interface système
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    
    -- Interface UART
    uart_rx       : in  std_logic;
    uart_tx       : out std_logic;
    
    -- Interface avec le cœur CPU
    cpu_pc        : in  std_logic_vector(17 downto 0); -- PC actuel du CPU
    cpu_halt_req  : out std_logic;                     -- Demande d'arrêt du CPU
    cpu_halted    : in  std_logic;                     -- CPU arrêté
    cpu_resume    : out std_logic;                     -- Demande de reprise
    cpu_step      : out std_logic;                     -- Exécution pas à pas
    
    -- Accès aux registres CPU (quand halted = '1')
    reg_addr      : out std_logic_vector(3 downto 0);  -- Adresse du registre (R0-R7, PC, etc)
    reg_wdata     : out std_logic_vector(8 downto 0);  -- Donnée à écrire (9 bits = 3 trits)
    reg_rdata     : in  std_logic_vector(8 downto 0);  -- Donnée lue
    reg_we        : out std_logic;                     -- Write enable
    
    -- Accès mémoire (quand halted = '1')
    mem_addr      : out std_logic_vector(17 downto 0); -- Adresse mémoire (18 bits)
    mem_wdata     : out std_logic_vector(8 downto 0);  -- Donnée à écrire
    mem_rdata     : in  std_logic_vector(8 downto 0);  -- Donnée lue
    mem_we        : out std_logic;                     -- Write enable
    mem_valid     : out std_logic;                     -- Requête valide
    mem_ready     : in  std_logic                      -- Mémoire prête
  );
end entity debug_module;

architecture rtl of debug_module is
  -- États du module de débogage
  type debug_state_t is (IDLE, PARSE_CMD, EXEC_CMD, WAIT_CPU_HALT, WAIT_MEM);
  signal state : debug_state_t;
  
  -- Buffer de commande UART
  signal cmd_buffer : std_logic_vector(31 downto 0);  -- Étendu pour supporter les adresses
  signal cmd_len : natural range 0 to 4;              -- Longueur de la commande en octets
  signal cmd_valid : std_logic;
  
  -- Registres de contrôle
  signal halt_pending : std_logic;
  signal resume_pending : std_logic;
  signal step_pending : std_logic;
  
  -- Registres pour les points d'arrêt
  type breakpoint_array is array (0 to NUM_BREAKPOINTS-1) of std_logic_vector(17 downto 0);
  signal breakpoints : breakpoint_array := (others => (others => '0'));
  signal bp_enables : std_logic_vector(NUM_BREAKPOINTS-1 downto 0) := (others => '0');
  
  -- Fonction pour convertir un caractère hexadécimal en vecteur
  function hex_to_vector(hex_char : character) return std_logic_vector is
  begin
    case hex_char is
      when '0' => return x"0";
      when '1' => return x"1";
      when '2' => return x"2";
      when '3' => return x"3";
      when '4' => return x"4";
      when '5' => return x"5";
      when '6' => return x"6";
      when '7' => return x"7";
      when '8' => return x"8";
      when '9' => return x"9";
      when 'a'|'A' => return x"A";
      when 'b'|'B' => return x"B";
      when 'c'|'C' => return x"C";
      when 'd'|'D' => return x"D";
      when 'e'|'E' => return x"E";
      when 'f'|'F' => return x"F";
      when others => return x"0";
    end case;
  end function;
  
begin

  -- Process de détection des points d'arrêt
  process(clk)
  begin
    if rising_edge(clk) then
      -- Vérifie si le PC correspond à un point d'arrêt actif
      for i in 0 to NUM_BREAKPOINTS-1 loop
        if bp_enables(i) = '1' and cpu_pc = breakpoints(i) then
          cpu_halt_req <= '1';
        end if;
      end loop;
    end if;
  end process;

  -- Process principal de la machine à états
  process(clk, rst_n)
    variable addr_temp : std_logic_vector(17 downto 0);
    variable data_temp : std_logic_vector(8 downto 0);
  begin
    if rst_n = '0' then
      state <= IDLE;
      cpu_halt_req <= '0';
      cpu_resume <= '0';
      cpu_step <= '0';
      reg_we <= '0';
      mem_we <= '0';
      mem_valid <= '0';
      halt_pending <= '0';
      resume_pending <= '0';
      step_pending <= '0';
      cmd_len <= 0;
      
    elsif rising_edge(clk) then
      case state is
        when IDLE =>
          if cmd_valid = '1' then
            state <= PARSE_CMD;
          end if;
          
        when PARSE_CMD =>
          -- Décode la commande reçue via UART
          case cmd_buffer(7 downto 0) is
            when x"3F" =>  -- '?' : Status
              -- TODO: Envoyer l'état du CPU via UART
              state <= IDLE;
              
            when x"68" =>  -- 'h' : Halt
              cpu_halt_req <= '1';
              halt_pending <= '1';
              state <= WAIT_CPU_HALT;
              
            when x"63" =>  -- 'c' : Continue
              if cpu_halted = '1' then
                cpu_resume <= '1';
                resume_pending <= '1';
                state <= IDLE;
              end if;
              
            when x"73" =>  -- 's' : Step
              if cpu_halted = '1' then
                cpu_step <= '1';
                step_pending <= '1';
                state <= IDLE;
              end if;
              
            when x"7A" =>  -- 'z' : Set breakpoint
              if cmd_len >= 3 then  -- Commande + adresse (2 octets)
                addr_temp := cmd_buffer(23 downto 8);
                -- Trouve un slot libre
                for i in 0 to NUM_BREAKPOINTS-1 loop
                  if bp_enables(i) = '0' then
                    breakpoints(i) <= addr_temp;
                    bp_enables(i) <= '1';
                    exit;
                  end if;
                end loop;
              end if;
              state <= IDLE;
              
            when x"5A" =>  -- 'Z' : Remove breakpoint
              if cmd_len >= 3 then
                addr_temp := cmd_buffer(23 downto 8);
                -- Trouve et désactive le point d'arrêt
                for i in 0 to NUM_BREAKPOINTS-1 loop
                  if breakpoints(i) = addr_temp then
                    bp_enables(i) <= '0';
                    exit;
                  end if;
                end loop;
              end if;
              state <= IDLE;
              
            when x"6D" =>  -- 'm' : Read memory
              if cmd_len >= 3 and cpu_halted = '1' then
                mem_addr <= cmd_buffer(23 downto 8);
                mem_we <= '0';
                mem_valid <= '1';
                state <= WAIT_MEM;
              else
                state <= IDLE;
              end if;
              
            when x"4D" =>  -- 'M' : Write memory
              if cmd_len >= 4 and cpu_halted = '1' then
                mem_addr <= cmd_buffer(23 downto 8);
                mem_wdata <= cmd_buffer(31 downto 24) & "0";  -- Conversion en 9 bits
                mem_we <= '1';
                mem_valid <= '1';
                state <= WAIT_MEM;
              else
                state <= IDLE;
              end if;
              
            when others =>
              state <= IDLE;
          end case;
          
        when WAIT_CPU_HALT =>
          if cpu_halted = '1' then
            cpu_halt_req <= '0';
            halt_pending <= '0';
            state <= IDLE;
          end if;
          
        when WAIT_MEM =>
          if mem_ready = '1' then
            mem_valid <= '0';
            mem_we <= '0';
            state <= IDLE;
          end if;
          
        when others =>
          state <= IDLE;
      end case;
      
      -- Reset des signaux de contrôle
      if resume_pending = '1' then
        cpu_resume <= '0';
        resume_pending <= '0';
      end if;
      
      if step_pending = '1' then
        cpu_step <= '0';
        step_pending <= '0';
      end if;
    end if;
  end process;

end architecture rtl;