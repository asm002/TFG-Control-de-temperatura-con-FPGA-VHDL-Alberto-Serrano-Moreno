library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_RX is
    generic (
        CLK_FREC : integer := 50E6;
        BAUD_FREC : integer := 115_200
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        
        -- Pin de entrada
        rx_in    : in  std_logic;   -- pin de entrada rx
        
        -- Interfaz con BUFFER_RX
        rx_byte   : out std_logic_vector(7 downto 0); -- byte recibido
        rx_ready  : out std_logic   -- pulso de 1 ciclo indicando que el byte ha sido leido completo
    );
end entity UART_RX;

architecture Behavioral of UART_RX is
    
    -- como la comunicacion uart es asincrona, a la hora de recibir bits, aunque sepamos la velocidad
    -- de baudios, no sabemos en que posicion del bit estamos: si acaba de salir del flanco,
    -- si estamos en el centro, o esta el bit a punto de cambiar al siguiente.
    
    -- en UART_TX no teniamos ese problema porque eramos nosotros quienes generabamos nuestra
    -- señal baud clock enable y eramos sincronos a ella para mandar bits.
    -- aqui sin embargo no estamos alineados en fase, por lo que tenemos que alinearnos
    -- manualmente.
    
    -- para ello, basta capturar el flanco descendente (cambio a  posible bit de start)
    -- y a partir de ahi, siguiendo la frecuencia de baudios, sabremos con exactitud
    -- cuando llegara el siguiente flanco. Estamos alineados.
    
    -- Sin embargo, alinearse justo en un flanco es muy problematico porque a la mas
    -- minima variacion de frecuencia por cualquiera de las partes (pc o fpga),
    -- podriamos meternos en el bit anterior o siguiente. Y si hay una pequeña diferencia entre
    -- la frecuencia de ambos lados, el desfase ira creciendo con cada bit de datos hasta romper
    -- la comunicacion por completo. Es cierto que en cada bit de start de un nuevo byte
    -- el desfase se resetea, pero situarse en el flanco te obliga a no tener nada de desfase
    -- desde el principio.
    
    -- Para solucionarlo, es mejor situarse en el centro de los bits, donde hay mucho
    -- margen tanto a la izquierda como a la derecha.
    -- Una vez detectemos el flanco descendente, habra que contar en cada ciclo de reloj
    -- hasta alcanzar un valor tal que estemos en el centro del bit.
    
    -- Para conseguir todo esto es vital que la frecuencia de reloj sea mucho mayor
    -- que la frecuencia de baudios. De esta manera, el modulo es mucho mas rapido
    -- que los datos que llegan y podemos "trocear" (sobremuestreo, oversampling)
    -- los bits de baud y posicionarnos dentro de ellos.
    
    -- La frecuencia de reloj es el numero de ciclos que hace el sistema por segundo.
    -- Si la multiplicamos por el tiempo que dura un bit de baud, obtenemos el numero 
    -- de ciclos que ocurren dentro de un bit.
    
    -- Si ponemos un contador a contar en cada ciclo, podremos saber en qué parte
    -- del bit estamos.
    
    -- Por este motivo, si la frecuencia de reloj no fuese mucho mayor que la 
    -- f_baud, no podriamos muestrear el bit ni posicionarnos dentro de él.
    
    -- ciclos por bit = frecuencia_clk (veces/segundo) * periodo_baud (segundos) 
    -- = f_clk * (1/f_baud) 
    -- = f_clk/f_baud
    
    -- Ejemplo para 50 MHz y 115200 baudios: 50000000 / 115200 = 434;
    
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    constant CICLOS_POR_BIT : integer := CLK_FREC/BAUD_FREC;

    type maquina_estados is (REPOSO, BIT_START, BITS_DATOS, BIT_STOP);
    signal estado : maquina_estados := REPOSO;

    signal contador_reloj : integer range 0 to CICLOS_POR_BIT - 1 := 0;
    signal indice_bit     : integer range 0 to 7 := 0;
    signal buffer_datos   : std_logic_vector(7 downto 0) := (others => '0');

    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------

        process(clk, rst)  -- reset asincrono
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------

        begin
            if rst = '1' then
                estado         <= REPOSO;
                contador_reloj <= 0;
                indice_bit     <= 0;
                rx_ready       <= '0';
                rx_byte        <= (others => '0');
                buffer_datos   <= (others => '0');
                
            elsif rising_edge(clk) then
                -- Por defecto, el pulso de dato listo siempre a 0
                rx_ready <= '0';
                
                case estado is
                
                    -- ESTADO 1: esperar flanco descendente (posible bit de start)
                    when REPOSO =>
                        contador_reloj <= 0;
                        indice_bit <= 0;
                        
                        if rx_in = '0' then
                            estado <= BIT_START;
                        end if;

                    -- ESTADO 2: situarse en el centro del bit y confirmar que sigue siendo '0'
                    when BIT_START =>
                        -- Hasta que no estemos en el centro del bit no hacemos nada mas
                        if contador_reloj = (CICLOS_POR_BIT - 1) / 2 then 
                            if rx_in = '0' then
                                contador_reloj <= 0; -- reset del contador para la captura
                                                    -- de los datos en el estado siguiente
                                estado         <= BITS_DATOS;
                            else
                                -- era ruido, volvemos a reposo
                                estado         <= REPOSO;
                            end if;
                        else
                            contador_reloj <= contador_reloj + 1;
                        end if;

                    -- ESTADO 3: guardar bits de datos en buffer
                    when BITS_DATOS =>
                        -- Dado que nos situamos en el centro del bit de start en el estado anterior,
                        -- ahora hay que sumar ciclos completos para ir saltando por los consecutivos
                        -- bits de datos.
                        if contador_reloj = CICLOS_POR_BIT - 1 then
                            contador_reloj <= 0;
                            buffer_datos(indice_bit) <= rx_in; -- guardamos el bit recibido
                            
                            -- comprobamos si ya hemos leído los 8 bits
                            if indice_bit = 7 then
                                estado <= BIT_STOP;
                                indice_bit <= 0;
                            else
                                indice_bit <= indice_bit + 1;
                            end if;
                        else
                            contador_reloj <= contador_reloj + 1;
                        end if;

                    -- ESTADO 4: esperar bit de stop
                    when BIT_STOP =>
                        -- Nuevamente avanzamos un ciclo de bit para situarnos en el centro
                        -- del bit de stop.
                        -- Independientemente de si el bit es 1 o hay un error, 
                        -- enviamos el byte al exterior y damos el pulso de validez.
                        if contador_reloj = CICLOS_POR_BIT - 1 then
                            -- no hace falta resetear el buffer porque en el siguiente
                            -- ciclo, antes de mandarse, se habrá sobrescrito con los nuevos bits
                            rx_byte  <= buffer_datos;
                            rx_ready <= '1';
                            contador_reloj <= 0;
                            estado         <= REPOSO;
                        else
                            contador_reloj <= contador_reloj + 1;
                        end if;

                    -- ESTADO 5: Limpieza de un ciclo para asegurar la transición
                    -- when ESPERA =>
                        -- estado <= REPOSO;
                        
                end case;
            end if;
        end process;

end architecture;