library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package CONFIG_PROYECTO is

    -- CONSTANTES
    constant PLL_C0_FREC : integer := 25E6;
    constant BAUD_FREC : integer := 115200;
    constant MSG_FREC : integer := 10;
    constant PIN_TX : integer := 15;
    constant BITS_MUESTRAS_MEDIA_MOVIL : integer := 10;
    constant V_TIEMPO_MEDIA_MOVIL : integer := 20;
    constant MSG_N_BYTES : integer := 11; -- CUIDADO: debe coincidir con el tamaño de indice
                                          -- dentro de MENSAJE_TX
                                          -- NO se modifica automaticamente
                                          
    -- BUSES
    type t_bus_temperatura is record
        bit_signo    :  std_logic;
        bcd_decenas  :  std_logic_vector(3 downto 0);
        bcd_unidades :  std_logic_vector(3 downto 0);
        bcd_decimas  :  std_logic_vector(3 downto 0);
        milivoltios           :  std_logic_vector(12 downto 0);
        centesimas_centigrado :  signed(15 downto 0);
        
    end record;

    -- 1. TODO LO QUE ENTRA A LA FPGA (Sensores y Periféricos de Entrada)
    type t_perifericos_in is record
        clk         : std_logic;
        reset_n     : std_logic;
        switches    : std_logic_vector(9 downto 0);  -- Los 10 switches de la DE10-Lite
        key         : std_logic_vector(1 downto 0);  -- Los pulsadores
        uart_rx_pin : std_logic;                     -- Pin físico de recepción serie
        adc_data    : std_logic_vector(11 downto 0); -- Datos crudos del integrado ADC
    end record;

    -- 2. TODO LO QUE SALE DE LA FPGA (Actuadores y Periféricos de Salida)
    type t_perifericos_out is record
        leds        : std_logic_vector(9 downto 0);  -- Los 10 LEDs integrados
        hex0        : std_logic_vector(6 downto 0);  -- Display 7 segmentos 0
        hex1        : std_logic_vector(6 downto 0);  -- Display 7 segmentos 1
        hex2        : std_logic_vector(6 downto 0);  -- Display 7 segmentos 2
        uart_tx_pin : std_logic;                     -- Pin físico de transmisión serie
        pwm_out     : std_logic;                     -- Pin hacia el transistor/motor
    end record;

end package;