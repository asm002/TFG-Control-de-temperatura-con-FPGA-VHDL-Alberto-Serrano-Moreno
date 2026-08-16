

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity TOP_LEVEL_ENTITY_CONTROL is
    PORT(
            MAX10_CLK1_50 : in std_logic;
            ADC_CLK_10 : in std_logic;
            SW : in std_logic_vector (9 downto 0);
            KEY : in std_logic_vector (1 downto 0);
            LEDR : out std_logic_vector (9 downto 0) := (others=>'0');          
            ARDUINO_RESET_N : in std_logic;
            ARDUINO_IO : inout std_logic_vector (15 downto 0);
            HEX0 : out std_logic_vector (7 downto 0);
            HEX1 : out std_logic_vector (7 downto 0);
            HEX2 : out std_logic_vector (7 downto 0);
            HEX3 : out std_logic_vector (7 downto 0);
            HEX4 : out std_logic_vector (7 downto 0);
            HEX5 : out std_logic_vector (7 downto 0)
    );
END entity;

architecture Behavioral of TOP_LEVEL_ENTITY_CONTROL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    -- ADQUISICION DE DATOS --
    signal clk_adc : std_logic;
    signal bus_temperatura : t_bus_temperatura;
    signal pll_locked, reset_and_pll_n : std_logic;


    -- CONTROL Y COMUNICACIONES --
    signal bus_datos_graficos_tx : t_bus_datos_graficos_tx;
    signal bus_control_data_rx : t_bus_control_data_rx;
    signal modo_valid, pid_valid, pwm_valid : std_logic;
    signal bus_estado_interno : t_bus_estado_control;


    -- PWM --
    signal salida_digital_pwm : std_logic := '0';
    signal pulso_200hz : std_logic := '0';  -- para ajustar el PWM manualmente
    signal pwm_t_on : UNSIGNED(N_BITS_PWM-1 downto 0) := (others => '0');   -- 0 a 1023


    -- INTERFAZ DE USUARIO
    signal KEY_pulsos : std_logic_vector(1 downto 0);
    signal SW_sync : std_logic_vector(9 downto 0);
    signal avanzar, retroceder, ajustar : std_logic;


    -- GESTION DE DISPLAYS --
    constant N_PANTALLAS : integer := 9;
    signal contador_pantallas : integer range 0 to N_PANTALLAS-1;

    signal info_displays_modo : t_bus_info_displays;
    signal info_displays_pwm : t_bus_info_displays;
    signal info_displays_kp : t_bus_info_displays;
    signal info_displays_ki : t_bus_info_displays;
    signal info_displays_kd : t_bus_info_displays;
    signal info_displays_consigna : t_bus_info_displays;
    signal info_displays_celsius : t_bus_info_displays;
    signal info_displays_mv : t_bus_info_displays;
    signal info_displays_error : t_bus_info_displays;
    signal info_displays_activa : t_bus_info_displays;
    signal id : std_logic_vector(3 downto 0);   -- se le asigna el valor del contador

    signal bus_t_disp : t_bus_temperatura;
    signal pulso4hz : std_logic;

    signal array_displays_out : t_displays_7seg;


    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------

        -- GENERADOR_PULSOS_inst : entity work.GENERADOR_PULSOS
        --     generic map (
        --         CLK_FREC => PLL_C0_FREC,
        --         PULSE_FREC => 205
        --     )
        --     port map (
        --         CLK => clk_adc,
        --         RESET => not reset_and_pll_n,
        --         PULSE => pulso_200hz
        --     );

        ADQUISICION_DE_DATOS0 : entity work.ADQUISICION_DE_DATOS
            port map (
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N,
                
                clk_adc => clk_adc,
                pll_locked_out => pll_locked,

                bus_temperatura => bus_temperatura
            );

        COMUNICACIONES0 : entity work.COMUNICACIONES
            generic map (
                CLK_FREQ => PLL_C0_FREC,
                BAUD_FREQ => BAUD_FREC,
                MSG_FREQ => MSG_FREC
            )
            port map (
                clk => clk_adc,
                reset_n => reset_and_pll_n,

                -- Pines de comunicacion (convertidor puerto serie)
                uart_tx => ARDUINO_IO(PIN_TX),
                uart_rx => ARDUINO_IO(PIN_RX),
                uart_tx_echo => ARDUINO_IO(PIN_TX_ECHO),

                -- Datos desde los registros de CONTROL (Para enviar por TX) --
                bus_datos_graficos => bus_datos_graficos_tx,

                -- Datos para CONTROL (Recibidos por RX) --
                bus_control_data_rx => bus_control_data_rx,
                modo_valid => modo_valid,
                pwm_valid => pwm_valid,
                pid_valid => pid_valid
            );

        PWM0 : entity work.PWM
            generic map (
                CLK_FREC => PLL_C0_FREC,
                PWM_FREC => FREC_PWM,
                N_BITS => N_BITS_PWM
            )
            port map (
                clk => clk_adc,
                reset_n => reset_and_pll_n,
                t_on => std_logic_vector(pwm_t_on),
                pwm_out => salida_digital_pwm
            );

        CONTROL0 : entity work.CONTROL
            generic map (
                CLK_FREC => PLL_C0_FREC
            )
            port map (
                clk => clk_adc,
                reset_n => reset_and_pll_n,

                -- Datos de adquisición
                bus_temperatura => bus_temperatura,

                -- Datos del parser (COMUNICACIONES RX)
                bus_control_data_rx => bus_control_data_rx,
                modo_valid => modo_valid,
                pwm_valid => pwm_valid,
                pid_valid => pid_valid,

                -- DATOS PARA ENVIAR (COMUNICACIONES TX)
                bus_datos_graficos_tx => bus_datos_graficos_tx,

                -- ESTADO INTERNO (variables de control almacenadas)
                bus_estado_interno => bus_estado_interno,

                -- SALIDA AL MÓDULO PWM (Conectar a t_on en TOP)
                pwm_t_on => pwm_t_on
            );

        CAPTURA_PULSADORES0 : entity work.CAPTURA_PULSADORES
            generic map (
                N_PULSADORES => 2
            )
            port map (
                clk => clk_adc,
                reset => not reset_and_pll_n,

                pulsadores => not KEY,
                pulsos => KEY_pulsos
            );

        SINCRONIZADOR_ENTRADAS_SW : entity work.SINCRONIZADOR_ENTRADAS
            generic map (
                N_ENTRADAS => 10
            )
            port map (
                clk => clk_adc,
                reset => not reset_and_pll_n,

                entradas => SW,
                entradas_sincronizadas => SW_sync
            );

        GESTION_DISPLAYS0 : entity work.GESTION_DISPLAYS
            generic map (
                N_BITS_VALOR_ABSOLUTO => N_BITS_CELSIUS
            )
            port map (
                valor_absoluto => info_displays_activa.valor_absoluto,
                es_negativo => info_displays_activa.es_negativo,
                id => info_displays_activa.id,
                array_puntos_decimales => info_displays_activa.array_puntos_decimales,
                displays_hex_out => array_displays_out
            );

        GENERADOR_PULSOS0 : entity work.GENERADOR_PULSOS
            generic map (
                CLK_FREC => PLL_C0_FREC,
                PULSE_FREC => 4
            )
            port map (
                CLK => clk_adc,
                RESET => not reset_and_pll_n,
                PULSE => pulso4hz
            );


        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_and_pll_n <= ARDUINO_RESET_N and pll_locked;  -- reset de boton y ademas condicionado a que el pll
                                                            -- esté listo. Activo a nivel bajo
        

        -- PWM
        ARDUINO_IO(PIN_PWM) <= not salida_digital_pwm;  -- señal negada porque la etapa de potencia
                                                        -- tiene señal de control activa a nivel bajo
        LEDR(8) <= '1'; -- led al maximo como referencia
        LEDR(9) <= salida_digital_pwm;  -- led regulado por el mismo pwm


        -- PRUEBAS --
        --bus_registro_control.consigna <= to_signed(1200, N_BITS_CELSIUS);   -- 12 grados de consigna manual


        -- GESTION DISPLAYS
        avanzar <= KEY_pulsos(0);
        retroceder <= KEY_pulsos(1);
        -- se usará cuando haya registros modificables directamente en la FPGA (PWM manual por ejemplo)
        ajustar <= SW_sync(0);

        id <= std_logic_vector(to_unsigned(contador_pantallas, 4));

        info_displays_modo.valor_absoluto <= (0 => bus_estado_interno.modo, others => '0');
        info_displays_modo.es_negativo <= false;
        info_displays_modo.id <= id;
        info_displays_modo.array_puntos_decimales <= "0000";

        info_displays_pwm.valor_absoluto <= std_logic_vector(resize(unsigned(bus_estado_interno.pwm), 16));
        info_displays_pwm.es_negativo <= false;
        info_displays_pwm.id <= id;
        info_displays_pwm.array_puntos_decimales <= "0000";

        info_displays_kp.valor_absoluto <= std_logic_vector(resize(unsigned(bus_estado_interno.kp), 16));
        info_displays_kp.es_negativo <= false;
        info_displays_kp.id <= id;
        info_displays_kp.array_puntos_decimales <= "0100";

        info_displays_ki.valor_absoluto <= std_logic_vector(resize(unsigned(bus_estado_interno.ki), 16));
        info_displays_ki.es_negativo <= false;
        info_displays_ki.id <= id;
        info_displays_ki.array_puntos_decimales <= "0100";

        info_displays_kd.valor_absoluto <= std_logic_vector(resize(unsigned(bus_estado_interno.kd), 16));
        info_displays_kd.es_negativo <= false;
        info_displays_kd.id <= id;
        info_displays_kd.array_puntos_decimales <= "0100";

        info_displays_consigna.valor_absoluto <= std_logic_vector(abs(bus_estado_interno.consigna));
        info_displays_consigna.es_negativo <= bus_estado_interno.consigna(N_BITS_CELSIUS-1) = '1';
        info_displays_consigna.id <= id;
        info_displays_consigna.array_puntos_decimales <= "0100";

        info_displays_celsius.valor_absoluto <= std_logic_vector(abs(bus_t_disp.centesimas_celsius));
        info_displays_celsius.es_negativo <= bus_t_disp.centesimas_celsius(N_BITS_CELSIUS-1) = '1';
        info_displays_celsius.id <= id;
        info_displays_celsius.array_puntos_decimales <= "0100";

        info_displays_mv.valor_absoluto <= std_logic_vector(resize(unsigned(bus_t_disp.milivoltios), 16));
        info_displays_mv.es_negativo <= false;
        info_displays_mv.id <= id;
        info_displays_mv.array_puntos_decimales <= "1000";

        info_displays_error.valor_absoluto <= std_logic_vector(abs(bus_estado_interno.error));
        info_displays_error.es_negativo <= bus_estado_interno.error(N_BITS_CELSIUS-1) = '1';
        info_displays_error.id <= id;
        info_displays_error.array_puntos_decimales <= "0100";

        HEX0 <= array_displays_out(0);
        HEX1 <= array_displays_out(1);
        HEX2 <= array_displays_out(2);
        HEX3 <= array_displays_out(3);
        HEX4 <= array_displays_out(4);
        HEX5 <= array_displays_out(5);

        with contador_pantallas select info_displays_activa <= 
            info_displays_celsius   when 0,
            info_displays_mv        when 1,
            info_displays_modo      when 2,
            info_displays_consigna  when 3,
            info_displays_error     when 4,
            info_displays_pwm       when 5,
            info_displays_kp        when 6,
            info_displays_ki        when 7,
            info_displays_kd        when 8,
            info_displays_celsius   when others;

        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------

        process(clk_adc) -- Gestión del contador de pantallas
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk_adc) then
                    if reset_and_pll_n = '0' then
                        contador_pantallas <= 0;
                    else
                        if avanzar = '1' then
                            if contador_pantallas = N_PANTALLAS - 1 then
                                contador_pantallas <= 0;
                            else
                                contador_pantallas <= contador_pantallas + 1;
                            end if;

                        elsif retroceder = '1' then
                            if contador_pantallas = 0 then
                                contador_pantallas <= N_PANTALLAS - 1;
                            else
                                contador_pantallas <= contador_pantallas - 1;
                            end if;
                        end if;
                    end if;
                end if;
        end process;

        process(clk_adc) -- Refresco a 4 Hz de los displays
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk_adc) then
                    if reset_and_pll_n = '0' then
                        bus_t_disp.milivoltios <= (others => '0');
                        bus_t_disp.centesimas_celsius <= (others => '0');
                    else
                        if pulso4hz = '1' then
                            bus_t_disp <= bus_estado_interno.bus_temperatura;
                        end if;
                    end if;
                end if;
        end process;

end architecture;