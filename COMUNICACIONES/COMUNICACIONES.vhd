-- Este modulo resuelve las comunicaciones y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_COM hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity COMUNICACIONES is
    generic(
        CLK_FREQ : integer := 50E6;
        BAUD_FREQ : integer := 115200
    );
    PORT(
        clk : in std_logic;  -- conexion al reloj de 50 Mhz 
                                -- (OJO: EN EL PROYECTO FINAL SERIA 
                                -- MEJOR USAR EL RELOJ DEL ADC DE 10MHZ)
        switches : in std_logic_vector (9 downto 0);  -- conexiones a los SW()       
        reset_n : in std_logic := '0';   -- conexion a arduino reset 
        out_pin : out std_logic;
        in_pin : in std_logic := '0'
    );
END entity;

architecture Behavioral of COMUNICACIONES is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal baud_clock_enable : std_logic;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        BAUD_GEN : entity work.GENERADOR_PULSOS
            generic map(
                CLK_FREC => CLK_FREQ,
                PULSE_FREC => BAUD_FREQ
            )
            port map(
                CLK => clk,
                RESET => not reset_n,
                PULSE => baud_clock_enable
            );
        
        UART_TX0 : entity work.UART_TX
            port map(
                clk => clk,       
                rst => not reset_n,
                baud_ce => baud_clock_enable,
                tx_start => '1',   
                tx_data => x"41",    
                tx_out => out_pin,    
                tx_ready => open,    
                tx_done => open   
            );
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;