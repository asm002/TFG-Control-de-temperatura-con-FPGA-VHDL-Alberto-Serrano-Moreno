-- Este modulo resuelve las comunicaciones y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_COM hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.CONFIG_PROYECTO.all;

entity COMUNICACIONES is
    generic(
        CLK_FREQ : integer := 50E6;
        BAUD_FREQ : integer := 115200;
        MSG_FREQ : integer := 10    -- 100 ms -> 10 hz
    );
    PORT(
        clk : in std_logic;  -- conexion al reloj de 50 Mhz 
                             -- (OJO: EN EL PROYECTO FINAL SERIA 
                             -- MEJOR USAR EL RELOJ DEL ADC DE 10MHZ)
        reset_n : in std_logic := '0';   -- conexion a reset activo a nivel bajo 
        
        uart_tx : out std_logic;
        uart_rx : in std_logic := '0';
                
        -- DATOS DE OTRAS AREAS --
        -- ADQUISICION:
        bus_temperatura : in t_bus_temperatura
        
    );
END entity;

architecture Behavioral of COMUNICACIONES is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal baud_clock_enable : std_logic := '0';
    signal msg_pulse : std_logic := '0';
    
    signal s_ready, s_start, s_done : std_logic := '0';
    signal s_data : std_logic_vector(7 downto 0) := (others => '0');
                                       
    signal msg_byte_indice : integer range 0 to MSG_N_BYTES-1;
    signal msg_byte : std_logic_vector(7 downto 0);
    
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
        
        FREC_MENSAJE : entity work.GENERADOR_PULSOS
            generic map(
                CLK_FREC => CLK_FREQ,
                PULSE_FREC => MSG_FREQ
                )
            port map(
                CLK => clk,
                RESET => not reset_n,
                PULSE => msg_pulse
                );
        
        UART_TX0 : entity work.UART_TX
            port map(
                clk => clk,       
                rst => not reset_n,
                baud_ce => baud_clock_enable,
                tx_start => s_start,   
                tx_data => s_data,    
                tx_out => uart_tx,    
                tx_ready => s_ready,    
                tx_done => s_done   
            );
            
        MENSAJE_TX0 : entity work.MENSAJE_TX
            port map(
                indice => msg_byte_indice,
                byte_out => msg_byte,
                
                bus_temperatura => bus_temperatura
            );
            
        SECUENCIADOR0 : entity work.SECUENCIADOR
            generic map(
                MSG_N_BYTES => MSG_N_BYTES
            )
            port map(
                clk => clk,
                rst => not reset_n,
                mandar_mensaje => msg_pulse,
                tx_ready => s_ready,
                tx_done => s_done,
                tx_start => s_start,
                tx_data => s_data,
                
                msg_byte_indice => msg_byte_indice,
                msg_byte => msg_byte
                );
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;