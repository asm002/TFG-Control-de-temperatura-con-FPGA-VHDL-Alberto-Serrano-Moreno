library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Dada una frecuencia de entrada y una deseada, genera un pulso a la frecuencia deseada.
-- Uso: generar procesos lentos a partir de relojes rapidos, sincronos al reloj y sin problemas de cruce de dominios de reloj
entity GENERADOR_PULSOS is
	GENERIC(
		CLK_FREC : integer := 10E6;
		PULSE_FREC : integer := 4
	);
	PORT(
		CLK: in std_logic := '0';
		RESET: in std_logic := '0';
		PULSE: out std_logic := '0'
	);
END entity;

architecture Behavioral of GENERADOR_PULSOS is
	-- < DEFINICION DE SEÑALES INTERNAS, CONSTANTES, TYPES... > --
	
	-- vamos a contar en cada ciclo. Hasta cuanto hay que contar para que hayan pasado 1/4 s (1/PULSE_FREC)?
	-- en 1 segundo, CLK cuenta hasta 10M (CLK_FREC).
	-- en 1/4 s (1/PULSE_FREC), CLK cuenta hasta 10M*1/4 = 2.5M (CLK_FREC*1/PULSE_FREC) = CUENTAS
	-- es decir: CUENTAS = (CLK_FREC*1/PULSE_FREC) = CLK_FREC/PULSE_FREC
	
	constant CUENTAS : integer := CLK_FREC/PULSE_FREC;
	signal cont : integer range 0 to CUENTAS - 1 := 0;
	
	begin
		-- < MAPEO DE ENTIDADES INTERNAS > --
		
		
		-- < MAPEO DE SEÑALES COMBINACIONALES > --
		
		
		-- < PROCESOS > --
		process(CLK)
			-- < DECLARACION DE VARIABLES >
			
			begin			
				if rising_edge(CLK) then
				
					if RESET = '1' then
						cont <= 0;
						PULSE <= '0';
						
					else
						if cont = CUENTAS - 1 then
							cont <= 0;
							PULSE <= '1';
						else
							cont <= cont + 1;
							PULSE <= '0';
						
						end if;
					
					end if;
					
				end if;
		end process;
		
end architecture;