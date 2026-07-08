-- Este modulo resuelve la generación PWM y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_PWM hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity PWM is
    generic(
        CLK_FREC : integer;
        PWM_FREC : integer;
        N_BITS : integer
    );
    PORT(
        clk : in std_logic;
        reset_n : in std_logic := '1';   -- conexion a reset activo a nivel bajo 
        
        t_on : in std_logic_vector(N_BITS-1 downto 0);
        pwm_out : out std_logic := '0'
    );
END entity;

architecture Behavioral of PWM is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        GENERADOR_PWM0 : entity work.GENERADOR_PWM
            generic map (
                CLK_FREC => CLK_FREC,
                FREC => PWM_FREC,
                N_BITS => N_BITS
            )
            port map (
                clk => clk,
                reset => not reset_n,
                t_on => t_on,
                pwm_out => pwm_out
            );

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;