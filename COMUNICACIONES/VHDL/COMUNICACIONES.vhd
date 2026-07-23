-- Este modulo resuelve las comunicaciones y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_COM hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity COMUNICACIONES is
    generic(
        CLK_FREQ : integer;
        BAUD_FREQ : integer;
        MSG_FREQ : integer
    );
    PORT(
        clk : in std_logic;
        reset_n : in std_logic := '0';   -- conexion a reset activo a nivel bajo 
        
        uart_tx : out std_logic;
        uart_rx : in std_logic := '0';
        uart_tx_echo : out std_logic;
                
        -- DATOS DESDE OTRAS AREAS (Para enviar por TX) --
        bus_datos_graficos : in t_bus_datos_graficos_tx;

        -- DATOS HACIA OTRAS AREAS (Recibidos por RX) --
        bus_control_data_rx : out t_bus_control_data_rx;
        modo_valid          : out std_logic;
        pwm_valid           : out std_logic;
        pid_valid           : out std_logic

    );
END entity;

architecture Behavioral of COMUNICACIONES is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal baud_clock_enable : std_logic := '0';
    signal msg_pulse : std_logic := '0';
    
    signal s_tx_ready, s_tx_start, s_tx_done : std_logic := '0';
    signal s_tx_byte : std_logic_vector(7 downto 0) := (others => '0');
    
    signal s_rx_ready : std_logic := '0';
    signal s_rx_byte : std_logic_vector(7 downto 0) := (others => '0');
    
    signal s_tx_ready_echo, s_tx_done_echo : std_logic := '0';
                                       
    signal msg_byte_indice : integer range 0 to MSG_N_BYTES_TX-1;
    signal msg_byte : std_logic_vector(7 downto 0);

    signal s_rx_buffer_ready, s_rx_liberar_buffer : std_logic;
    signal s_rx_indice_buffer_out_byte : integer range 0 to N_BYTES_BUFFER_RX-1;
    signal s_rx_buffer_out_byte : std_logic_vector(7 downto 0);

    -- signal control_data_rx : t_bus_control_data_rx;
    -- signal s_modo_valid, s_pwm_valid, s_pid_valid : std_logic;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        BAUD_GEN0 : entity work.GENERADOR_PULSOS
            generic map(
                CLK_FREC => CLK_FREQ,
                PULSE_FREC => BAUD_FREQ
            )
            port map(
                CLK => clk,
                RESET => not reset_n,
                PULSE => baud_clock_enable
            );
        
        FREC_MENSAJE0 : entity work.GENERADOR_PULSOS
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
                tx_start => s_tx_start,   
                tx_byte => s_tx_byte,    
                tx_out => uart_tx,    
                tx_ready => s_tx_ready,    
                tx_done => s_tx_done   
            );
            
        MENSAJE_TX0 : entity work.MENSAJE_TX
            port map(
                indice => msg_byte_indice,
                byte_out => msg_byte,
                
                bus_datos_graficos => bus_datos_graficos -- [LISTO] CAMBIAR!!! Ha servido para probar,
                -- pero los datos de control que se envian al pc no deben provenir
                -- directamente de la lectura del puerto serie, 
                -- sino del registro del modulo de control cuando esté hecho
            );
            
        SECUENCIADOR0 : entity work.SECUENCIADOR
            generic map(
                MSG_N_BYTES => MSG_N_BYTES_TX
            )
            port map(
                clk => clk,
                rst => not reset_n,
                mandar_mensaje => msg_pulse,
                tx_ready => s_tx_ready,
                tx_done => s_tx_done,
                tx_start => s_tx_start,
                tx_data => s_tx_byte,
                
                msg_byte_indice => msg_byte_indice,
                msg_byte => msg_byte
                );

        UART_RX0 : entity work.UART_RX
            generic map (
                CLK_FREC => CLK_FREQ,
                BAUD_FREC => BAUD_FREQ
            )
            port map (
                clk => clk,
                rst => not reset_n,
                rx_in => uart_rx,
                rx_byte => s_rx_byte,
                rx_ready => s_rx_ready 
            );

        UART_TX_echo_RX0: entity work.UART_TX
            port map (
                clk => clk,
                rst => not reset_n,
                baud_ce => baud_clock_enable,
                tx_start => s_rx_ready,
                tx_byte => s_rx_byte,
                tx_out => uart_tx_echo,
                tx_ready => s_tx_ready_echo,
                tx_done => s_tx_done_echo
            );

        BUFFER_RX0 : entity work.BUFFER_RX
            port map (
                clk => clk,
                rst => not reset_n,

                -- INTERFAZ CON UART_RX
                rx_byte => s_rx_byte,
                rx_ready => s_rx_ready,

                -- INTERFAZ CON PARSER_ASCII
                buffer_ready => s_rx_buffer_ready,
                liberar_buffer => s_rx_liberar_buffer,
                indice_out_byte => s_rx_indice_buffer_out_byte,
                out_byte => s_rx_buffer_out_byte
            );

        
        PARSER_ASCII_RX0 : entity work.PARSER_ASCII_RX
            port map (
                clk => clk,
                rst => not reset_n,

                -- INTERFAZ CON BUFFER_RX
                buffer_ready => s_rx_buffer_ready,
                in_byte => s_rx_buffer_out_byte,
                indice_out_byte => s_rx_indice_buffer_out_byte,
                liberar_buffer => s_rx_liberar_buffer,

                -- INTERFAZ CON EL SISTEMA DE CONTROL
                control_rx => bus_control_data_rx,
                modo_valid => modo_valid,
                pwm_valid => pwm_valid,
                pid_valid => pid_valid
            );



        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        
end architecture;