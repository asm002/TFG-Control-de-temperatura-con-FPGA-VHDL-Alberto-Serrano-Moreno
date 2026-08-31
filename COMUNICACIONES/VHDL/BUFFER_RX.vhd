library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity BUFFER_RX is
    -- generic(
        
    --     );
    port(
        clk : in std_logic;
        rst : in std_logic;

        -- INTERFAZ CON UART_RX
        rx_byte   : in std_logic_vector(7 downto 0); -- byte procedente de UART_RX
        rx_ready  : in std_logic;   -- pulso de UART_RX que indica que hay un byte listo
                                    -- para ser almacenado en este modulo

        -- INTERFAZ CON PARSER_ASCII
        buffer_ready : out std_logic;  -- le indica al parser que ya ha llegado un /n
                                       -- y por tanto ya hay un mensaje completo 
                                       -- para interpretar

        liberar_buffer : in std_logic;  -- cuando haya un mensaje completo almacenado,
                                        -- el buffer se bloquea y deja de leer nuevos
                                        -- bytes. En ese estado tan solo sirve como
                                        -- memoria de lectura (out_byte segun el 
                                        -- indice). 
                                        -- Un pulso de esta señal libera el buffer
                                        -- para que empiece con un nuevo mensaje.
                                        -- El parser debera poner a '1' esta entrada
                                        -- cuando termine de interpretar el mensaje.

        -- indice solicitado por el parser para seleccionar el byte
        -- de salida
        indice_out_byte : in integer range 0 to N_BYTES_BUFFER_RX-1;
        
        -- byte de salida para el parser segun el indice solicitado
        out_byte : out std_logic_vector(7 downto 0)

    );
end entity;

architecture Behavioral of BUFFER_RX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    type maquina_estados is (ESPERAR_BYTE, ALMACENAR_BYTE, BUFFER_COMPLETADO, OFRECER_BYTE);
    signal estado : maquina_estados := ESPERAR_BYTE;

    type t_buffer_bytes is array (0 to N_BYTES_BUFFER_RX-1) of std_logic_vector(7 downto 0);
    signal buffer_bytes : t_buffer_bytes := (others => (others => '0'));
    signal indice_buffer : integer range 0 to N_BYTES_BUFFER_RX-1 := 0;
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- Lectura combinacional, siempre disponible. El parser sera el encargado de
        -- leer cuando toque (cuando buffer_ready = '1')
        out_byte <= buffer_bytes(indice_out_byte);
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------

        process(clk, rst)  -- reset asincrono
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin
                if rst = '1' then
                   estado <= ESPERAR_BYTE;
                   buffer_bytes <= (others => (others => '0'));
                   indice_buffer <= 0;

                elsif rising_edge(clk) then 
                    buffer_ready <= '0';

                    case estado is
                        when ESPERAR_BYTE =>
                            if rx_ready = '1' then
                                estado <= ALMACENAR_BYTE;
                            end if;
                        
                        when ALMACENAR_BYTE =>
                            buffer_bytes(indice_buffer) <= rx_byte;

                            -- llega un /n (salto de linea, LF)
                            if rx_byte = x"0A" then
                                indice_buffer <= 0;
                                buffer_ready <= '1';
                                estado <= BUFFER_COMPLETADO;
                            
                            -- no es /n, cuerpo del mensaje
                            -- hasta el penultimo byte (62)
                            elsif indice_buffer < N_BYTES_BUFFER_RX-1 then
                                indice_buffer <= indice_buffer + 1;
                                estado <= ESPERAR_BYTE;
                            
                            -- si llegamos al ultimo byte (63) y no es /n,
                            -- congelamos el indice.
                            -- SI EL BUFFER SE LLENA, SE VA A QUEDAR SOBRESCRIBIENDO 
                            -- BYTES EN LA ULTIMA POSICION HASTA QUE LLEGUE UN LF (/n)
                            else
                                estado <= ESPERAR_BYTE;

                            end if;
                        
                        -- En este estado se queda bloqueado sin leer nuevos
                        -- bytes hasta que el parser termine
                        -- Durante este estado buffer_ready vale '1'
                        when BUFFER_COMPLETADO =>
                            buffer_ready <= '1';
                            if liberar_buffer = '1' then
                                buffer_ready <= '0';
                                estado <= ESPERAR_BYTE;
                            end if;

                        when others =>
                            estado <= ESPERAR_BYTE;
                            buffer_bytes <= (others => (others => '0'));
                            indice_buffer <= 0;

                    end case;
                end if;
        end process;
        
end architecture;