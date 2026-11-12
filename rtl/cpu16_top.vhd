-- =====================================================================
--  cpu16_top.vhd
--  Entidade de topo: liga a CPU aos pinos da DE2-115.
--
--  ESQUELETO (Etapa 0): por enquanto só declara as portas e deixa os
--  displays apagados e os LEDs desligados, para o projeto já compilar
--  no Quartus. A CPU e os periféricos entram aqui nas Etapas 3 e 5.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu16_top is
  port (
    CLOCK_50 : in  std_logic;                     -- 50 MHz (debouncer)
    KEY      : in  std_logic_vector(3 downto 0);  -- ativo baixo; KEY0=clock, KEY1=reset
    SW       : in  std_logic_vector(17 downto 0); -- SW17 = RDM / ULA
    LEDG     : out std_logic_vector(8 downto 0);  -- estado da UC
    HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0); -- PC
    HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0)  -- RDM ou ULA
  );
end entity cpu16_top;

architecture rtl of cpu16_top is
begin
  -- Displays da DE2-115 são ativos em nível baixo: "1111111" = apagado
  HEX0 <= (others => '1');
  HEX1 <= (others => '1');
  HEX2 <= (others => '1');
  HEX3 <= (others => '1');
  HEX4 <= (others => '1');
  HEX5 <= (others => '1');
  HEX6 <= (others => '1');
  HEX7 <= (others => '1');

  LEDG <= (others => '0');
end architecture rtl;
