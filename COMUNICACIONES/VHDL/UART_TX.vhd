library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity UART_TX is
    port(
        clk         : in  std_logic;                    
        rst         : in  std_logic;

        baud_ce     : in  std_logic;    -- pulso de habilitación para cumplir los baudios

        -- Interfaz con SECUENCIADOR
        tx_start    : in  std_logic;  -- orden de empezar a transmitir (pulso)
        tx_byte     : in  std_logic_vector(7 downto 0);
        tx_ready    : out std_logic;  -- '1' si está libre, '0' si está ocupado
        tx_done     : out std_logic;  -- pulso de fin de transmisión (1 byte enviado)

        -- Salida
        tx_out      : out std_logic  -- bit serie de salida
    );
END entity;

architecture Behavioral of UART_TX is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    type estados is (REPOSO, BIT_START, DATOS, BIT_STOP);
    signal estado : estados := REPOSO;

    signal registro_datos   : std_logic_vector(7 downto 0) := (others => '0');
    signal indice_bit  : integer range 0 to 7 := 0;
    signal salida   : std_logic := '1';
    
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
         
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        tx_out   <= salida;
        tx_ready <= '1' when (estado = REPOSO) else '0';
        
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
        process(clk)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
        
        begin
        if rising_edge(clk) then
            if rst = '1' then
                estado    <= REPOSO;
                salida  <= '1';
                indice_bit <= 0;
                tx_done   <= '0';
            else
                tx_done <= '0'; -- El pulso de "hecho" dura solo un ciclo de reloj

                case estado is
                    
                    when REPOSO =>
                        salida <= '1'; -- Línea en alto
                        if tx_start = '1' then
                            registro_datos <= tx_byte; -- Capturamos el byte inmediatamente
                            estado   <= BIT_START;
                        end if;

                    when BIT_START =>
                        -- Esperamos al pulso del generador de baudios para cambiar la línea
                        if baud_ce = '1' then
                            salida  <= '0'; -- Bit de Start (0)
                            indice_bit <= 0;
                            estado    <= DATOS;
                        end if;

                    when DATOS =>
                        if baud_ce = '1' then
                            salida <= registro_datos(indice_bit); -- Mandamos el bit actual (LSB primero)
                            
                            if indice_bit = 7 then
                                estado <= BIT_STOP;
                            else
                                indice_bit <= indice_bit + 1;
                            end if;
                        end if;

                    when BIT_STOP =>
                        if baud_ce = '1' then
                            salida <= '1'; -- Bit de Stop (1)
                            tx_done  <= '1'; -- Avisamos de que el byte se ha enviado
                            estado   <= REPOSO;
                        end if;

                    when others =>
                        estado <= REPOSO;
                end case;
            end if;
        end if;
    end process;
        
end architecture;