-- ADVERTENCIA!! : la mayoría de constantes que aquí aparecen NO son parámetros de libre configuración.
-- Modificarlas requiere saber muy bien lo que se está haciendo y por lo general habrá que
-- modificar los sistemas (señales, buses, lógica...) para acomodar el nuevo valor.
-- El principal uso de este archivo es aglutinar todas las constantes aquí para verlas
-- todas de un vistazo y además no repetir sus valores en cada módulo que las necesite

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package CONFIG_PROYECTO is

    ---- CONSTANTES ----
    -- Frecuencias
    constant PLL_C0_FREC : integer := 25E6; -- lo suyo sería modificar el PLL para que esta frecuencia sea 50 Mhz
                                            -- cuanto mas alta, menores imprecisiones y mejor pwm
    constant BAUD_FREC : integer := 115200;
    constant MSG_FREC : integer := 10;  -- frecuencia a la que se envian los datos por puerto serie (TX)
                                        -- 10 hz -> 100 ms
    constant FREC_PWM : integer := 500;

    -- Pines
    constant PIN_TX : integer := 15;    -- pin del bus ARDUINO_IO (BLANCO)
    constant PIN_RX : integer := 14;    -- pin del bus ARDUINO_IO (VERDE)
    constant PIN_TX_ECHO : integer := 13; -- pin de eco, donde se manda 
                                          -- lo mismo que se recibe
    constant PIN_PWM : integer := 12;

    -- Dimensionado
    constant N_BITS_ADC : integer := 12;
    -- la señal de cuentas del ADC gana bits gracias al oversampling
    constant N_BITS_ADC_OVERSAMPLING : integer := 16;
    constant N_BITS_CELSIUS : integer := 16; -- centésimas de grado C
    constant N_BITS_MILIVOLTIOS : integer := 13;
    constant VREFmv : integer := 5000;  -- tension de referencia en milivoltios
    constant BITS_MUESTRAS_MEDIA_MOVIL : integer := 8;
    constant N_BITS_PWM : integer := 10;
    constant V_TIEMPO_MEDIA_MOVIL : integer := 20;  -- ventana de tiempo en milisegundos

    constant MSG_N_BYTES_TX : integer := 30; -- CUIDADO: debe coincidir con el tamaño
                                             -- de indice dentro de MENSAJE_TX.
                                             -- No se puede modificar sin modificar la
                                             -- arquitectura de MENSAJE_TX

    constant N_BYTES_BUFFER_RX : integer := 64;  -- debe ser >= al numero maximo de 
                                                 -- bytes que podrá enviar el PC
    constant N_BITS_PID : integer := 16;
    
    
    ---- BUSES Y ARRAYS ----
    type t_bus_temperatura is record
        milivoltios  :  std_logic_vector(N_BITS_MILIVOLTIOS-1 downto 0);
        -- 16 bits para poder representar todo el rango de temperatura de 0 a 5000 mV
        centesimas_celsius :  signed(N_BITS_CELSIUS-1 downto 0);
        
    end record;

    -- kp, ki, kd, consigna... pueden representarse con menos de 16 bits (0000 a 9999 ó -9999 a +9999)
    -- pero usamos 16 bits en todos por tener los mismos anchos de bus en todos y que
    -- además coincida con el tamaño de la temperatura celsius
    type t_bus_control_data_rx is record
        modo                  : std_logic;  -- '0' -> lazo abierto ; '1' -> lazo cerrado
        pwm_lazo_abierto      : std_logic_vector(N_BITS_PWM-1 downto 0);   -- 0 a 1023
        kp                    : std_logic_vector(N_BITS_PID-1 downto 0);  -- 0.00 a 99.99
        ki                    : std_logic_vector(N_BITS_PID-1 downto 0);  -- 0.00 a 99.99
        kd                    : std_logic_vector(N_BITS_PID-1 downto 0);  -- 0.00 a 99.99
        consigna              : signed(N_BITS_CELSIUS-1 downto 0);  -- -99.90 a +99.90
    end record;

    type t_bus_datos_graficos_tx is record
        consigna        : signed(N_BITS_CELSIUS-1 downto 0);  -- -99.90 a +99.90 
        bus_temperatura : t_bus_temperatura;
        error           : signed(N_BITS_CELSIUS-1 downto 0);  -- -199.8 a +199.8
        pwm             : std_logic_vector(N_BITS_PWM-1 downto 0);   -- 0 a 1023
    end record;

    type t_bus_bcd is record
        bcd0, bcd1, bcd2, bcd3 : std_logic_vector(3 downto 0);
    end record;

    -- Array de displays 7 segmentos
    type t_displays_7seg is array (0 to 5) of std_logic_vector(7 downto 0);

    type t_bus_info_displays is record
        valor_absoluto         : std_logic_vector(15 downto 0);
        es_negativo            : boolean;
        id                     : std_logic_vector(3 downto 0);
        array_puntos_decimales : std_logic_vector(3 downto 0);   -- 9.9.9.9. -> "1111"
    end record;

    

end package;