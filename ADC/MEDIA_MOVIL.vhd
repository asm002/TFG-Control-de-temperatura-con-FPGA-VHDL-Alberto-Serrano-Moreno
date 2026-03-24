library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Implementado el diezmado. En lugar de añadir un dato a la velocidad del reloj (PLL, 10MHz), se reduce la frecuencia mediante un contador_diezmado
-- que hace que se recoja un dato cada 312.5 microsegundos (3125*1/(10*10^6))
-- este tiempo multiplicado por los 64 DATOS (2^6_BITS_MUESTRAS), hace un total de 20 ms para rellenar el array de datos completo
-- 20 ms corresponde a una frecuencia de 50Hz, la de la red electrica en España
-- por tanto de este modo se implementa un filtrado digital del ruido electico de 50hz
-- la ventana de tiempo (los ultimos datos que se tienen en cuenta para la media, 64 datos en los ultimos 20 ms), coincide exactamente
-- con el periodo de la onda ruidosa de 50hz. Por tanto, la muestra siempre contiene el semiperiodo positivo y el negativo
-- de la onda. Al hacer la media se anula uno con otro y se filtra el ruido
entity MEDIA_MOVIL is
	GENERIC(
		N_BITS_DATO: integer := 12;
		N_BITS_MUESTRAS : integer := 6
		);
	PORT(
		CLK : in std_logic;
		RESET: in std_logic := '0';
		DATO_LISTO: in std_logic := '0';
		DATO: in std_logic_vector(N_BITS_DATO-1 downto 0);
		DATO_PROMEDIADO: out std_logic_vector(N_BITS_DATO-1 downto 0)
		);
END entity;

architecture Behavioral of MEDIA_MOVIL is
	-- < definicion de señales internas > --
	constant NUM_MUESTRAS : integer := 2**N_BITS_MUESTRAS; -- debe ser potencia de 2, 2^4=16
	type array_datos is array(NUM_MUESTRAS-1 downto 0) of std_logic_vector(N_BITS_DATO-1 downto 0);
	
	signal DATOS : array_datos := (others => (others => '0'));
	
	-- 2^12*16 = 2^12*2^4 = 2^16 ; PARA SUMAR 16 DATOS (2^4) DE 12 BITS HACEN FALTA 12+4 BITS
	-- 2^n_bits*2^4 = n_bits + 4
	constant BITS_SUMA : integer := N_BITS_DATO+N_BITS_MUESTRAS;
	signal SUMA : unsigned(BITS_SUMA-1 downto 0);
	
	--3125*1/(10*10^6)*1000*64 = 20ms (50hz)
	constant ciclos_diezmado : integer := 3125; -- ciclos que deben pasar entre la captura de un dato y el siguiente para que cuando se hayan capturado 64 (el total), hayan pasado 20ms (50hz)
	signal contador_diezmado : integer range 0 to ciclos_diezmado - 1 := 0;
	signal capturar_dato : std_logic := '0';
	
	begin
		-- < mapeo de entidades internas > --
		
		
		-- < mapeo de señales combinacionales > --
		-- SUMA(15 downto 4) para 12 bits y 16 muestras
		DATO_PROMEDIADO <= std_logic_vector(SUMA(BITS_SUMA-1 downto N_BITS_MUESTRAS));	-- dividir entre NUM_MUESTRAS. Si es 16, equivale a quedarse con los BITS_SUMA-4 bits mas significativos
		
		-- < procesos > --
		process(CLK)
			-- < declaracion de variables >
			variable suma_var : unsigned(BITS_SUMA-1 downto 0) := (others=>'0');
			begin			
				if rising_edge(CLK) then
				
					if RESET = '1' then
						
						suma_var := (others => '0');
						DATOS <= (others => (others => '0'));
						SUMA <= (others => '0');
						capturar_dato <= '0';
						contador_diezmado <= 0;
						
					else
					
						if contador_diezmado = ciclos_diezmado - 1 then
							contador_diezmado <= 0;
							capturar_dato <= '1';
						else
							contador_diezmado <= contador_diezmado + 1;
						end if;
						
						if DATO_LISTO = '1' and capturar_dato = '1' then
						
							for i in NUM_MUESTRAS-1 downto 1 loop	-- desplazar los datos a la izquierda. El nuevo dato entra a la posicion 0
								DATOS(i) <= DATOS(i-1);	-- el dato que se va a perder, es el mas significativo (mayor indice, a la izquierda del todo)
							end loop;
							DATOS(0) <= DATO;
							
							-- resize(dato, bits) automaticamente recorta o añade ceros a la izquierda a un dato para que acabe siendo el tamaño especificado. Muy util para sumar un dato pequeño a uno mayor sin tener que estar concatenando bits '0' a la izquierda
							suma_var := suma_var + resize(unsigned(DATO), BITS_SUMA) - resize(unsigned(DATOS(NUM_MUESTRAS-1)), BITS_SUMA);	-- añadimos a la suma el dato nuevo y restamos el mas antiguo (ultima posicion)
							
							SUMA <= suma_var;
							capturar_dato <= '0';
							
						end if;
					
					end if;
							
				end if;
				
		end process;
		
end architecture;