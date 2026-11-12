-- =====================================================================
--  tb_extensor_sinal.vhd - Testa todos os 64 imediatos possíveis
--
--  Para cada imediato de -32 a +31, confere se a saída de 16 bits
--  representa o mesmo número.
--
--  ModelSim:
--    vlib work
--    vcom -2008 rtl/extensor_sinal.vhd sim/tb_extensor_sinal.vhd
--    vsim -c tb_extensor_sinal -do "run -all; quit"
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_extensor_sinal is
end entity tb_extensor_sinal;

architecture sim of tb_extensor_sinal is
  signal imm6  : std_logic_vector(5 downto 0);
  signal imm16 : std_logic_vector(15 downto 0);
begin

  dut : entity work.extensor_sinal port map (imm6 => imm6, imm16 => imm16);

  process
    variable falhas : natural := 0;
  begin
    for v in -32 to 31 loop
      imm6 <= std_logic_vector(to_signed(v, 6));
      wait for 5 ns;
      if to_integer(signed(imm16)) /= v then
        falhas := falhas + 1;
        report "FALHOU: imediato " & integer'image(v) & " virou " & to_hstring(imm16) severity error;
      end if;
    end loop;

    if falhas = 0 then
      report "=== EXTENSOR: os 64 imediatos (-32 a +31) passaram ===" severity note;
    else
      report "=== EXTENSOR: " & integer'image(falhas) & " falha(s) ===" severity failure;
    end if;
    wait;
  end process;

end architecture sim;
