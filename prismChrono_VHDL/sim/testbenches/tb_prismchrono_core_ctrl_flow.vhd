library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_prismchrono_core_ctrl_flow is
    -- Testbench n'a pas de ports
end entity tb_prismchrono_core_ctrl_flow;

architecture sim of tb_prismchrono_core_ctrl_flow is
    -- Composant à tester
    component prismchrono_core is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            instr_data      : in  EncodedWord;                   -- Données d'instruction de la mémoire
            mem_data_in     : in  EncodedWord;                   -- Données de la mémoire (lecture)
            instr_addr      : out EncodedAddress;                -- Adresse pour la mémoire d'instructions
            mem_addr        : out EncodedAddress;                -- Adresse pour la mémoire de données
            mem_data_out    : out EncodedWord;                   -- Données pour la mémoire (écriture)
            mem_read        : out std_logic;                     -- Signal de lecture mémoire
            mem_write       : out std_logic;                     -- Signal d'écriture mémoire
            halted          : out std_logic;                     -- Signal indiquant que le CPU est arrêté
            debug_state     : out FsmStateType                   -- État courant de la FSM (pour debug)
        );
    end component;
    
    -- Signaux pour la simulation
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal instr_data : EncodedWord := (others => '0');
    signal mem_data_in : EncodedWord := (others => '0');
    signal instr_addr : EncodedAddress;
    signal mem_addr : EncodedAddress;
    signal mem_data_out : EncodedWord;
    signal mem_read : std_logic;
    signal mem_write : std_logic;
    signal halted : std_logic;
    signal debug_state : FsmStateType;
    
    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Mémoire d'instructions simulée
    type instr_memory_type is array (0 to 31) of EncodedWord;
    signal instr_memory : instr_memory_type := (others => (others => '0'));
    
    -- Mémoire de données simulée
    type data_memory_type is array (0 to 31) of EncodedWord;
    signal data_memory : data_memory_type := (others => (others => '0'));
    
    -- Banc de registres simulé pour vérification
    type reg_file_type is array (0 to 7) of EncodedWord;
    signal reg_file : reg_file_type := (others => (others => '0'));
    
    -- Signaux pour le suivi des instructions
    signal current_pc : integer := 0;
    signal next_pc : integer := 0;
    signal instr_count : integer := 0;
    
    -- Fonction pour créer une instruction JAL
    function create_jal(rd : integer; offset : integer) return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode JAL = "010000" (ZNN, -4)
        instr(47 downto 42) := OPCODE_JAL;
        
        -- Registre destination (rd) sur 3 bits
        instr(41 downto 39) := std_logic_vector(to_unsigned(rd, 3));
        
        -- Offset sur 10 trits (20 bits), simplifié pour le test
        -- Nous supposons que l'offset est déjà en nombre d'instructions (pas en octets)
        if offset < 0 then
            -- Encodage pour valeur négative (tous les trits à N pour simplifier)
            instr(39 downto 20) := (others => '0'); -- TRIT_N
        elsif offset > 0 then
            -- Encodage pour valeur positive (tous les trits à P pour simplifier)
            instr(39 downto 20) := (others => '1'); -- TRIT_P
            -- Mettre la valeur exacte de l'offset
            instr(23 downto 20) := std_logic_vector(to_unsigned(offset, 4));
        else
            -- Offset = 0, tous les trits à Z
            instr(39 downto 20) := (others => '0');
        end if;
        
        return instr;
    end function;
    
    -- Fonction pour créer une instruction JALR
    function create_jalr(rd : integer; rs1 : integer; imm : integer) return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode JALR = "010001" (ZNN, -3)
        instr(47 downto 42) := OPCODE_JALR;
        
        -- Registre destination (rd) sur 3 bits
        instr(41 downto 39) := std_logic_vector(to_unsigned(rd, 3));
        
        -- Registre source 1 (rs1) sur 3 bits
        instr(35 downto 33) := std_logic_vector(to_unsigned(rs1, 3));
        
        -- Immédiat sur 5 trits (10 bits), simplifié pour le test
        if imm < 0 then
            -- Encodage pour valeur négative
            instr(29 downto 20) := (others => '0'); -- TRIT_N
        elsif imm > 0 then
            -- Encodage pour valeur positive
            instr(29 downto 20) := (others => '1'); -- TRIT_P
            -- Mettre la valeur exacte de l'immédiat
            instr(23 downto 20) := std_logic_vector(to_unsigned(imm, 4));
        else
            -- Immédiat = 0, tous les trits à Z
            instr(29 downto 20) := (others => '0');
        end if;
        
        return instr;
    end function;
    
    -- Fonction pour créer une instruction CMP
    function create_cmp(rs1 : integer; rs2 : integer) return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode CMP = "100011" (PNN, -1)
        instr(47 downto 42) := OPCODE_CMP;
        
        -- Registre source 1 (rs1) sur 3 bits
        instr(35 downto 33) := std_logic_vector(to_unsigned(rs1, 3));
        
        -- Registre source 2 (rs2) sur 3 bits
        instr(29 downto 27) := std_logic_vector(to_unsigned(rs2, 3));
        
        return instr;
    end function;
    
    -- Fonction pour créer une instruction BRANCH
    function create_branch(cond : BranchCondType; offset : integer) return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode BRANCH = "010010" (ZNN, -2)
        instr(47 downto 42) := OPCODE_BRANCH;
        
        -- Condition de branchement sur 3 trits (6 bits)
        instr(35 downto 30) := cond;
        
        -- Offset sur 8 trits (16 bits), simplifié pour le test
        if offset < 0 then
            -- Encodage pour valeur négative
            instr(29 downto 14) := (others => '0'); -- TRIT_N
        elsif offset > 0 then
            -- Encodage pour valeur positive
            instr(29 downto 14) := (others => '1'); -- TRIT_P
            -- Mettre la valeur exacte de l'offset
            instr(17 downto 14) := std_logic_vector(to_unsigned(offset, 4));
        else
            -- Offset = 0, tous les trits à Z
            instr(29 downto 14) := (others => '0');
        end if;
        
        return instr;
    end function;
    
    -- Fonction pour créer une instruction ADDI
    function create_addi(rd : integer; rs1 : integer; imm : integer) return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode ADDI = "100000" (PNN, -4)
        instr(47 downto 42) := OPCODE_ADDI;
        
        -- Registre destination (rd) sur 3 bits
        instr(41 downto 39) := std_logic_vector(to_unsigned(rd, 3));
        
        -- Registre source 1 (rs1) sur 3 bits
        instr(35 downto 33) := std_logic_vector(to_unsigned(rs1, 3));
        
        -- Immédiat sur 5 trits (10 bits), simplifié pour le test
        if imm < 0 then
            -- Encodage pour valeur négative
            instr(29 downto 20) := (others => '0'); -- TRIT_N
            -- Mettre la valeur exacte de l'immédiat (complément à 2 pour simplifier)
            instr(23 downto 20) := std_logic_vector(to_unsigned(-imm, 4));
        elsif imm > 0 then
            -- Encodage pour valeur positive
            instr(29 downto 20) := (others => '1'); -- TRIT_P
            -- Mettre la valeur exacte de l'immédiat
            instr(23 downto 20) := std_logic_vector(to_unsigned(imm, 4));
        else
            -- Immédiat = 0, tous les trits à Z
            instr(29 downto 20) := (others => '0');
        end if;
        
        return instr;
    end function;
    
    -- Fonction pour créer une instruction HALT
    function create_halt return EncodedWord is
        variable instr : EncodedWord := (others => '0');
    begin
        -- Opcode HALT = "000000" (NNN, -13)
        instr(47 downto 42) := OPCODE_HALT;
        
        return instr;
    end function;
    
begin
    -- Instanciation du composant à tester
    uut: prismchrono_core
        port map (
            clk         => clk,
            rst         => rst,
            instr_data  => instr_data,
            mem_data_in => mem_data_in,
            instr_addr  => instr_addr,
            mem_addr    => mem_addr,
            mem_data_out=> mem_data_out,
            mem_read    => mem_read,
            mem_write   => mem_write,
            halted      => halted,
            debug_state => debug_state
        );
    
    -- Processus de génération d'horloge
    process
    begin
        wait for CLK_PERIOD/2;
        clk <= not clk;
    end process;
    
    -- Processus de simulation de la mémoire d'instructions
    process(clk)
    begin
        if rising_edge(clk) then
            -- Convertir l'adresse en index pour la mémoire simulée
            current_pc <= to_integer(unsigned(instr_addr));
            instr_data <= instr_memory(to_integer(unsigned(instr_addr)));
        end if;
    end process;
    
    -- Processus de simulation de la mémoire de données
    process(clk)
    begin
        if rising_edge(clk) then
            if mem_read = '1' then
                mem_data_in <= data_memory(to_integer(unsigned(mem_addr)));
            end if;
            if mem_write = '1' then
                data_memory(to_integer(unsigned(mem_addr))) <= mem_data_out;
            end if;
        end if;
    end process;
    
    -- Processus principal de test
    process
    begin
        -- Initialisation de la mémoire d'instructions avec le programme de test
        
        -- Test 1: JAL et JALR
        -- 0: JAL R1, +2 (saute à l'adresse 2)
        instr_memory(0) <= create_jal(1, 2);
        -- 1: HALT (ne devrait pas être exécuté)
        instr_memory(1) <= create_halt;
        -- 2: JALR R2, R1, 0 (retourne à l'adresse stockée dans R1, qui est PC+1=1)
        instr_memory(2) <= create_jalr(2, 1, 0);
        -- 3: JAL R0, +2 (saute à l'adresse 5, R0 n'est pas modifié)
        instr_memory(3) <= create_jal(0, 2);
        -- 4: HALT (ne devrait pas être exécuté)
        instr_memory(4) <= create_halt;
        
        -- Test 2: Branchements conditionnels
        -- 5: ADDI R3, R0, 5 (R3 = 5)
        instr_memory(5) <= create_addi(3, 0, 5);
        -- 6: ADDI R4, R0, 5 (R4 = 5)
        instr_memory(6) <= create_addi(4, 0, 5);
        -- 7: CMP R3, R4 (compare R3 et R4, devrait mettre ZF=1)
        instr_memory(7) <= create_cmp(3, 4);
        -- 8: BRANCH EQ, +1 (saute à l'adresse 9 si ZF=1, ce qui est le cas)
        instr_memory(8) <= create_branch(COND_EQ, 1);
        -- 9: ADDI R5, R0, 1 (R5 = 1)
        instr_memory(9) <= create_addi(5, 0, 1);
        -- 10: ADDI R4, R0, 6 (R4 = 6)
        instr_memory(10) <= create_addi(4, 0, 6);
        -- 11: CMP R3, R4 (compare R3 et R4, devrait mettre ZF=0, SF=1)
        instr_memory(11) <= create_cmp(3, 4);
        -- 12: BRANCH NE, +1 (saute à l'adresse 13 si ZF=0, ce qui est le cas)
        instr_memory(12) <= create_branch(COND_NE, 1);
        -- 13: ADDI R6, R0, 1 (R6 = 1)
        instr_memory(13) <= create_addi(6, 0, 1);
        -- 14: CMP R3, R4 (compare R3 et R4, devrait mettre ZF=0, SF=1)
        instr_memory(14) <= create_cmp(3, 4);
        -- 15: BRANCH LT, +1 (saute à l'adresse 16 si SF=1 & ZF=0, ce qui est le cas)
        instr_memory(15) <= create_branch(COND_LT, 1);
        -- 16: ADDI R7, R0, 1 (R7 = 1)
        instr_memory(16) <= create_addi(7, 0, 1);
        
        -- Test 3: Boucle simple
        -- 17: ADDI R1, R0, 3 (R1 = 3, compteur de boucle)
        instr_memory(17) <= create_addi(1, 0, 3);
        -- 18: ADDI R1, R1, -1 (R1 = R1 - 1)
        instr_memory(18) <= create_addi(1, 1, -1);
        -- 19: CMP R1, R0 (compare R1 et R0)
        instr_memory(19) <= create_cmp(1, 0);
        -- 20: BRANCH NE, -2 (retourne à l'adresse 18 si ZF=0)
        instr_memory(20) <= create_branch(COND_NE, -2);
        -- 21: HALT
        instr_memory(21) <= create_halt;
        
        -- Démarrage de la simulation
        wait for CLK_PERIOD;
        rst <= '0'; -- Désactivation du reset
        
        -- Attente de la fin de la simulation (HALT)
        wait until halted = '1';
        wait for CLK_PERIOD * 5;
        
        -- Vérification des résultats
        assert current_pc = 21 report "Test échoué: PC final incorrect" severity error;
        
        -- Fin de la simulation
        report "Simulation terminée avec succès!" severity note;
        wait;
    end process;
    
end architecture sim;