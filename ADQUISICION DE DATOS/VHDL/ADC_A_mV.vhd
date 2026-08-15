library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity ADC_A_mV is
    GENERIC(
        N_BITS_ADC : integer  -- bits del ADC (se le suman los bits ganados si hay oversampling)
        );
    PORT(
        cuentas_ADC : in std_logic_vector(N_BITS_ADC-1 downto 0);
        conversion_mv : out std_logic_vector(N_BITS_MILIVOLTIOS-1 downto 0)
    );
END entity;

architecture Behavioral of ADC_A_mV is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    constant N_BITS_FACTOR : integer := 3+10;   -- 3 bits para V_ref y 10 bits para 1000
    
    -- multiplicacion de un dato de 12 bits y un dato de 13 bits
    constant N_BITS_PRODUCTO : integer := N_BITS_ADC + N_BITS_FACTOR;
    
    -- desplazamiento de 12 bits al dato anterior
    constant N_BITS_DIVISION : integer := N_BITS_PRODUCTO - N_BITS_ADC;
    
    signal producto : unsigned(N_BITS_PRODUCTO-1 downto 0); 
    signal division : unsigned(N_BITS_DIVISION-1 downto 0); 
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- multiplicacion por 5, la tensión de ref. ; multiplicamos por 1000
        -- para representar del 0 al 5000 y luego en los displays encendemos
        -- el punto decimal en el primer digito, de manera que queda 5,000
        producto <= (unsigned(cuentas_ADC)*to_unsigned(VREFmv, N_BITS_FACTOR));
        
        -- division entre 4096 que equivale a un desplazamiento a la derecha
        -- de 12 bits (2^12=4096) o quedarse con los 13 bits
        -- (25 totales - 12 desplazados y eliminados) mas significativos
        division <= producto(N_BITS_PRODUCTO-1 downto N_BITS_ADC);
        
        conversion_mv <= std_logic_vector(division); -- 13 bits para representar de 0 a 5000
        
        
        
end architecture;