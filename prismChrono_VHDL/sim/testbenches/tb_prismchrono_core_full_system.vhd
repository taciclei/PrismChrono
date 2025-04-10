library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_prismchrono_core_full_system is
end entity tb_prismchrono_core_full_system;

architecture testbench of tb_prismchrono_core_full_system is
    -- Signaux pour le composant sous test
    signal clk              : std_logic := '0';
    signal rst              : std_logic := '0';
    signal instruction      : EncodedWord := (others => '0');
    signal pc              : EncodedAddress := (others => '0');
    signal mem_read_data   : EncodedWord := (others => '0');
    signal mem_write_data  : EncodedWord := (others => '0');
    signal mem_address     : EncodedAddress := (others => '0');
    signal mem_write_en    : std_logic := '0';
    signal mem_read_en     : std_logic := '0';
    signal current_privilege : std_logic_vector(1 downto 0) := PRIV_M;
    
    -- Période d'horloge
    constant CLK_PERIOD : time := 10 ns;
    
    -- Mémoire simulée (DDR)
    type memory_type is array (0 to 1023) of EncodedWord;
    signal memory : memory_type := (others => (others => '0'));
    
    -- Programme de test en mémoire (noyau M/S et application U)
    constant KERNEL_START : natural := 0;
    constant USER_APP_START : natural := 512;
    
    -- Procédure pour charger le code en mémoire
    procedure load_test_program is
    begin
        -- Code du noyau (M-mode)
        -- Configuration initiale des CSRs
        memory(0) := encode_trit_vector("PPPNNNZZZ"); -- Configure mstatus
        memory(1) := encode_trit_vector("PPPNNNZZZ"); -- Configure mtvec
        memory(2) := encode_trit_vector("PPPNNNZZZ"); -- Configure medeleg
        memory(3) := encode_trit_vector("PPPNNNZZZ"); -- Configure mideleg
        
        -- Transition vers S-mode
        memory(4) := encode_trit_vector("PPPNNNZZZ"); -- Configure sstatus
        memory(5) := encode_trit_vector("PPPNNNZZZ"); -- Configure stvec
        memory(6) := encode_trit_vector("PPPNNNZZZ"); -- MRET vers S-mode
        
        -- Code du superviseur (S-mode)
        memory(7) := encode_trit_vector("PPPNNNZZZ"); -- Configure satp
        memory(8) := encode_trit_vector("PPPNNNZZZ"); -- Configure protection mémoire
        memory(9) := encode_trit_vector("PPPNNNZZZ"); -- SRET vers U-mode
        
        -- Code de l'application (U-mode)
        memory(512) := encode_trit_vector("PPPNNNZZZ"); -- Test MUL
        memory(513) := encode_trit_vector("PPPNNNZZZ"); -- Test DIV
        memory(514) := encode_trit_vector("PPPNNNZZZ"); -- Test branchements
        memory(515) := encode_trit_vector("PPPNNNZZZ"); -- ECALL vers S-mode
    end procedure;
    
    -- Procédure pour vérifier les transitions de privilège
    procedure check_privilege_transition(
        expected_mode : std_logic_vector(1 downto 0);
        message : string
    ) is
    begin
        assert current_privilege = expected_mode
            report message
            severity error;
    end procedure;

begin
    -- Instanciation du composant sous test
    UUT: entity work.prismchrono_core
        port map (
            clk              => clk,
            rst              => rst,
            instruction      => instruction,
            pc               => pc,
            mem_read_data    => mem_read_data,
            mem_write_data   => mem_write_data,
            mem_address      => mem_address,
            mem_write_en     => mem_write_en,
            mem_read_en      => mem_read_en,
            current_privilege => current_privilege
        );
    
    -- Processus de génération d'horloge
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de simulation de la mémoire
    memory_process: process(clk)
    begin
        if rising_edge(clk) then
            if mem_read_en = '1' then
                mem_read_data <= memory(to_integer(unsigned(mem_address(9 downto 0))));
            end if;
            if mem_write_en = '1' then
                memory(to_integer(unsigned(mem_address(9 downto 0)))) <= mem_write_data;
            end if;
        end if;
    end process;
    
    -- Processus de test principal
    test_process: process
    begin
        -- Chargement du programme de test
        load_test_program;
        
        -- Reset initial
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        -- Vérification du mode initial (M-mode)
        check_privilege_transition(PRIV_M, "Le processeur devrait démarrer en M-mode");
        
        -- Attente de la transition vers S-mode
        wait until current_privilege = PRIV_S;
        check_privilege_transition(PRIV_S, "La transition vers S-mode a échoué");
        
        -- Attente de la transition vers U-mode
        wait until current_privilege = PRIV_U;
        check_privilege_transition(PRIV_U, "La transition vers U-mode a échoué");
        
        -- Attente de l'ECALL
        wait until current_privilege = PRIV_S;
        check_privilege_transition(PRIV_S, "Le retour en S-mode après ECALL a échoué");
        
        -- Fin des tests
        wait for CLK_PERIOD * 100;
        report "Tests système terminés";
        wait;
    end process;

end architecture testbench;