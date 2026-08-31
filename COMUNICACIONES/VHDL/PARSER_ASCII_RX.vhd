library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity PARSER_ASCII_RX is
    port(
        clk : in std_logic;
        rst : in std_logic;

        -- INTERFAZ CON BUFFER_RX
        buffer_ready    : in  std_logic; -- '1' cuando el buffer tiene un mensaje
                                         -- completo y esta listo para ser leido

        -- byte combinacional del buffer segun el indice que solicitemos
        in_byte         : in  std_logic_vector(7 downto 0);

        -- indice solicitado
        indice_out_byte : out integer range 0 to N_BYTES_BUFFER_RX-1;

        liberar_buffer  : out std_logic; -- para que llegue un nuevo mensaje cuando
                                         -- el parser termine


        -- INTERFAZ CON EL SISTEMA DE CONTROL
        control_rx     : out t_bus_control_data_rx;  -- bus con todas las señales leidas 
        
        -- pulsos de habilitación (1 ciclo de reloj) para indicar qué dato es válido
        modo_valid      : out std_logic; 
        pwm_valid       : out std_logic; 
        pid_valid       : out std_logic  
    );
end entity;

architecture Behavioral of PARSER_ASCII_RX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------

    type t_estado is (
        ESPERAR_BUFFER, 
        EVALUAR_ETIQUETA,
        SALTAR_HASTA_ESPACIO,
        LEER_NUMERO,
        GUARDAR_PARAMETRO,
        FIN_MENSAJE
    );
    signal estado : t_estado := ESPERAR_BUFFER;


    type t_comando is (CMD_MODO, CMD_PWM, CMD_PID, CMD_NINGUNO);
    signal comando_actual : t_comando := CMD_NINGUNO;


    signal indice_interno  : integer range 0 to N_BYTES_BUFFER_RX-1 := 0;
    
    signal acumulador      : integer := 0; 
    signal es_negativo     : std_logic := '0';
    signal indice_pid    : integer range 0 to 3 := 0;

    -- Registro de salidas
    signal reg_out : t_bus_control_data_rx := (
        modo => '0', 
        pwm_lazo_abierto => (others => '0'), 
        kp => (others => '0'), 
        ki => (others => '0'), 
        kd => (others => '0'), 
        consigna => (others => '0')
    );
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        indice_out_byte <= indice_interno;
        control_rx <= reg_out;
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk, rst)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            variable valor : integer; -- para introducir el signo en el ciclo presente

            begin
            if rst = '1' then
                estado         <= ESPERAR_BUFFER;
                liberar_buffer <= '0';
                modo_valid     <= '0';
                pwm_valid      <= '0';
                pid_valid      <= '0';
                indice_interno <= 0;
                acumulador     <= 0;
                es_negativo    <= '0';
                indice_pid   <= 0;
                comando_actual <= CMD_NINGUNO;

            elsif rising_edge(clk) then
                -- pulsos, a 0 por defecto salvo que se diga lo contrario
                liberar_buffer <= '0';
                modo_valid     <= '0';
                pwm_valid      <= '0';
                pid_valid      <= '0';

                case estado is

                    when ESPERAR_BUFFER =>
                        if buffer_ready = '1' then
                            indice_interno <= 0;
                            estado <= EVALUAR_ETIQUETA;
                        end if;

                    -- Con el primer carácter de la etiqueta de comando podemos identificar
                    -- qué comando es
                    when EVALUAR_ETIQUETA =>
                        case in_byte is
                            when x"31" =>      -- '1' (MODO)
                                comando_actual <= CMD_MODO;
                                estado <= SALTAR_HASTA_ESPACIO;
                                
                            when x"32" =>      -- '2' (PWM)
                                comando_actual <= CMD_PWM;
                                estado <= SALTAR_HASTA_ESPACIO;
                                
                            when x"33" =>      -- '3' (PID)
                                comando_actual <= CMD_PID;
                                estado <= SALTAR_HASTA_ESPACIO;
                                
                            when others =>
                                estado <= FIN_MENSAJE;   -- etiqueta no reconocida, abortar
                        end case;
                        
                        indice_interno <= indice_interno + 1;


                    -- Ignorar el resto de caracteres de la etiqueta de comando
                    when SALTAR_HASTA_ESPACIO =>
                        if in_byte = x"20" then -- 0x20 -> espacio
                            acumulador   <= 0;
                            es_negativo  <= '0';
                            indice_pid <= 0;
                            estado       <= LEER_NUMERO;
                        end if;
                        indice_interno <= indice_interno + 1;

                    -- Reconstruir un numero leyendo cada uno de sus digitos
                    -- (ignorando punto decimal) y asignandole a cada digito
                    -- su peso posicional, hasta encontrar espacio o nueva linea
                    when LEER_NUMERO =>
                        -- Espacio o \n ; numero completado
                        if in_byte = x"20" or in_byte = x"0A" then
                            estado <= GUARDAR_PARAMETRO;

                        elsif in_byte = x"2B" then -- '+'
                            es_negativo <= '0';
                            indice_interno <= indice_interno + 1;

                        elsif in_byte = x"2D" then -- '-'
                            es_negativo <= '1';
                            indice_interno <= indice_interno + 1;

                        elsif in_byte = x"2E" then -- '.' (Punto Decimal)
                            indice_interno <= indice_interno + 1;

                        -- Si es un digito ('0' a '9'), acumular su valor y peso
                        elsif (unsigned(in_byte) >= x"30") and (unsigned(in_byte) <= x"39") then
                            -- para pasar de ascii a bcd simplemente restamos 0x30 (el cero).
                            -- Por cada digito que haya, multiplicamos lo anterior por 10.
                            -- En un numero de 3 cifras, leyendo de izquierda a derecha,
                            -- el primero es potencia 2 (10^2), el 
                            -- segundo potencia 1, el tercero potencia 0.
                            acumulador <= (acumulador * 10) + to_integer(unsigned(in_byte) - x"30");
                            indice_interno <= indice_interno + 1;
                        
                        -- Carácter inválido, saltar
                        else
                            indice_interno <= indice_interno + 1;
                        end if;


                    -- Asignar el numero a su señal correspondiente, segun la etiqueta
                    when GUARDAR_PARAMETRO =>
                        -- Aplicar signo
                        if es_negativo = '1' then
                            valor := -acumulador;
                        else
                            valor := acumulador;
                        end if;

                        if comando_actual = CMD_MODO then
                            if valor = 0 then 
                                reg_out.modo <= '0'; 
                            else 
                                reg_out.modo <= '1'; 
                            end if;
                            
                        elsif comando_actual = CMD_PWM then
                            reg_out.pwm_lazo_abierto <= std_logic_vector(to_unsigned(valor, 10));
                            
                        elsif comando_actual = CMD_PID then
                            case indice_pid is
                                when 0 => reg_out.kp <= std_logic_vector(to_signed(valor, 16));
                                when 1 => reg_out.ki <= std_logic_vector(to_signed(valor, 16));
                                when 2 => reg_out.kd <= std_logic_vector(to_signed(valor, 16));
                                when 3 => reg_out.consigna <= to_signed(valor, 16);
                            end case;
                        end if;

                        -- Comprobar si hemos llegado al final del mensaje
                        if in_byte = x"0A" then
                            estado <= FIN_MENSAJE;
                        else
                            -- Preparar para el siguiente número
                            -- (solo ocurrira en comando PID, que tiene varios numeros)
                            indice_pid   <= indice_pid + 1;
                            acumulador     <= 0;
                            es_negativo    <= '0';
                            indice_interno <= indice_interno + 1; 
                            estado         <= LEER_NUMERO;
                        end if;

                    -- Generar el pulso valid que toque y liberar buffer
                    when FIN_MENSAJE =>
                        if comando_actual = CMD_MODO then
                            modo_valid <= '1';
                        elsif comando_actual = CMD_PWM then
                            pwm_valid <= '1';
                        elsif comando_actual = CMD_PID then
                            pid_valid <= '1';
                        end if;
                        
                        liberar_buffer <= '1';
                        estado <= ESPERAR_BUFFER;

                    when others =>
                        estado <= ESPERAR_BUFFER;

                end case;
            end if;
    end process;  
end architecture;