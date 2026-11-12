-- =====================================================================
--  extensor_sinal.vhd - Estende o imediato de 6 bits para 16 bits
--
--  Copia o bit de sinal (bit 5) para os 10 bits de cima, mantendo o
--  valor em complemento de 2:
--    000101 (+5)  -> 0000000000000101 (0x0005)
--    111101 (-3)  -> 1111111111111101 (0xFFFD)
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extensor_sinal is
  port (
    imm6  : in  std_logic_vector(5 downto 0);
    imm16 : out std_logic_vector(15 downto 0)
  );
end entity extensor_sinal;

architecture rtl of extensor_sinal is
begin
  -- resize() em um número com sinal repete o bit de sinal
  imm16 <= std_logic_vector(resize(signed(imm6), 16));
end architecture rtl;
