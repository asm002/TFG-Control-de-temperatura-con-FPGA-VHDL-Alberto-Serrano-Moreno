-- Este modulo tan solo instancia COMUNICACIONES (y adquisicion) 
-- para conectarlo con los periféricos de la tarjeta y así probar dicho modulo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.CONFIG_PROYECTO.all;

entity TOP_LEVEL_ENTITY_COM is
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

architecture Behavioral of TOP_LEVEL_ENTITY_COM is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    signal clk_adc : std_logic; -- 25 MHz
    signal pll_locked : std_logic;
    signal reset_and_pll_n : std_logic;
    
    signal bus_temperatura : t_bus_temperatura;
    signal bus_displays : t_displays_7seg;

    signal bus_datos_graficos : t_bus_datos_graficos_tx;
    signal bus_control_data_rx : t_bus_control_data_rx;
    signal modo_valid, pwm_valid, pid_valid : std_logic := '0';
    signal consigna_reg : signed(N_BITS_CELSIUS-1 downto 0);
    signal pwm_reg      : std_logic_vector(N_BITS_PWM-1 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        COMUNICACIONES : entity work.COMUNICACIONES
            generic map(
                CLK_FREQ => PLL_C0_FREC,
                BAUD_FREQ => BAUD_FREC,
                MSG_FREQ => MSG_FREC  -- 100 ms -> 10 hz
                )
            port map(
                clk => clk_adc,
                reset_n => reset_and_pll_n,
                
                uart_tx => ARDUINO_IO(PIN_TX),
                uart_rx => ARDUINO_IO(PIN_RX),
                uart_tx_echo => ARDUINO_IO(PIN_TX_ECHO),
                
                -- DATOS DESDE OTRAS AREAS (Para enviar por TX) --
                bus_datos_graficos => bus_datos_graficos,
                
                -- DATOS HACIA OTRAS AREAS (Recibidos por RX) --
                bus_control_data_rx => bus_control_data_rx,
                modo_valid => modo_valid,
                pwm_valid => pwm_valid,
                pid_valid => pid_valid
            );

            
        ADQUISICION : entity work.ADQUISICION_DE_DATOS
            port map(
                clk_50 => MAX10_CLK1_50,
                reset_n => ARDUINO_RESET_N, -- mucho cuidado, aqui solo reset de boton,
                                            -- usar reset_and_pll_n crea un bucle
                                            -- infinito y no funciona nada
                                            
                modo_displays => SW(0),
                
                clk_adc => clk_adc,
                pll_locked_out => pll_locked,
                
                bus_temperatura => bus_temperatura,
                displays_out => bus_displays
                
        );
            
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        reset_and_pll_n <= ARDUINO_RESET_N and pll_locked;  -- reset de boton y ademas condicionado a que el pll
                                                            -- esté listo. Activo a nivel bajo
        
        -- BUSES SALIDA
        HEX0 <= bus_displays(0);
        HEX1 <= bus_displays(1);
        HEX2 <= bus_displays(2);
        HEX3 <= bus_displays(3);
        HEX4 <= bus_displays(4);
        HEX5 <= bus_displays(5);
        
        -- Se simulan los datos que llegarian desde el area de control
        -- bus_datos_graficos.consigna <= to_signed(2050, N_BITS_CELSIUS);
        -- bus_datos_graficos.bus_temperatura <= bus_temperatura;
        -- bus_datos_graficos.error <= (bus_datos_graficos.consigna - bus_temperatura.centesimas_centigrado);
        -- bus_datos_graficos.pwm <= std_logic_vector(TO_UNSIGNED(512, N_BITS_PWM));

        -- Conectamos los registros "espejo" al bus de transmision
        bus_datos_graficos.consigna <= consigna_reg;
        bus_datos_graficos.bus_temperatura <= bus_temperatura;
        bus_datos_graficos.error <= (consigna_reg - bus_temperatura.centesimas_centigrado);
        bus_datos_graficos.pwm <= pwm_reg;
    
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        -- proceso para simular lo que llega del modulo de control. Como no hay modulo de control,
        -- se hace efecto espejo: lo que se recibe por RX (bus_control_data_rx), se manda (no todo)
        -- por TX (bus_datos_graficos)
        process(clk_adc, reset_and_pll_n)
        begin
            if reset_and_pll_n = '0' then
                -- Valores por defecto al resetear
                consigna_reg <= to_signed(2050, N_BITS_CELSIUS); 
                pwm_reg <= std_logic_vector(TO_UNSIGNED(512, N_BITS_PWM));
                
            elsif rising_edge(clk_adc) then
                -- Cuando llega un comando PID válido, actualizamos la consigna
                if pid_valid = '1' then
                    consigna_reg <= bus_control_data_rx.consigna;
                end if;
                
                -- Cuando llega un comando PWM válido, actualizamos el ciclo de trabajo
                if pwm_valid = '1' then
                    pwm_reg <= bus_control_data_rx.pwm_lazo_abierto;
                end if;
            end if;
        end process;

end architecture;
