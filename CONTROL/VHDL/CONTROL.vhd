-- Este modulo resuelve el control y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_CONTROL hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity CONTROL is
    generic(
        CLK_FREC : integer
        
    );
    PORT(
        clk : in std_logic;
        reset_n : in std_logic := '1';   -- conexion a reset activo a nivel bajo 
        
        -- Datos de adquisición
        bus_temperatura : in t_bus_temperatura;

        -- Datos del parser (COMUNICACIONES RX)
        bus_control_data_rx : in t_bus_control_data_rx;
        modo_valid : in std_logic;
        pwm_valid : in std_logic;
        pid_valid : in std_logic;

        -- DATOS PARA ENVIAR (COMUNICACIONES TX)
        bus_datos_graficos_tx : out t_bus_datos_graficos_tx;

        -- SALIDA AL MÓDULO PWM (Conectar a 't_on' en el Top Level)
        pwm_t_on : out unsigned(N_BITS_PWM-1 downto 0)

    );
END entity;

architecture Behavioral of CONTROL is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    -- Registros para almacenar lo que llega desde el PC
    signal modo_reg       : std_logic := '0'; -- '0' = lazo abierto, '1' = lazo cerrado
    signal pwm_manual_reg : std_logic_vector(N_BITS_PWM-1 downto 0) := (others => '0');
    signal consigna_reg   : signed(N_BITS_CELSIUS-1 downto 0) := to_signed(2000, N_BITS_CELSIUS); -- 20.00C por defecto

    signal pwm_t_on_aplicado : unsigned(N_BITS_PWM-1 downto 0);
    signal pwm_t_on_lazo_cerrado : unsigned(N_BITS_PWM-1 downto 0);
    signal pwm_t_on_lazo_abierto : unsigned(N_BITS_PWM-1 downto 0);
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        TODO_O_NADA_inst : entity work.TODO_O_NADA
            port map (
                clk => clk,
                reset => not reset_n,

                temp_actual => bus_temperatura.centesimas_centigrado,
                consigna => consigna_reg,

                t_on => pwm_t_on_lazo_cerrado
            );



        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        
        -- Seleccion de PWM segun el modo de trabajo
        pwm_t_on_aplicado <= pwm_t_on_lazo_cerrado when modo_reg = '1' else pwm_t_on_lazo_abierto;
        pwm_t_on_lazo_abierto <= unsigned(pwm_manual_reg);

        -- Salida PWM
        pwm_t_on <= pwm_t_on_aplicado;

        -- Datos para graficar
        bus_datos_graficos_tx.consigna <= consigna_reg;
        bus_datos_graficos_tx.bus_temperatura <= bus_temperatura;
        bus_datos_graficos_tx.error <= (consigna_reg - bus_temperatura.centesimas_centigrado);
        bus_datos_graficos_tx.pwm <= std_logic_vector(pwm_t_on_aplicado);
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        
    process(clk, reset_n)
    
    begin
        if not reset_n = '1' then
            modo_reg       <= '0'; -- Por seguridad, arranca en manual
            pwm_manual_reg <= (others => '0');
            consigna_reg   <= to_signed(2000, N_BITS_CELSIUS);
            
        elsif rising_edge(clk) then
            -- Actualiza los registros solo cuando el parser indica un dato válido
            if modo_valid = '1' then
                modo_reg <= bus_control_data_rx.modo; 
            end if;
            
            if pwm_valid = '1' then
                pwm_manual_reg <= bus_control_data_rx.pwm_lazo_abierto;
            end if;
            
            if pid_valid = '1' then
                consigna_reg <= bus_control_data_rx.consigna;
            end if;
        end if;
    end process;
        
end architecture;