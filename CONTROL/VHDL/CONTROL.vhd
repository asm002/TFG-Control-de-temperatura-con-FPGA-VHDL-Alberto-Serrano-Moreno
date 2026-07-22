-- Este modulo resuelve el control y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_CONTROL hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity CONTROL is
    generic(
        CLK_FREC : integer
        
    );
    PORT(
        clk : in std_logic;
        reset_n : in std_logic := '1';   -- conexion a reset activo a nivel bajo 
        
        bus_control_entrada : in t_bus_control;
        bus_temperatura : in t_bus_temperatura;

        t_on : out unsigned(N_BITS_PWM-1 downto 0)
    );
END entity;

architecture Behavioral of CONTROL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        TODO_O_NADA_inst : entity work.TODO_O_NADA
            port map (
                clk => clk,
                reset => not reset_n,

                temp_actual => bus_temperatura.centesimas_centigrado,
                consigna => bus_control_entrada.consigna,

                t_on => t_on
            );



        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;