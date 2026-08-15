-- Este modulo resuelve la adquisicion de datos y es modular: no conecta directamente
-- con el hardware externo.
-- Este modulo es el que se conectará con el resto de áreas del proyecto.
-- TOP_LEVEL_ENTITY_ADC hace uso de este módulo para conectar con
-- el hardware de la tarjeta y probarlo.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.CONFIG_PROYECTO.all;

entity ADQUISICION_DE_DATOS is
    PORT(
            clk_50 : in std_logic;  -- conexion al reloj de 50 Mhz
            reset_n : in std_logic;   -- conexion a reset (mucho cuidado, debe ser un reset de logica inversa, activo a nivel bajo)
                        
            -- salidas de datos para otros modulos
            clk_adc : out std_logic;
            pll_locked_out : out std_logic; -- para mantener sistemas a reset hasta que el pll sea estable
            bus_temperatura : out t_bus_temperatura           
    );
END entity;

architecture Behavioral of ADQUISICION_DE_DATOS is

    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    
    signal adc_clk : std_logic;
    
    signal ch1: std_logic_vector(N_BITS_ADC-1 downto 0);
    signal adc_valid: std_logic;
    
    signal ch1_milivoltios : std_logic_vector(N_BITS_MILIVOLTIOS-1 downto 0);
    signal ch1_centesimas_celsius : signed(N_BITS_CELSIUS-1 downto 0);
    signal ch1_filtrado: std_logic_vector(N_BITS_ADC_OVERSAMPLING-1 downto 0);
    
    signal pll_locked : std_logic;
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        ADC_DRIVER0 : entity work.ADC_DRIVER
            port map(
                        clk_in => clk_50,
                        pll_c0_clk => adc_clk,
                        reset_n => reset_n,
                        ch1_data => ch1,
                        adc_valid => adc_valid,
                        pll_locked_out => pll_locked
                        
                        );
                        
        MEDIA_MOVIL0 : entity work.MEDIA_MOVIL 
                            generic map(N_BITS_DATO => N_BITS_ADC, 
                                            N_BITS_MUESTRAS => BITS_MUESTRAS_MEDIA_MOVIL,
                                            VENTANA_TIEMPO_MS => V_TIEMPO_MEDIA_MOVIL,
                                            CLK_FREC => PLL_C0_FREC)
                            port map(
                                        clk => adc_clk,
                                        reset => not reset_n, 
                                        dato_listo => adc_valid,
                                        dato => ch1,
                                        dato_promediado => ch1_filtrado);
                                                
        ADC_A_MV0 :    entity work.ADC_A_MV
                                generic map(
                                    N_BITS_ADC => N_BITS_ADC_OVERSAMPLING
                                )
                                port map(
                                            cuentas_ADC => ch1_filtrado, -- señal de 16 bits de MEDIA_MOVIL
                                            conversion_mv => ch1_milivoltios -- 13 bits (0 a 5000 mV)
                                            );

        ADC_A_CELSIUS0 : entity work.ADC_A_CELSIUS
            generic map (
                N_BITS_ADC => N_BITS_ADC_OVERSAMPLING
            )
            port map (
                cuentas_ADC => ch1_filtrado, -- señal de 16 bits de MEDIA_MOVIL
                centesimas_celsius => ch1_centesimas_celsius -- 16 bits signed (ej: 2504 = 25.04 °C)
            );

                                            
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
                                
        -- asignacion de salidas del modulo
        bus_temperatura.milivoltios <= ch1_milivoltios;
        bus_temperatura.centesimas_celsius <= ch1_centesimas_celsius;
        
        clk_adc <= adc_clk;
        pll_locked_out <= pll_locked;
        
end architecture;