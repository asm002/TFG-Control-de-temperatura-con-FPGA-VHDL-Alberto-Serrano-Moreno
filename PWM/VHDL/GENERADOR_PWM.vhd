library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity GENERADOR_PWM is
    generic(
		CLK_FREC : integer;
		FREC : integer;
		N_BITS : integer
        );
    port(
		clk : in std_logic;
        reset : in std_logic := '0';

		-- numero de periodos a nivel alto
		t_on : in std_logic_vector(N_BITS-1 downto 0);
		pwm_out : out std_logic
    );
end entity;

architecture Behavioral of GENERADOR_PWM is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
	-- Contador para desplazarse desde el inicio del periodo hasta el final.
	-- Si es de 12 bits:
	-- 0 corresponde al principio del periodo.
	-- 511 a la mitad (semiperiodo)
	-- 1023 al final
	constant N_MUESTRAS : integer := 2**(N_BITS);	-- 1024
	signal fase : unsigned(N_BITS-1 downto 0) := (others => '0');

	-- T_muestreo = T_pwm / N_muestras
	-- f_muestreo = 1/T_muestreo = N_muestras / T_pwm = N_muestras/(1/f_pwm)
	-- = N_muestras*F_pwm = F_muestreo
	constant FRECUENCIA_MUESTREO : integer := N_MUESTRAS * FREC;
	signal pulso_muestreo : std_logic := '0';
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        GENERADOR_PULSOS0 : entity work.GENERADOR_PULSOS
			generic map (
				CLK_FREC => CLK_FREC,
				PULSE_FREC => FRECUENCIA_MUESTREO
			)
			port map (
				CLK => clk,
				RESET => reset,
				PULSE => pulso_muestreo
			);

        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
				if rising_edge(clk) then
					if reset = '1' then	-- reset síncrono
						fase <= (others => '0');
						pwm_out <= '0';
					else
						-- solo actuamos en los flancos en los que haya pulso
						if pulso_muestreo = '1' then
							-- siempre en cada pulso avanzamos en fase
							-- el contador no tiene reinicio,
							-- al desbordar, vuelve a cero.
							fase <= fase + 1;
							if fase < unsigned(t_on) then
								pwm_out <= '1';	-- TON
							else
								pwm_out <= '0';	-- TOFF
							end if;
							-- El periodo esta formado por 2^N muestras (1024).
							-- El numero de muestras en alto puede tomar:
							-- (0 ... 2^N), es decir, se necesitan 2^N + 1 valores (1025),
							-- para poder representar el caso de todos las muestras en alto.
							-- Sin embargo, t_on dispone únicamente de N (10) bits,
							-- por lo que sólo puede representar 2^N (1024) valores.
							-- Se reserva el valor máximo, 2^N - 1 (1023), como saturación al 100%
							if unsigned(t_on) = N_MUESTRAS-1 then
								pwm_out <= '1';	-- TON
							end if;
						end if;
					end if;
                end if;
        end process;
        
end architecture;