-- Toma un vector de entradas y las sincroniza registrándolas con un doble biestable para cada una
-- Uso: sincronizar entradas asíncronas (switches) con el reloj

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SINCRONIZADOR_ENTRADAS is
    generic(
        N_ENTRADAS : integer
        );
    port(
        clk : in std_logic;
        reset : in std_logic;

        entradas : in std_logic_vector(N_ENTRADAS-1 downto 0);
        entradas_sincronizadas : out std_logic_vector(N_ENTRADAS-1 downto 0)
    );
end entity;

architecture Behavioral of SINCRONIZADOR_ENTRADAS is
    ------------------------------------------------------------------
    -- DEFINICION DE SEÑALES INTERNAS, TIPOS Y CONSTANTES
    ------------------------------------------------------------------
    signal sync1 : std_logic_vector(N_ENTRADAS-1 downto 0) := (others => '0');
    signal sync2 : std_logic_vector(N_ENTRADAS-1 downto 0) := (others => '0');
    
    begin
        ------------------------------------------------------------------
        -- MAPEO DE ENTIDADES INTERNAS
        ------------------------------------------------------------------
        
        
        ------------------------------------------------------------------
        -- LOGICA COMBINACIONAL ; ASIGNACIONES DIRECTAS
        ------------------------------------------------------------------
        entradas_sincronizadas <= sync2;
        
        ------------------------------------------------------------------
        -- LOGICA SECUENCIAL ; PROCESOS
        ------------------------------------------------------------------
        process(clk)
        ------------------------------------------------------------------
        -- DEFINICION DE VARIABLES, TIPOS Y CONSTANTES
        ------------------------------------------------------------------
            
            begin           
                if rising_edge(clk) then
                    if reset = '1' then
                        sync1 <= (others => '0');
                        sync2 <= (others => '0');
                    else
                        sync1 <= entradas;
                        sync2 <= sync1;
                    end if;
                end if;
        end process;
        
end architecture;