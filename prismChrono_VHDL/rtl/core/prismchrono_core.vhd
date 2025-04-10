library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Import du package de types personnalisé
library work;
use work.prismchrono_types_pkg.all;

entity prismchrono_core is
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
end entity prismchrono_core;

architecture rtl of prismchrono_core is
    -- Composant unité de contrôle
    component control_unit is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            opcode          : in  OpcodeType;                    -- Opcode de l'instruction courante
            flags           : in  FlagBusType;                   -- Flags de l'ALU
            control_signals : out ControlSignalsType;            -- Signaux de contrôle pour le datapath
            current_state   : out FsmStateType                   -- État courant de la FSM (pour debug)
        );
    end component;
    
    -- Composant datapath
    component datapath is
        port (
            clk             : in  std_logic;                     -- Horloge système
            rst             : in  std_logic;                     -- Reset asynchrone
            control_signals : in  ControlSignalsType;            -- Signaux de contrôle
            instr_data      : in  EncodedWord;                   -- Données d'instruction de la mémoire
            mem_data_in     : in  EncodedWord;                   -- Données de la mémoire (lecture)
            opcode          : out OpcodeType;                    -- Opcode pour l'unité de contrôle
            flags           : out FlagBusType;                   -- Flags de l'ALU
            pc_out          : out EncodedAddress;                -- Adresse du PC (pour la mémoire d'instructions)
            mem_addr        : out EncodedAddress;                -- Adresse mémoire (pour la mémoire de données)
            mem_data_out    : out EncodedWord                    -- Données pour la mémoire (écriture)
        );
    end component;
    
    -- Signaux internes pour la connexion entre l'unité de contrôle et le datapath
    signal opcode : OpcodeType;
    signal flags : FlagBusType;
    signal branch_cond : BranchCondType;
    signal control_signals : ControlSignalsType;
    
begin
    -- Instanciation de l'unité de contrôle
    inst_control_unit : control_unit
        port map (
            clk             => clk,
            rst             => rst,
            opcode          => opcode,
            flags           => flags,
            branch_cond     => branch_cond,
            control_signals => control_signals,
            current_state   => debug_state
        );
    
    -- Instanciation du datapath
    inst_datapath : datapath
        port map (
            clk             => clk,
            rst             => rst,
            control_signals => control_signals,
            instr_data      => instr_data,
            mem_data_in     => mem_data_in,
            opcode          => opcode,
            flags           => flags,
            pc_out          => instr_addr,
            mem_addr        => mem_addr,
            mem_data_out    => mem_data_out,
            branch_cond     => branch_cond
        );
    
    -- Connexion des signaux de contrôle mémoire aux sorties
    mem_read <= control_signals.mem_read;
    mem_write <= control_signals.mem_write;
    halted <= control_signals.halted;
    
end architecture rtl;