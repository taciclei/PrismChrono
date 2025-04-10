library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity pipelined_core is
    port (
        -- Signaux globaux
        clk              : in  std_logic;
        rst              : in  std_logic;
        
        -- Interface mémoire instructions
        instruction      : in  EncodedWord;
        pc               : out EncodedAddress;
        
        -- Interface mémoire données
        mem_read_data    : in  EncodedWord;
        mem_write_data   : out EncodedWord;
        mem_address      : out EncodedAddress;
        mem_write_en     : out std_logic;
        mem_read_en      : out std_logic;
        
        -- Signaux debug pipeline
        if_id_valid      : out std_logic;
        id_ex_valid      : out std_logic;
        ex_mem_valid     : out std_logic;
        mem_wb_valid     : out std_logic;
        forward_ex_ex    : out std_logic;
        forward_mem_ex   : out std_logic;
        forward_wb_ex    : out std_logic;
        stall_pipeline   : out std_logic;
        flush_pipeline   : out std_logic
    );
end entity pipelined_core;

architecture rtl of pipelined_core is
    -- Types pour les registres pipeline
    type if_id_reg_type is record
        pc          : EncodedAddress;
        instruction : EncodedWord;
        valid       : std_logic;
    end record;
    
    type id_ex_reg_type is record
        pc          : EncodedAddress;
        rs1_data    : EncodedWord;
        rs2_data    : EncodedWord;
        rd          : std_logic_vector(4 downto 0);
        imm         : EncodedWord;
        alu_op      : std_logic_vector(3 downto 0);
        mem_read    : std_logic;
        mem_write   : std_logic;
        reg_write   : std_logic;
        is_mul_div  : std_logic;  -- Indique une opération de multiplication/division
        mul_div_op  : std_logic_vector(1 downto 0);  -- Type d'opération (mul, div, rem)
        valid       : std_logic;
    end record;
    
    type ex_mem_reg_type is record
        alu_result  : EncodedWord;
        write_data  : EncodedWord;
        rd          : std_logic_vector(4 downto 0);
        mem_read    : std_logic;
        mem_write   : std_logic;
        reg_write   : std_logic;
        valid       : std_logic;
    end record;
    
    type mem_wb_reg_type is record
        alu_result  : EncodedWord;
        mem_data    : EncodedWord;
        rd          : std_logic_vector(4 downto 0);
        reg_write   : std_logic;
        valid       : std_logic;
    end record;
    
    -- Registres pipeline
    signal if_id_reg  : if_id_reg_type;
    signal id_ex_reg  : id_ex_reg_type;
    signal ex_mem_reg : ex_mem_reg_type;
    signal mem_wb_reg : mem_wb_reg_type;
    
    -- Signaux de contrôle pipeline
    signal stall_if   : std_logic;
    signal stall_id   : std_logic;
    signal flush_if   : std_logic;
    signal flush_id   : std_logic;
    
    -- Signaux forwarding
    signal forward_a  : std_logic_vector(1 downto 0);
    signal forward_b  : std_logic_vector(1 downto 0);
    signal forward_mul_div_a : std_logic_vector(1 downto 0);
    signal forward_mul_div_b : std_logic_vector(1 downto 0);
    
    -- Compteurs de performance
    signal total_cycles : unsigned(31 downto 0);
    signal stall_cycles : unsigned(31 downto 0);
    signal mul_div_stall_cycles : unsigned(31 downto 0);
    signal branch_mispredictions : unsigned(31 downto 0);
    signal data_hazards : unsigned(31 downto 0);
    signal forwarding_events : unsigned(31 downto 0);
    
    -- Signaux pour les opérations multi-cycles
    signal mul_div_busy : std_logic;
    signal mul_div_done : std_logic;
    signal mul_div_result : EncodedWord;
    
    -- Signaux pour la détection des aléas
    signal rs1_addr   : std_logic_vector(4 downto 0);
    signal rs2_addr   : std_logic_vector(4 downto 0);
    signal load_use_hazard : std_logic;
    signal branch_hazard   : std_logic;
    
    -- Banc de registres
    type register_file_type is array(0 to 31) of EncodedWord;
    signal reg_file : register_file_type := (others => (others => '0'));
    
    -- PC et contrôle
    signal pc_reg     : EncodedAddress := (others => '0');
    signal pc_next    : EncodedAddress;
    signal branch_taken : std_logic;
    
    -- Composant unité de forwarding
    component forwarding_unit is
        port (
            -- Registres sources étage EX
            id_ex_rs1     : in  std_logic_vector(4 downto 0);
            id_ex_rs2     : in  std_logic_vector(4 downto 0);
            
            -- Registre destination étages MEM et WB
            ex_mem_rd     : in  std_logic_vector(4 downto 0);
            mem_wb_rd     : in  std_logic_vector(4 downto 0);
            ex_mem_regwrite : in  std_logic;
            mem_wb_regwrite : in  std_logic;
            
            -- Signaux de forwarding
            forward_a     : out std_logic_vector(1 downto 0);
            forward_b     : out std_logic_vector(1 downto 0)
        );
    end component;
    
    -- Composant unité de détection des aléas
    component hazard_detection_unit is
        port (
            -- Registres sources étage ID
            if_id_rs1     : in  std_logic_vector(4 downto 0);
            if_id_rs2     : in  std_logic_vector(4 downto 0);
            
            -- Registre destination étage EX
            id_ex_rd      : in  std_logic_vector(4 downto 0);
            id_ex_memread : in  std_logic;
            
            -- Contrôle branchement
            branch_taken  : in  std_logic;
            
            -- Signaux de contrôle pipeline
            load_use_hazard : out std_logic;
            branch_hazard   : out std_logic
        );
    end component;
    signal branch_target : EncodedAddress;
    signal branch_taken  : std_logic;
    
begin
    -- Étage IF (Instruction Fetch)
    if_stage: process(clk, rst)
    begin
        if rst = '1' then
            pc_reg <= (others => '0');
            if_id_reg.valid <= '0';
        elsif rising_edge(clk) then
            if stall_if = '0' then
                if branch_taken = '1' then
                    pc_reg <= branch_target;
                else
                    pc_reg <= std_logic_vector(unsigned(pc_reg) + 4);
                end if;
            end if;
            
            if flush_if = '1' then
                if_id_reg.valid <= '0';
            elsif stall_if = '0' then
                if_id_reg.pc <= pc_reg;
                if_id_reg.instruction <= instruction;
                if_id_reg.valid <= '1';
            end if;
        end if;
    end process;
    
    -- Étage ID (Instruction Decode)
    id_stage: process(clk, rst)
        variable rs1_addr : integer;
        variable rs2_addr : integer;
        variable rd_addr  : integer;
    begin
        if rst = '1' then
            id_ex_reg.valid <= '0';
        elsif rising_edge(clk) then
            if flush_id = '1' then
                id_ex_reg.valid <= '0';
            elsif stall_id = '0' then
                -- Décodage des adresses registres
                rs1_addr := to_integer(unsigned(if_id_reg.instruction(19 downto 15)));
                rs2_addr := to_integer(unsigned(if_id_reg.instruction(24 downto 20)));
                rd_addr  := to_integer(unsigned(if_id_reg.instruction(11 downto 7)));
                
                -- Lecture des registres
                id_ex_reg.rs1_data <= reg_file(rs1_addr);
                id_ex_reg.rs2_data <= reg_file(rs2_addr);
                id_ex_reg.rd <= if_id_reg.instruction(11 downto 7);
                
                -- Extension de l'immédiat et contrôle
                -- À implémenter selon le format d'instruction
                
                id_ex_reg.valid <= if_id_reg.valid;
            end if;
        end if;
    end process;
    
    -- Étage EX (Execute)
    ex_stage: process(clk, rst)
        variable alu_in_a : EncodedWord;
        variable alu_in_b : EncodedWord;
        variable mul_div_in_a : EncodedWord;
        variable mul_div_in_b : EncodedWord;
    begin
        if rst = '1' then
            ex_mem_reg.valid <= '0';
            mul_div_busy <= '0';
            mul_div_done <= '0';
        elsif rising_edge(clk) then
            -- Sélection des entrées ALU avec forwarding
            case forward_a is
                when "00" => alu_in_a := id_ex_reg.rs1_data;
                when "01" => alu_in_a := ex_mem_reg.alu_result;
                when "10" => alu_in_a := mem_wb_reg.alu_result;
                when others => alu_in_a := (others => '0');
            end case;
            
            case forward_b is
                when "00" => alu_in_b := id_ex_reg.rs2_data;
                when "01" => alu_in_b := ex_mem_reg.alu_result;
                when "10" => alu_in_b := mem_wb_reg.alu_result;
                when others => alu_in_b := (others => '0');
            end case;
            
            -- Sélection des entrées MUL/DIV avec forwarding
            case forward_mul_div_a is
                when "00" => mul_div_in_a := id_ex_reg.rs1_data;
                when "01" => mul_div_in_a := ex_mem_reg.alu_result;
                when "10" => mul_div_in_a := mem_wb_reg.alu_result;
                when others => mul_div_in_a := (others => '0');
            end case;
            
            case forward_mul_div_b is
                when "00" => mul_div_in_b := id_ex_reg.rs2_data;
                when "01" => mul_div_in_b := ex_mem_reg.alu_result;
                when "10" => mul_div_in_b := mem_wb_reg.alu_result;
                when others => mul_div_in_b := (others => '0');
            end case;
            
            -- Gestion des opérations MUL/DIV
            if id_ex_reg.is_mul_div = '1' and mul_div_busy = '0' then
                mul_div_busy <= '1';
                -- Démarrage de l'opération MUL/DIV
                case id_ex_reg.mul_div_op is
                    when "00" => -- MUL
                        mul_div_result <= std_logic_vector(signed(mul_div_in_a) * signed(mul_div_in_b));
                        mul_div_done <= '1';
                    when "01" => -- DIV
                        if signed(mul_div_in_b) /= 0 then
                            mul_div_result <= std_logic_vector(signed(mul_div_in_a) / signed(mul_div_in_b));
                        else
                            mul_div_result <= (others => '1'); -- Division par zéro
                        end if;
                        mul_div_done <= '1';
                    when "10" => -- REM
                        if signed(mul_div_in_b) /= 0 then
                            mul_div_result <= std_logic_vector(signed(mul_div_in_a) rem signed(mul_div_in_b));
                        else
                            mul_div_result <= mul_div_in_a; -- Reste de division par zéro
                        end if;
                        mul_div_done <= '1';
                    when others =>
                        mul_div_result <= (others => '0');
                        mul_div_done <= '1';
                end case;
            elsif mul_div_done = '1' then
                mul_div_busy <= '0';
                mul_div_done <= '0';
                ex_mem_reg.alu_result <= mul_div_result;
            else
                -- Exécution ALU standard
                -- À implémenter selon les opérations supportées
            end if;
            
            if not (mul_div_busy = '1' and mul_div_done = '0') then
                ex_mem_reg.valid <= id_ex_reg.valid;
            end if;
        end if;
    end process;
    
    -- Étage MEM (Memory Access)
    mem_stage: process(clk, rst)
    begin
        if rst = '1' then
            mem_wb_reg.valid <= '0';
        elsif rising_edge(clk) then
            mem_wb_reg.alu_result <= ex_mem_reg.alu_result;
            mem_wb_reg.mem_data <= mem_read_data;
            mem_wb_reg.rd <= ex_mem_reg.rd;
            mem_wb_reg.reg_write <= ex_mem_reg.reg_write;
            mem_wb_reg.valid <= ex_mem_reg.valid;
        end if;
    end process;
    
    -- Processus de mise à jour des compteurs de performance
    performance_counters: process(clk, rst)
    begin
        if rst = '1' then
            total_cycles <= (others => '0');
            stall_cycles <= (others => '0');
            mul_div_stall_cycles <= (others => '0');
            branch_mispredictions <= (others => '0');
            data_hazards <= (others => '0');
            forwarding_events <= (others => '0');
        elsif rising_edge(clk) then
            -- Incrémentation du compteur de cycles total
            total_cycles <= total_cycles + 1;
            
            -- Comptage des cycles de stall
            if stall_if = '1' or stall_id = '1' then
                stall_cycles <= stall_cycles + 1;
            end if;
            
            -- Comptage des stalls dus aux opérations MUL/DIV
            if mul_div_busy = '1' then
                mul_div_stall_cycles <= mul_div_stall_cycles + 1;
            end if;
            
            -- Comptage des aléas de données
            if load_use_hazard = '1' then
                data_hazards <= data_hazards + 1;
            end if;
            
            -- Comptage des événements de forwarding
            if forward_a /= "00" or forward_b /= "00" or
               forward_mul_div_a /= "00" or forward_mul_div_b /= "00" then
                forwarding_events <= forwarding_events + 1;
            end if;
            
            -- Comptage des mauvaises prédictions de branchement
            if branch_hazard = '1' then
                branch_mispredictions <= branch_mispredictions + 1;
            end if;
        end if;
    end process;

    -- Étage WB (Write Back)
    wb_stage: process(clk)
        variable wb_data : EncodedWord;
        variable rd_addr : integer;
    begin
        if rising_edge(clk) then
            if mem_wb_reg.valid = '1' and mem_wb_reg.reg_write = '1' then
                rd_addr := to_integer(unsigned(mem_wb_reg.rd));
                if rd_addr /= 0 then  -- R0 toujours 0
                    reg_file(rd_addr) <= mem_wb_reg.alu_result;
                end if;
            end if;
        end if;
    end process;
    
    -- Instanciation de l'unité de forwarding
    forwarding_unit_inst : forwarding_unit
    port map (
        id_ex_rs1      => id_ex_reg.rs1,
        id_ex_rs2      => id_ex_reg.rs2,
        ex_mem_rd      => ex_mem_reg.rd,
        mem_wb_rd      => mem_wb_reg.rd,
        ex_mem_regwrite => ex_mem_reg.reg_write,
        mem_wb_regwrite => mem_wb_reg.reg_write,
        forward_a      => forward_a,
        forward_b      => forward_b
    );
    
    -- Instanciation de l'unité de détection des aléas
    hazard_detection_inst : hazard_detection_unit
    port map (
        if_id_rs1      => if_id_reg.instruction(19 downto 15),
        if_id_rs2      => if_id_reg.instruction(24 downto 20),
        id_ex_rd       => id_ex_reg.rd,
        id_ex_memread  => id_ex_reg.mem_read,
        branch_taken   => branch_taken,
        load_use_hazard => load_use_hazard,
        branch_hazard  => branch_hazard
    );
    
    -- Logique de contrôle du pipeline
    pipeline_control: process(all)
    begin
        -- Détection avancée des dépendances pour MUL/DIV
        -- Vérifie si une opération MUL/DIV a besoin d'un résultat qui n'est pas encore disponible
        signal mul_div_data_hazard : std_logic;
        mul_div_data_hazard <= '0';
        
        if id_ex_reg.is_mul_div = '1' then
            -- Vérifie les dépendances avec l'étage EX/MEM
            if ex_mem_reg.valid = '1' and ex_mem_reg.reg_write = '1' and 
               ex_mem_reg.rd /= "00000" and 
               (ex_mem_reg.rd = id_ex_reg.rs1 or ex_mem_reg.rd = id_ex_reg.rs2) then
                mul_div_data_hazard <= '1';
            -- Vérifie les dépendances avec l'étage MEM/WB
            elsif mem_wb_reg.valid = '1' and mem_wb_reg.reg_write = '1' and 
                  mem_wb_reg.rd /= "00000" and 
                  (mem_wb_reg.rd = id_ex_reg.rs1 or mem_wb_reg.rd = id_ex_reg.rs2) then
                mul_div_data_hazard <= '1';
            end if;
        end if;
        
        -- Gestion optimisée des stalls
        stall_if <= load_use_hazard or 
                   (mul_div_busy and not mul_div_done) or
                   (id_ex_reg.is_mul_div and mul_div_data_hazard);
        
        stall_id <= load_use_hazard or 
                   (mul_div_busy and not mul_div_done) or
                   (id_ex_reg.is_mul_div and mul_div_data_hazard);
        
        -- Gestion des flush avec priorité
        flush_if <= branch_hazard or
                   (id_ex_reg.is_mul_div and mul_div_done and not mul_div_data_hazard);
        flush_id <= branch_hazard or 
                   load_use_hazard or
                   (id_ex_reg.is_mul_div and mul_div_done and not mul_div_data_hazard);
        
        -- Forwarding optimisé pour les opérations mul/div
        if id_ex_reg.is_mul_div = '1' and not mul_div_data_hazard then
            -- Forwarding depuis EX/MEM avec priorité
            if ex_mem_reg.valid = '1' and ex_mem_reg.reg_write = '1' and 
               ex_mem_reg.rd /= "00000" then
                if ex_mem_reg.rd = id_ex_reg.rs1 then
                    forward_mul_div_a <= "01";
                end if;
                if ex_mem_reg.rd = id_ex_reg.rs2 then
                    forward_mul_div_b <= "01";
                end if;
            end if;
            
            -- Forwarding depuis MEM/WB si pas déjà fait depuis EX/MEM
            if mem_wb_reg.valid = '1' and mem_wb_reg.reg_write = '1' and 
               mem_wb_reg.rd /= "00000" then
                if mem_wb_reg.rd = id_ex_reg.rs1 and forward_mul_div_a = "00" then
                    forward_mul_div_a <= "10";
                end if;
                if mem_wb_reg.rd = id_ex_reg.rs2 and forward_mul_div_b = "00" then
                    forward_mul_div_b <= "10";
                end if;
            end if;
        else
            forward_mul_div_a <= "00";
            forward_mul_div_b <= "00";
        end if;
    end process;
    
    -- Sorties
    pc <= pc_reg;
    mem_address <= ex_mem_reg.alu_result;
    mem_write_data <= ex_mem_reg.write_data;
    mem_write_en <= ex_mem_reg.mem_write;
    mem_read_en <= ex_mem_reg.mem_read;
    
    -- Signaux debug
    if_id_valid <= if_id_reg.valid;
    id_ex_valid <= id_ex_reg.valid;
    ex_mem_valid <= ex_mem_reg.valid;
    mem_wb_valid <= mem_wb_reg.valid;
    forward_ex_ex <= forward_a(0);
    forward_mem_ex <= forward_a(1);
    forward_wb_ex <= forward_b(1);
    stall_pipeline <= stall_if;
    flush_pipeline <= flush_if;
    
end architecture rtl;