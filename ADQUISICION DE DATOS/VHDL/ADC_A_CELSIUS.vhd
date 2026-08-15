library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity ADC_A_CELSIUS is
    GENERIC(
        N_BITS_ADC : integer := 16  -- 16 bits tras oversampling
    );
    PORT(
        cuentas_ADC        : in std_logic_vector(N_BITS_ADC-1 downto 0);
        centesimas_celsius : out signed(N_BITS_CELSIUS-1 downto 0)
    );
END entity;

architecture Behavioral of ADC_A_CELSIUS is

    -- hacen falta 16 bits para representar la tension de referencia
    -- en unidades de décima de milivoltio: 50000 [10^-4 V]
    constant N_BITS_FACTOR : integer := 16;
    -- VREFmv = 5000 [mV]
    constant vRef_dmv : unsigned(N_BITS_FACTOR-1 downto 0) := to_unsigned(VREFmv * 10, N_BITS_FACTOR);
    
    constant N_BITS_PRODUCTO : integer := N_BITS_ADC + N_BITS_FACTOR;
    signal producto : unsigned(N_BITS_PRODUCTO-1 downto 0);
    
    constant N_BITS_DMV : integer := N_BITS_PRODUCTO - N_BITS_ADC;
    signal tension_decimas_mv  : unsigned(N_BITS_DMV-1  downto 0);
    constant N_BITS_TEMP : integer := N_BITS_DMV + 1;
    signal celsius_centesimas : signed(N_BITS_TEMP-1 downto 0);

begin

    -- Hay que obtener la tension en decimas de milivoltio para
    -- tener la resolucion en tension suficiente necesaria
    -- para obtener una resolucion de temperatura de centesimas

    -- producto de las cuentas del ADC y de la tension de referencia en 10^-4 V
    producto <= unsigned(cuentas_ADC) * vRef_dmv;

    -- división entre 2^N_BITS_ADC (desplazamiento de bits a la derecha)
    -- el resultado es la tension en decimas de milivoltio (10^-4 V)
    tension_decimas_mv <= producto(N_BITS_PRODUCTO-1 downto N_BITS_ADC);

    -- Para obtener la temperatura, hay que multiplicar la tension 
    -- por el factor de conversion del sensor: (0.1 K/mV) = (100 K/V)
    -- En una decima de mV: 10^-4 V * 100 K/V = 10^-2 K

    -- El factor del sensor es: F = 10^-2 K/(10^-4 V)
    -- La temperatura en grados Celsius será: T = tension * F - 273.15
    -- Con aritmética de coma fija, multiplicando todo por 100
    -- para obtener centésimas de grado, será:
    -- T [10^-2 C] = tension * F * 100 - 27315
    -- El factor F queda como 1: F * 100 = 10^-2 * 100 = 1

    -- Por tanto, para obtener la temperatura en centésimas de Celsius,
    -- solo hay que restar 27315 a la temperatura en décimas de mV.
    -- Se añade un bit más para el signo
    celsius_centesimas <= signed('0' & tension_decimas_mv) - to_signed(27315, N_BITS_TEMP);

    -- Se recorta la señal de salida a 16 bits, suficientes para representar
    -- todo el rango de tension (0 a 5 V)
    centesimas_celsius <= resize(celsius_centesimas, N_BITS_CELSIUS);

end architecture;