library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Implementado el diezmado. En lugar de añadir un dato a la velocidad del reloj 
-- (PLL, 10MHz), se reduce la frecuencia mediante un contador_diezmado
-- que hace que se recoja un dato cada 312.5 microsegundos (3125*1/(10*10^6))
-- este tiempo multiplicado por los 64 DATOS (2^6_BITS_MUESTRAS), hace un total 
-- de 20 ms para rellenar el array de datos completo
-- 20 ms corresponde a una frecuencia de 50Hz, la de la red electrica en España
-- por tanto de este modo se implementa un filtrado digital del ruido electico de 50hz
-- la ventana de tiempo (los ultimos datos que se tienen en cuenta para 
-- la media, 64 datos en los ultimos 20 ms), coincide exactamente
-- con el periodo de la onda ruidosa de 50hz. 
-- Por tanto, la muestra siempre contiene el semiperiodo positivo y el negativo
-- de la onda. Al hacer la media se anula uno con otro y se filtra el ruido
entity MEDIA_MOVIL is
    GENERIC(
        N_BITS_DATO: integer := 12; -- tamaño del dato a promediar/filtrar
        N_BITS_MUESTRAS : integer := 8; -- si se desean 64 muestras -> 6 bits (2^6=64)
        VENTANA_TIEMPO_MS: integer := 20;   -- en milisegundos
        CLK_FREC: integer := 25E6   -- frecuencia del reloj de entrada, en hercios
        );
    PORT(
        clk : in std_logic; -- reloj de entrada
        reset: in std_logic := '0'; -- reset activo a nivel alto

        dato_listo: in std_logic := '0';    -- se debe recibir un pulso cada vez que el 
                                            -- dato se haya actualizado, para registrar 
                                            -- una nueva muestra
                                            
        dato: in std_logic_vector(N_BITS_DATO-1 downto 0);   -- dato de entrada
        
        -- dato de salida, promediado/filtrado
        dato_promediado: out std_logic_vector(N_BITS_DATO + (N_BITS_MUESTRAS/2) - 1 downto 0)
        );
END entity;

architecture Behavioral of MEDIA_MOVIL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    -- debe ser potencia de 2, 2^4=16
    constant NUM_MUESTRAS : integer := 2**N_BITS_MUESTRAS;
    
    type array_datos is array(NUM_MUESTRAS-1 downto 0)
    of std_logic_vector(N_BITS_DATO-1 downto 0);
    
    signal DATOS : array_datos := (others => (others => '0'));
    
    -- 2^12*16 = 2^12*2^4 = 2^16 ; 
    -- PARA SUMAR 16 DATOS (2^4) DE 12 BITS HACEN FALTA 12+4 BITS
    -- 2^n_bits*2^4 = n_bits + 4
    constant BITS_SUMA : integer := N_BITS_DATO + N_BITS_MUESTRAS;
    signal SUMA : unsigned(BITS_SUMA-1 downto 0);
    
    constant FRECUENCIA_MUESTREO : integer := (NUM_MUESTRAS*1000)/(VENTANA_TIEMPO_MS);
    signal PULSE_FREC_MUESTREO_HZ : std_logic := '0';
    signal capturar_dato : boolean := false;

    -- OVERSAMPLING
    constant BITS_GANADOS : integer := N_BITS_MUESTRAS / 2;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        GENERADOR_PULSOS_FRECUENCIA_MUESTREO_HZ : entity work.GENERADOR_PULSOS
            generic map(CLK_FREC => CLK_FREC, 
                        PULSE_FREC => FRECUENCIA_MUESTREO
                        )
            port map(
                     CLK => clk,
                     RESET => reset,
                     PULSE => PULSE_FREC_MUESTREO_HZ
                    );
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- SUMA(15 downto 4) para 12 bits y 16 muestras
        -- dividir entre NUM_MUESTRAS.
        -- Si es 16, equivale a quedarse con los BITS_SUMA-4 bits mas significativos.
        -- Oversampling: con 2^4 muestras, ganas 2 bits,
        -- que equivale a quedarse con los BITS_SUMA-2
        dato_promediado <= std_logic_vector(SUMA(BITS_SUMA-1 downto BITS_GANADOS));
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk)
            ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            variable suma_var : unsigned(BITS_SUMA-1 downto 0) := (others=>'0');
            begin           
                if rising_edge(clk) then
                
                    if reset = '1' then
                        
                        suma_var := (others => '0');
                        DATOS <= (others => (others => '0'));
                        SUMA <= (others => '0');
                        capturar_dato <= false;
                        
                    else
                        
                        if PULSE_FREC_MUESTREO_HZ = '1' then
                        
                            capturar_dato <= true;
                            
                        end if;
                        
                        if dato_listo = '1' and capturar_dato = true then
                        
                            -- desplazar los datos a la izquierda.
                            -- El nuevo dato entra a la posicion 0
                            for i in NUM_MUESTRAS-1 downto 1 loop
                                -- el dato que se va a perder, es el mas significativo
                                -- (mayor indice, a la izquierda del todo)
                                DATOS(i) <= DATOS(i-1); 
                            end loop;
                            DATOS(0) <= dato;
                            
                            -- resize(dato, bits) automaticamente recorta o añade ceros
                            -- a la izquierda a un dato para que acabe siendo el tamaño
                            -- especificado. Muy util para sumar un dato pequeño a uno 
                            -- mayor sin tener que estar 
                            -- concatenando bits '0' a la izquierda
                            
                            -- añadimos a la suma el dato nuevo y
                            -- restamos el mas antiguo (ultima posicion)
                            suma_var := suma_var
                             + resize(unsigned(dato), BITS_SUMA)
                             - resize(unsigned(DATOS(NUM_MUESTRAS-1)), BITS_SUMA);
                            
                            SUMA <= suma_var;
                            capturar_dato <= false;
                            
                        end if;
                    
                    end if;
                            
                end if;
                
        end process;
        
end architecture;