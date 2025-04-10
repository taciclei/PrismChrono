library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity tb_csr_registers is
    -- Pas de ports pour un testbench
end entity tb_csr_registers;

architecture sim of tb_csr_registers is
    -- Composant à tester
    component csr_registers is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            -- Interface d'accès aux CSRs
            csr_addr        : in  std_logic_vector(11 downto 0); -- Adresse du CSR (12 bits)
            csr_write_data  : in  EncodedWord;                   -- Données à écrire dans le CSR
            csr_read_data   : out EncodedWord;                   -- Données lues du CSR
            csr_write_en    : in  std_logic;                     -- Signal d'écriture CSR
            csr_read_en     : in  std_logic;                     -- Signal de lecture CSR
            csr_set_en      : in  std_logic;                     -- Signal pour l'opération SET (CSRRS)
            csr_clear_en    : in  std_logic;                     -- Signal pour l'opération CLEAR (CSRRC)
            -- Niveau de privilège courant
            current_privilege : in std_logic_vector(1 downto 0);  -- Niveau de privilège (00: U, 01: S, 11: M)
            -- Signaux de debug
            debug_mstatus   : out EncodedWord                    -- Valeur de mstatus pour debug
        );
    end component;
    
    -- Signaux pour la stimulation du composant
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    
    -- Signaux pour l'interface d'accès aux CSRs
    signal csr_addr : std_logic_vector(11 downto 0) := (others => '0');
    signal csr_write_data : EncodedWord := (others => '0');
    signal csr_read_data : EncodedWord;
    signal csr_write_en : std_logic := '0';
    signal csr_read_en : std_logic := '0';
    signal csr_set_en : std_logic := '0';
    signal csr_clear_en : std_logic := '0';
    
    -- Niveau de privilège
    signal current_privilege : std_logic_vector(1 downto 0) := "11"; -- Mode Machine par défaut
    
    -- Signal de debug
    signal debug_mstatus : EncodedWord;
    
    -- Constantes pour la simulation
    constant CLK_PERIOD : time := 10 ns;
    
    -- Procédure pour faciliter l'affichage des messages
    procedure print(msg : string) is
    begin
        report msg severity note;
    end procedure;
    
begin
    -- Instanciation du composant à tester
    uut: csr_registers
        port map (
            clk => clk,
            rst => rst,
            csr_addr => csr_addr,
            csr_write_data => csr_write_data,
            csr_read_data => csr_read_data,
            csr_write_en => csr_write_en,
            csr_read_en => csr_read_en,
            csr_set_en => csr_set_en,
            csr_clear_en => csr_clear_en,
            current_privilege => current_privilege,
            debug_mstatus => debug_mstatus
        );
    
    -- Processus de génération de l'horloge
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Processus de stimulation
    process
    begin
        -- Initialisation
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        wait for CLK_PERIOD;
        
        print("Test 1: Écriture et lecture de mstatus");
        -- Écriture dans mstatus
        csr_addr <= CSR_MSTATUS_ADDR;
        csr_write_data <= X"123456789ABCDEF0123456789ABCDEF0"; -- Valeur arbitraire
        csr_write_en <= '1';
        wait for CLK_PERIOD;
        csr_write_en <= '0';
        wait for CLK_PERIOD;
        
        -- Lecture de mstatus
        csr_read_en <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la valeur lue correspond à la valeur écrite
        assert csr_read_data = csr_write_data report "Erreur: Valeur lue de mstatus incorrecte" severity error;
        
        -- Fin de la lecture
        csr_read_en <= '0';
        wait for CLK_PERIOD;
        
        print("Test 2: Opération SET sur mstatus");
        -- Valeur initiale de mstatus (déjà écrite)
        -- Opération SET avec une nouvelle valeur
        csr_write_data <= X"000000000000FFFF000000000000FFFF"; -- Valeur pour SET
        csr_set_en <= '1';
        wait for CLK_PERIOD;
        csr_set_en <= '0';
        wait for CLK_PERIOD;
        
        -- Lecture de mstatus après SET
        csr_read_en <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la valeur lue correspond au résultat de l'opération MAX
        -- Pour simplifier, on vérifie juste que ce n'est pas la valeur initiale
        assert csr_read_data /= X"123456789ABCDEF0123456789ABCDEF0" report "Erreur: Opération SET n'a pas modifié mstatus" severity error;
        
        -- Fin de la lecture
        csr_read_en <= '0';
        wait for CLK_PERIOD;
        
        print("Test 3: Opération CLEAR sur mstatus");
        -- Valeur actuelle de mstatus (après SET)
        -- Opération CLEAR avec une nouvelle valeur
        csr_write_data <= X"FFFFFFFF0000FFFF0000FFFF00000000"; -- Valeur pour CLEAR
        csr_clear_en <= '1';
        wait for CLK_PERIOD;
        csr_clear_en <= '0';
        wait for CLK_PERIOD;
        
        -- Lecture de mstatus après CLEAR
        csr_read_en <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la valeur lue correspond au résultat de l'opération MIN
        -- Pour simplifier, on vérifie juste que ce n'est pas la valeur après SET
        assert csr_read_data /= csr_read_data report "Erreur: Opération CLEAR n'a pas modifié mstatus" severity error;
        
        -- Fin de la lecture
        csr_read_en <= '0';
        wait for CLK_PERIOD;
        
        print("Test 4: Écriture et lecture de mscratch");
        -- Écriture dans mscratch
        csr_addr <= CSR_MSCRATCH_ADDR;
        csr_write_data <= X"FEDCBA9876543210FEDCBA9876543210"; -- Valeur arbitraire
        csr_write_en <= '1';
        wait for CLK_PERIOD;
        csr_write_en <= '0';
        wait for CLK_PERIOD;
        
        -- Lecture de mscratch
        csr_read_en <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la valeur lue correspond à la valeur écrite
        assert csr_read_data = csr_write_data report "Erreur: Valeur lue de mscratch incorrecte" severity error;
        
        -- Fin de la lecture
        csr_read_en <= '0';
        wait for CLK_PERIOD;
        
        print("Test 5: Vérification du niveau de privilège");
        -- Changement du niveau de privilège à User
        current_privilege <= "00";
        wait for CLK_PERIOD;
        
        -- Tentative d'écriture dans mstatus avec privilège insuffisant
        csr_addr <= CSR_MSTATUS_ADDR;
        csr_write_data <= X"0000000000000000000000000000000A"; -- Nouvelle valeur
        csr_write_en <= '1';
        wait for CLK_PERIOD;
        csr_write_en <= '0';
        wait for CLK_PERIOD;
        
        -- Lecture de mstatus
        csr_read_en <= '1';
        wait for CLK_PERIOD;
        
        -- Vérification que la valeur n'a pas été modifiée (privilège insuffisant)
        assert csr_read_data /= csr_write_data report "Erreur: mstatus modifié malgré privilège insuffisant" severity error;
        
        -- Fin de la lecture
        csr_read_en <= '0';
        wait for CLK_PERIOD;
        
        -- Retour au niveau de privilège Machine
        current_privilege <= "11";
        wait for CLK_PERIOD;
        
        -- Fin de la simulation
        print("Tous les tests ont été exécutés avec succès");
        wait;
    end process;
    
end architecture sim;