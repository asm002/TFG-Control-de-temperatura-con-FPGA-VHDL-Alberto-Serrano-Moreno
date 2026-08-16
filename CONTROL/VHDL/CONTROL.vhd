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
        
        -- Datos de adquisición
        bus_temperatura : in t_bus_temperatura;

        -- Datos del parser (COMUNICACIONES RX)
        bus_control_data_rx : in t_bus_control_data_rx;
        modo_valid : in std_logic;
        pwm_valid : in std_logic;
        pid_valid : in std_logic;

        -- DATOS PARA ENVIAR (COMUNICACIONES TX)
        bus_datos_graficos_tx : out t_bus_datos_graficos_tx;

        -- ESTADO INTERNO (variables de control almacenadas)
        bus_estado_interno : out t_bus_estado_control;

        -- SALIDA AL MÓDULO PWM (Conectar a 't_on' en el Top Level)
        pwm_t_on : out unsigned(N_BITS_PWM-1 downto 0)

    );
END entity;

architecture Behavioral of CONTROL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    -- registro de la informacion recibida por PC (RX)
    signal bus_control_data_rx_registro : t_bus_control_data_rx := (
        modo => MODO0,
        pwm_lazo_abierto => PWM_MANUAL0,
        kp => KP0,
        ki => KI0,
        kd => KD0,
        consigna => CONSIGNA0
    );
    -- signal modo_reg       : std_logic := '0'; -- '0' = lazo abierto, '1' = lazo cerrado
    -- signal pwm_manual_reg : std_logic_vector(N_BITS_PWM-1 downto 0) := (others => '0');
    -- signal consigna_reg   : signed(N_BITS_CELSIUS-1 downto 0) := to_signed(2000, N_BITS_CELSIUS); -- 20.00C por defecto

    -- bus de todas las variables de control (para mostrar por displays)
    signal bus_estado_global : t_bus_estado_control;

    signal pwm_t_on_aplicado : unsigned(N_BITS_PWM-1 downto 0);
    signal pwm_t_on_lazo_cerrado : unsigned(N_BITS_PWM-1 downto 0);
    signal pwm_t_on_lazo_abierto : unsigned(N_BITS_PWM-1 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        TODO_O_NADA0 : entity work.TODO_O_NADA
            port map (
                clk => clk,
                reset => not reset_n,

                temp_actual => bus_temperatura.centesimas_celsius,
                consigna => bus_control_data_rx_registro.consigna,

                t_on => pwm_t_on_lazo_cerrado
            );

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- Seleccion de PWM segun el modo de trabajo
        pwm_t_on_aplicado <= pwm_t_on_lazo_cerrado when bus_control_data_rx_registro.modo = '1' else pwm_t_on_lazo_abierto;
        pwm_t_on_lazo_abierto <= unsigned(bus_control_data_rx_registro.pwm_lazo_abierto);

        -- Salida PWM
        pwm_t_on <= pwm_t_on_aplicado;

        -- Datos para graficar
        bus_datos_graficos_tx.consigna <= bus_control_data_rx_registro.consigna;
        bus_datos_graficos_tx.bus_temperatura <= bus_temperatura;
        bus_datos_graficos_tx.error <= (bus_control_data_rx_registro.consigna - bus_temperatura.centesimas_celsius);
        bus_datos_graficos_tx.pwm <= std_logic_vector(pwm_t_on_aplicado);

        -- Datos del bus global
        bus_estado_global.modo <= bus_control_data_rx_registro.modo;
        bus_estado_global.pwm <= std_logic_vector(pwm_t_on_aplicado);
        bus_estado_global.kp <= bus_control_data_rx_registro.kp;
        bus_estado_global.ki <= bus_control_data_rx_registro.ki;
        bus_estado_global.kd <= bus_control_data_rx_registro.kd;
        bus_estado_global.consigna <= bus_control_data_rx_registro.consigna;
        bus_estado_global.bus_temperatura <= bus_temperatura;
        bus_estado_global.error <= (bus_control_data_rx_registro.consigna - bus_temperatura.centesimas_celsius);

        -- Salida del estado interno de control
        bus_estado_interno <= bus_estado_global;

        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
    process(clk, reset_n)
    
    begin
        if not reset_n = '1' then
            bus_control_data_rx_registro.modo <= '0'; -- Por seguridad, arranca en manual
            bus_control_data_rx_registro.pwm_lazo_abierto <= PWM_MANUAL0;
            bus_control_data_rx_registro.kp <= KP0;
            bus_control_data_rx_registro.ki <= KI0;
            bus_control_data_rx_registro.kd <= KD0;
            bus_control_data_rx_registro.consigna <= CONSIGNA0;
            
        elsif rising_edge(clk) then
            -- Actualiza los registros solo cuando el parser indica un dato válido
            if modo_valid = '1' then
                bus_control_data_rx_registro.modo <= bus_control_data_rx.modo; 
            end if;
            
            if pwm_valid = '1' then
                bus_control_data_rx_registro.pwm_lazo_abierto <= bus_control_data_rx.pwm_lazo_abierto;
            end if;
            
            if pid_valid = '1' then
                bus_control_data_rx_registro.kp <= bus_control_data_rx.kp;
                bus_control_data_rx_registro.ki <= bus_control_data_rx.ki;
                bus_control_data_rx_registro.kd <= bus_control_data_rx.kd;
                bus_control_data_rx_registro.consigna <= bus_control_data_rx.consigna;
            end if;
        end if;
    end process;
        
end architecture;