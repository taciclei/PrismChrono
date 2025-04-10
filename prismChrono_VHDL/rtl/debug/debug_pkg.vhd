library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package debug_pkg is
  -- Codes de commande RSP (Remote Serial Protocol)
  constant CMD_STATUS    : std_logic_vector(7 downto 0) := x"3F";  -- '?' : Demande statut
  constant CMD_HALT      : std_logic_vector(7 downto 0) := x"68";  -- 'h' : Arrêt CPU
  constant CMD_CONTINUE  : std_logic_vector(7 downto 0) := x"63";  -- 'c' : Reprise exécution
  constant CMD_STEP      : std_logic_vector(7 downto 0) := x"73";  -- 's' : Pas à pas
  constant CMD_REG_READ  : std_logic_vector(7 downto 0) := x"67";  -- 'g' : Lecture registres
  constant CMD_REG_WRITE : std_logic_vector(7 downto 0) := x"47";  -- 'G' : Écriture registres
  constant CMD_MEM_READ  : std_logic_vector(7 downto 0) := x"6D";  -- 'm' : Lecture mémoire
  constant CMD_MEM_WRITE : std_logic_vector(7 downto 0) := x"4D";  -- 'M' : Écriture mémoire
  
  -- Types de registres accessibles
  constant REG_R0   : std_logic_vector(3 downto 0) := x"0";
  constant REG_R1   : std_logic_vector(3 downto 0) := x"1";
  constant REG_R2   : std_logic_vector(3 downto 0) := x"2";
  constant REG_R3   : std_logic_vector(3 downto 0) := x"3";
  constant REG_R4   : std_logic_vector(3 downto 0) := x"4";
  constant REG_R5   : std_logic_vector(3 downto 0) := x"5";
  constant REG_R6   : std_logic_vector(3 downto 0) := x"6";
  constant REG_R7   : std_logic_vector(3 downto 0) := x"7";
  constant REG_PC   : std_logic_vector(3 downto 0) := x"8";
  constant REG_CSR  : std_logic_vector(3 downto 0) := x"9";
  
  -- Types pour le module de débogage
  type debug_state_t is (IDLE, PARSE_CMD, EXEC_CMD, WAIT_CPU_HALT, WAIT_MEM);
  
end package debug_pkg;