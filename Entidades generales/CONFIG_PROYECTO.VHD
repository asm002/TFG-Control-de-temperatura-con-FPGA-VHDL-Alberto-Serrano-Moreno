library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package CONFIG_PROYECTO is

    -- CONSTANTES
    constant PLL_C0_FREC : integer := 25E6;
    constant BAUD_FREC : integer := 115200;
    constant MSG_FREC : integer := 10;
    constant PIN_TX : integer := 15;
    constant BITS_MUESTRAS_MEDIA_MOVIL : integer := 8;
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

    
    type t_displays_7seg is array (0 to 5) of std_logic_vector(7 downto 0);

end package;