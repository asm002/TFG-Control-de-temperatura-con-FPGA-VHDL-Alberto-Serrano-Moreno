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
    constant PIN_TX : integer := 15;    -- pin del bus ARDUINO_IO
    constant PIN_RX : integer := 14;    -- pin del bus ARDUINO_IO
    constant PIN_TX_ECHO : integer := 13; -- pin de eco, donde se manda 
                                          -- lo mismo que se recibe
    constant PIN_PWM : integer := 12;

    -- Dimensionado
    constant N_BITS_CELSIUS : integer := 16;  -- hay que modificar adquisicion y comunicaciones
                                              -- para que la use
    constant N_BITS_MILIVOLTIOS : integer := 13; -- idem
    constant BITS_MUESTRAS_MEDIA_MOVIL : integer := 8;
    constant N_BITS_PWM : integer := 10;
    constant V_TIEMPO_MEDIA_MOVIL : integer := 20;  -- ventana de tiempo en milisegundos

    constant MSG_N_BYTES_TX : integer := 29; -- CUIDADO: debe coincidir con el tamaño
                                             -- de indice dentro de MENSAJE_TX.
                                             -- No se puede modificar sin modificar la
                                             -- arquitectura de MENSAJE_TX

    constant N_BYTES_BUFFER_RX : integer := 64;  -- debe ser >= al numero maximo de 
                                                 -- bytes que podrá enviar el PC
    
    
    
    ---- BUSES Y ARRAYS ----
    type t_bus_temperatura is record
        bit_signo    :  std_logic;
        bcd_decenas  :  std_logic_vector(3 downto 0);
        bcd_unidades :  std_logic_vector(3 downto 0);
        bcd_decimas  :  std_logic_vector(3 downto 0);
        milivoltios  :  std_logic_vector(N_BITS_MILIVOLTIOS-1 downto 0);

        -- 16 bits para poder representar todo el rango de temperatura de 0 a 5000 mV
        centesimas_centigrado :  signed(N_BITS_CELSIUS-1 downto 0);
        
    end record;

    type t_bus_control is record
        modo                  : std_logic;  -- '0' -> lazo abierto ; '1' -> lazo cerrado
        pwm_lazo_abierto      : std_logic_vector(N_BITS_PWM-1 downto 0);   -- 0 a 1023
        kp                    : std_logic_vector(15 downto 0);  -- 0.00 a 99.99
        ki                    : std_logic_vector(15 downto 0);  -- 0.00 a 99.99
        kd                    : std_logic_vector(15 downto 0);  -- 0.00 a 99.99
        consigna              : signed(N_BITS_CELSIUS-1 downto 0);  -- -99.90 a +99.90
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