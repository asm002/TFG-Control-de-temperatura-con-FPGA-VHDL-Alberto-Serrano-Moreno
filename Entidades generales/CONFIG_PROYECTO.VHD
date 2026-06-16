library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package CONFIG_PROYECTO is

    -- CONSTANTES
    constant PLL_C0_FREC : integer := 25E6; -- lo suyo sería modificar el PLL para que esta frecuencia sea 50 Mhz
                                            -- cuanto mas alta, menores imprecisiones y mejor pwm
    constant BAUD_FREC : integer := 115200;
    constant MSG_FREC : integer := 10;  -- frecuencia a la que se envian los datos por puerto serie (TX)
                                        -- 10 hz -> 100 ms

    constant PIN_TX : integer := 15;    -- pin del bus ARDUINO_IO
    constant PIN_RX : integer := 14;    -- pin del bus ARDUINO_IO
    constant PIN_TX_ECHO : integer := 13; -- pin de eco, donde se manda 
                                          -- lo mismo que se recibe

    constant BITS_MUESTRAS_MEDIA_MOVIL : integer := 8;
    constant V_TIEMPO_MEDIA_MOVIL : integer := 20;  -- ventana de tiempo en milisegundos

    constant MSG_N_BYTES_TX : integer := 28; -- CUIDADO: debe coincidir con el tamaño
                                          -- de indice dentro de MENSAJE_TX
                                          -- No se puede modificar sin modificar la
                                          -- arquitectura de MENSAJE_TX

    constant N_BYTES_BUFFER_RX : integer := 64;  -- debe ser >= al numero maximo de 
                                                 -- bytes que podrá enviar el PC
    
                                          
                                          
    -- BUSES
    type t_bus_temperatura is record
        bit_signo    :  std_logic;
        bcd_decenas  :  std_logic_vector(3 downto 0);
        bcd_unidades :  std_logic_vector(3 downto 0);
        bcd_decimas  :  std_logic_vector(3 downto 0);
        milivoltios           :  std_logic_vector(12 downto 0);
        centesimas_centigrado :  signed(15 downto 0);
        
    end record;

    -- Array de displays 7 segmentos
    type t_displays_7seg is array (0 to 5) of std_logic_vector(7 downto 0);

end package;