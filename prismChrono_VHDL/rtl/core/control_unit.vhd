library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity control_unit is
    port (
        clk             : in  std_logic;                     -- Horloge système
        rst             : in  std_logic;                     -- Reset asynchrone
        opcode          : in  OpcodeType;                    -- Opcode de l'instruction courante
        flags           : in  FlagBusType;                   -- Flags de l'ALU
        branch_cond     : in  BranchCondType;                -- Condition de branchement
        control_signals : out ControlSignalsType;            -- Signaux de contrôle pour le datapath
        current_state   : out FsmStateType                   -- État courant de la FSM (pour debug)
    );
end entity control_unit;

architecture rtl of control_unit is
    -- Signal pour l'état courant et le prochain état
    signal state_reg : FsmStateType := RESET;
    signal state_next : FsmStateType := RESET;
    
    -- Signal pour les signaux de contrôle
    signal ctrl_reg : ControlSignalsType := (
        pc_inc      => '0',
        pc_load     => '0',
        pc_src      => "00",
        alu_op      => OP_ADD,
        alu_src_a   => '0',
        alu_src_b   => '0',
        reg_write   => '0',
        reg_dst     => "00",
        reg_src     => "00",
        branch_cond => (others => '0'),
        branch_taken=> '0',
        mem_read    => '0',
        mem_write   => '0',
        csr_read    => '0',
        csr_write   => '0',
        csr_set     => '0',
        csr_clear   => '0',
        csr_addr    => (others => '0'),
        stall       => '0',
        flush       => '0',
        halted      => '0'
    );
    signal ctrl_next : ControlSignalsType := (
        pc_inc      => '0',
        pc_load     => '0',
        pc_src      => "00",
        alu_op      => OP_ADD,
        alu_src_a   => '0',
        alu_src_b   => '0',
        reg_write   => '0',
        reg_dst     => "00",
        reg_src     => "00",
        branch_cond => (others => '0'),
        branch_taken=> '0',
        mem_read    => '0',
        mem_write   => '0',
        csr_read    => '0',
        csr_write   => '0',
        csr_set     => '0',
        csr_clear   => '0',
        csr_addr    => (others => '0'),
        stall       => '0',
        flush       => '0',
        halted      => '0'
    );
    
    -- Signal pour l'évaluation des conditions de branchement
    signal branch_taken_internal : std_logic := '0';
    
begin
    
    -- Processus synchrone pour mettre à jour l'état et les signaux de contrôle
    process(clk, rst)
    begin
        if rst = '1' then
            -- Réinitialisation de l'état et des signaux de contrôle
            state_reg <= RESET;
            ctrl_reg <= (
                pc_inc      => '0',
                pc_load     => '0',
                pc_src      => "00",
                alu_op      => OP_ADD,
                alu_src_a   => '0',
                alu_src_b   => '0',
                reg_write   => '0',
                reg_dst     => "00",
                reg_src     => "00",
                branch_cond => (others => '0'),
                branch_taken=> '0',
                mem_read    => '0',
                mem_write   => '0',
                csr_read    => '0',
                csr_write   => '0',
                csr_set     => '0',
                csr_clear   => '0',
                csr_addr    => (others => '0'),
                stall       => '0',
                flush       => '0',
                halted      => '0'
            );
        elsif rising_edge(clk) then
            -- Mise à jour de l'état et des signaux de contrôle
            state_reg <= state_next;
            ctrl_reg <= ctrl_next;
        end if;
    end process;
    
    -- Processus combinatoire pour évaluer les conditions de branchement
    process(branch_cond, flags)
    begin
        -- Par défaut, le branchement n'est pas pris
        branch_taken_internal <= '0';
        
        -- Évaluation de la condition en fonction des flags
        case branch_cond is
            when COND_EQ =>
                -- Equal (Zero Flag = 1)
                if flags(FLAG_Z_IDX) = '1' then
                    branch_taken_internal <= '1';
                end if;
                
            when COND_NE =>
                -- Not Equal (Zero Flag = 0)
                if flags(FLAG_Z_IDX) = '0' then
                    branch_taken_internal <= '1';
                end if;
                
            when COND_LT =>
                -- Less Than (Sign Flag = 1 & Zero Flag = 0)
                if flags(FLAG_S_IDX) = '1' and flags(FLAG_Z_IDX) = '0' then
                    branch_taken_internal <= '1';
                end if;
                
            when COND_GE =>
                -- Greater or Equal (Sign Flag = 0 | Zero Flag = 1)
                if flags(FLAG_S_IDX) = '0' or flags(FLAG_Z_IDX) = '1' then
                    branch_taken_internal <= '1';
                end if;
                
            when COND_B =>
                -- Branch Always (Unconditional)
                branch_taken_internal <= '1';
                
            when others =>
                -- Condition non reconnue, branchement non pris
                branch_taken_internal <= '0';
        end case;
    end process;
    
    -- Processus combinatoire pour calculer le prochain état et les signaux de contrôle
    process(state_reg, opcode, flags, branch_cond)
    begin
        -- Par défaut, on maintient les valeurs précédentes
        state_next <= state_reg;
        ctrl_next <= ctrl_reg;
        
        -- Calcul du prochain état et des signaux de contrôle en fonction de l'état courant
        case state_reg is
            when RESET =>
                -- Réinitialisation des signaux de contrôle
                ctrl_next.pc_inc <= '0';
                ctrl_next.pc_load <= '0';
                ctrl_next.pc_src <= "00";
                ctrl_next.alu_op <= OP_ADD;
                ctrl_next.alu_src_a <= '0';
                ctrl_next.alu_src_b <= '0';
                ctrl_next.reg_write <= '0';
                ctrl_next.reg_dst <= "00";
                ctrl_next.reg_src <= "00";
                ctrl_next.branch_cond <= (others => '0');
                ctrl_next.branch_taken <= '0';
                ctrl_next.mem_read <= '0';
                ctrl_next.mem_write <= '0';
                ctrl_next.csr_read <= '0';
                ctrl_next.csr_write <= '0';
                ctrl_next.csr_set <= '0';
                ctrl_next.csr_clear <= '0';
                ctrl_next.csr_addr <= (others => '0');
                ctrl_next.stall <= '0';
                ctrl_next.flush <= '0';
                ctrl_next.halted <= '0';
                
                -- Passage à l'état FETCH
                state_next <= FETCH;
                
            when FETCH =>
                -- Incrémentation du PC
                ctrl_next.pc_inc <= '1';
                
                -- Passage à l'état DECODE
                state_next <= DECODE;
                
            when DECODE =>
                -- Décodage de l'opcode
                case opcode is
                    when OPCODE_NOP =>
                        state_next <= EXEC_NOP;
                        
                    when OPCODE_HALT =>
                        ctrl_next.halted <= '1';
                        state_next <= HALTED;
                        
                    when OPCODE_ADDI =>
                        state_next <= EXEC_ADDI;
                        
                    when OPCODE_ADD | OPCODE_SUB | OPCODE_TMIN | OPCODE_TMAX | OPCODE_TINV | OPCODE_CMP =>
                        state_next <= EXEC_ALU_R;
                        
                    when OPCODE_TMINI | OPCODE_TMAXI =>
                        state_next <= EXEC_ALU_I;
                        
                    when OPCODE_MUL =>
                        state_next <= EXEC_MUL_INIT;
                        
                    when OPCODE_DIV | OPCODE_MOD =>
                        state_next <= EXEC_DIV_INIT;
                        
                    when OPCODE_CSRRW_T | OPCODE_CSRRS_T | OPCODE_CSRRC_T =>
                        state_next <= EXEC_CSR;
                        
                    when OPCODE_JAL =>
                        state_next <= EXEC_JAL;
                        
                    when OPCODE_JALR =>
                        state_next <= EXEC_JALR;
                        
                    when OPCODE_BRANCH =>
                        state_next <= EXEC_BRANCH;
                        
                    when OPCODE_ECALL =>
                        -- Déclencher un trap pour ECALL
                        -- Sauvegarder PC dans mepc
                        ctrl_next.csr_write <= '1';
                        ctrl_next.csr_addr <= CSR_MEPC_ADDR;
                        -- Définir la cause dans mcause
                        -- Note: Dans une implémentation complète, il faudrait déterminer
                        -- le mode de privilège actuel (U/S/M) pour choisir la bonne cause
                        ctrl_next.csr_write <= '1';
                        ctrl_next.csr_addr <= CSR_MCAUSE_ADDR;
                        -- Pour simplifier, on utilise toujours ECALL_M
                        -- Sauter vers le gestionnaire de trap via mtvec
                        ctrl_next.pc_load <= '1';
                        ctrl_next.pc_src <= "10"; -- Charger depuis mtvec
                        state_next <= FETCH;
                        
                    when OPCODE_EBREAK =>
                        -- Déclencher un trap pour EBREAK
                        -- Sauvegarder PC dans mepc
                        ctrl_next.csr_write <= '1';
                        ctrl_next.csr_addr <= CSR_MEPC_ADDR;
                        -- Définir la cause dans mcause comme BREAKPOINT
                        ctrl_next.csr_write <= '1';
                        ctrl_next.csr_addr <= CSR_MCAUSE_ADDR;
                        -- Sauter vers le gestionnaire de trap via mtvec
                        ctrl_next.pc_load <= '1';
                        ctrl_next.pc_src <= "10"; -- Charger depuis mtvec
                        state_next <= FETCH;
                        
                    when others =>
                        -- Instruction non reconnue, on reste dans l'état DECODE
                        state_next <= DECODE;
                end case;
                
            when EXEC_NOP =>
                -- Après l'exécution de NOP, on revient à FETCH
                state_next <= FETCH;
                
            when EXEC_ADDI =>
                -- Après l'exécution de ADDI, on passe à l'état de write-back
                state_next <= WB_ADDI;
                
            when EXEC_ALU_R =>
                -- Après l'exécution d'une instruction ALU format R, on passe à l'état de write-back
                state_next <= WB_REG;
                
            when EXEC_ALU_I =>
                -- Après l'exécution d'une instruction ALU format I, on passe à l'état de write-back
                state_next <= WB_REG;
                
            when EXEC_CSR =>
                -- Après l'exécution d'une instruction CSR, on passe à l'état de write-back
                state_next <= WB_CSR;
                
            when EXEC_JAL =>
                -- Après l'exécution de JAL, on passe à l'état de write-back
                state_next <= WB_JAL;
                
            when EXEC_JALR =>
                -- Après l'exécution de JALR, on passe à l'état de write-back
                state_next <= WB_JALR;
                
            when EXEC_BRANCH =>
                -- Après l'exécution de BRANCH, on revient directement à FETCH
                state_next <= FETCH;
                
            when WB_ADDI =>
                -- Après le write-back, on revient à FETCH
                state_next <= FETCH;
                
            when WB_REG =>
                -- Après le write-back, on revient à FETCH
                state_next <= FETCH;
                
            when WB_CSR =>
                -- Après le write-back, on revient à FETCH
                state_next <= FETCH;
                
            when WB_JAL =>
                -- Après le write-back, on revient à FETCH
                state_next <= FETCH;
                
            when WB_JALR =>
                -- Après le write-back, on revient à FETCH
                state_next <= FETCH;
                
            when MEM_READ =>
                -- Attente de la mémoire
                state_next <= MEM_WAIT;
                
            when MEM_WRITE =>
                -- Attente de la mémoire
                state_next <= MEM_WAIT;
                
            when MEM_WAIT =>
                -- Après l'accès mémoire, on revient à FETCH
                state_next <= FETCH;
                
            when HALTED =>
                -- On reste dans l'état HALTED jusqu'à un reset
                state_next <= HALTED;
                
            when others =>
                -- Pour les états non reconnus, on revient à FETCH
                state_next <= FETCH;
        end case;
    
    -- Processus combinatoire pour générer les signaux de contrôle
    process(state_reg, opcode, branch_taken_internal)
    begin
        -- Par défaut, tous les signaux de contrôle sont désactivés
        ctrl_next <= (
            pc_inc      => '0',
            pc_load     => '0',
            pc_src      => "00",
            alu_op      => OP_ADD,
            alu_src_a   => '0',
            alu_src_b   => '0',
            reg_write   => '0',
            reg_dst     => "00",
            reg_src     => "00",
            branch_cond => (others => '0'),
            branch_taken=> '0',
            mem_read    => '0',
            mem_write   => '0',
            csr_read    => '0',
            csr_write   => '0',
            csr_set     => '0',
            csr_clear   => '0',
            csr_addr    => (others => '0'),
            stall       => '0',
            flush       => '0',
            halted      => '0'
        );
        
        -- Génération des signaux de contrôle en fonction de l'état courant
        case state_reg is
            when RESET =>
                -- Aucun signal de contrôle actif pendant le reset
                null;
                
            when FETCH =>
                -- Pendant FETCH, on active la lecture mémoire pour récupérer l'instruction
                ctrl_next.mem_read <= '1';
                
            when DECODE =>
                -- Pendant DECODE, aucun signal de contrôle spécifique
                null;
                
            when EXEC_NOP =>
                -- Pour NOP, on incrémente simplement le PC
                ctrl_next.pc_inc <= '1';
                
            when EXEC_ADDI =>
                -- Pour ADDI, on configure l'ALU pour l'addition avec un immédiat
                ctrl_next.alu_op <= OP_ADD;
                ctrl_next.alu_src_a <= '0'; -- Source A = rs1
                ctrl_next.alu_src_b <= '1'; -- Source B = immédiat
                
            when EXEC_JAL =>
                -- Pour JAL, on prépare le chargement du PC avec l'adresse cible
                ctrl_next.pc_load <= '1';
                ctrl_next.pc_src <= "10"; -- Source = adresse cible JAL
                
            when EXEC_JALR =>
                -- Pour JALR, on prépare le chargement du PC avec l'adresse cible
                ctrl_next.pc_load <= '1';
                ctrl_next.pc_src <= "01"; -- Source = adresse cible JALR
                
            when EXEC_BRANCH =>
                -- Pour BRANCH, on évalue la condition et on charge le PC si nécessaire
                ctrl_next.branch_taken <= branch_taken_internal;
                if branch_taken_internal = '1' then
                    ctrl_next.pc_load <= '1';
                    ctrl_next.pc_src <= "11"; -- Source = adresse cible BRANCH
                else
                    ctrl_next.pc_inc <= '1'; -- Incrémentation normale du PC
                end if;
                
            when WB_ADDI =>
                -- Pour le write-back de ADDI, on active l'écriture dans le registre destination
                -- et on incrémente le PC
                ctrl_next.reg_write <= '1';
                ctrl_next.reg_dst <= "00"; -- Destination = rd
                ctrl_next.reg_src <= "00"; -- Source = ALU
                ctrl_next.pc_inc <= '1';
                
            when WB_JAL =>
                -- Pour le write-back de JAL, on écrit PC+1 dans le registre destination
                ctrl_next.reg_write <= '1';
                ctrl_next.reg_dst <= "00"; -- Destination = rd
                ctrl_next.reg_src <= "10"; -- Source = PC+1
                
            when WB_JALR =>
                -- Pour le write-back de JALR, on écrit PC+1 dans le registre destination
                ctrl_next.reg_write <= '1';
                ctrl_next.reg_dst <= "00"; -- Destination = rd
                ctrl_next.reg_src <= "10"; -- Source = PC+1
                
            when HALTED =>
                -- Dans l'état HALTED, on active le signal halted
                ctrl_next.halted <= '1';
                
            when others =>
                -- Pour les états non reconnus, aucun signal de contrôle spécifique
                null;
        end case;
    end process;
    
    -- Assignation des sorties
    control_signals <= ctrl_reg;
    current_state <= state_reg;
    
end architecture rtl;

-- Processus de décodage des instructions
process(instruction)
begin
    -- Initialisation par défaut
    ctrl_next <= CTRL_SIGNALS_INIT;
    
    -- Décodage basé sur l'opcode
    case instruction(6 downto 0) is
        when OPCODE_TERNARY_SPEC =>
            -- Instructions spécialisées ternaires
            case instruction(14 downto 12) is  -- funct3
                when FUNCT3_TCMP3 =>
                    if instruction(31 downto 25) = FUNCT7_TERNARY_SPEC then
                        ctrl_next.alu_op <= OP_TCMP3;
                        ctrl_next.reg_write <= '1';
                        state_next <= EXEC_ALU_R;
                    end if;
                    
                when FUNCT3_ABS_T =>
                    if instruction(31 downto 25) = FUNCT7_TERNARY_SPEC then
                        ctrl_next.alu_op <= OP_ABS_T;
                        ctrl_next.reg_write <= '1';
                        state_next <= EXEC_ALU_R;
                    end if;
                    
                when FUNCT3_SIGNUM_T =>
                    if instruction(31 downto 25) = FUNCT7_TERNARY_SPEC then
                        ctrl_next.alu_op <= OP_SIGNUM_T;
                        ctrl_next.reg_write <= '1';
                        state_next <= EXEC_ALU_R;
                    end if;
                    
                when FUNCT3_EXTRACT_TRYTE =>
                    if instruction(31 downto 25) = FUNCT7_TERNARY_SPEC then
                        ctrl_next.alu_op <= OP_EXTRACT_TRYTE;
                        ctrl_next.reg_write <= '1';
                        state_next <= EXEC_ALU_R;
                    end if;
                    
                when FUNCT3_INSERT_TRYTE =>
                    if instruction(31 downto 25) = FUNCT7_TERNARY_SPEC then
                        ctrl_next.alu_op <= OP_INSERT_TRYTE;
                        ctrl_next.reg_write <= '1';
                        state_next <= EXEC_ALU_R;
                    end if;
                    
                when others =>
                    -- Instructions non reconnues
                    null;
            end case;
            
        when others =>
            -- Instructions non reconnues
            null;
    end case;
end process;