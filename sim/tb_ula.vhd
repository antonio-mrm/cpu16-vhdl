-- =====================================================================
--  tb_ula.vhd - Testbench da ULA
--
--  Aplica uma tabela de casos (a, b, op) e confere o resultado e a
--  flag zero com assert. No fim imprime quantos casos falharam.
--
--  ModelSim (na pasta do projeto):
--    vlib work
--    vcom -2008 rtl/ula.vhd sim/tb_ula.vhd
--    vsim -c tb_ula -do "run -all; quit"
--  Para ver as formas de onda, rode sem "-c" e use "add wave *".
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ula is
end entity tb_ula;

architecture sim of tb_ula is

  signal a, b, s : std_logic_vector(15 downto 0);
  signal op      : std_logic_vector(2 downto 0);
  signal zero    : std_logic;

  type caso_t is record
    a, b     : std_logic_vector(15 downto 0);
    op       : std_logic_vector(2 downto 0);
    esperado : std_logic_vector(15 downto 0);
    zero     : std_logic;
    nome     : string(1 to 24);
  end record;

  type tabela_t is array (natural range <>) of caso_t;

  constant CASOS : tabela_t := (
    -- ADD
    (x"0005", x"0003", "000", x"0008", '0', "ADD 5 + 3               "),
    (x"0005", x"FFFD", "000", x"0002", '0', "ADD 5 + (-3)            "),
    (x"0003", x"FFFD", "000", x"0000", '1', "ADD 3 + (-3) = 0, zero  "),
    (x"FFFF", x"0001", "000", x"0000", '1', "ADD FFFF + 1 da a volta "),
    -- SUB
    (x"000A", x"0004", "001", x"0006", '0', "SUB 10 - 4              "),
    (x"0004", x"000A", "001", x"FFFA", '0', "SUB 4 - 10 = -6         "),
    (x"1234", x"1234", "001", x"0000", '1', "SUB iguais -> zero (BEQ)"),
    -- AND / OR (bit a bit)
    (x"F0F0", x"FF00", "010", x"F000", '0', "AND bit a bit           "),
    (x"F0F0", x"0F0F", "010", x"0000", '1', "AND sem bits comuns     "),
    (x"F0F0", x"0F00", "011", x"FFF0", '0', "OR bit a bit            "),
    (x"0000", x"0000", "011", x"0000", '1', "OR de zeros             "),
    -- SLT (com sinal)
    (x"0002", x"0005", "100", x"0001", '0', "SLT 2 < 5               "),
    (x"0005", x"0002", "100", x"0000", '1', "SLT 5 < 2 falso         "),
    (x"FFFF", x"0001", "100", x"0001", '0', "SLT -1 < 1 (sinal)      "),
    (x"0001", x"FFFF", "100", x"0000", '1', "SLT 1 < -1 falso        "),
    (x"0007", x"0007", "100", x"0000", '1', "SLT iguais falso        "),
    -- Códigos não usados
    (x"1234", x"5678", "111", x"0000", '1', "op 111 nao usado        ")
  );

begin

  dut : entity work.ula
    port map (a => a, b => b, op => op, s => s, zero => zero);

  estimulos : process
    variable falhas : natural := 0;
  begin
    for i in CASOS'range loop
      a  <= CASOS(i).a;
      b  <= CASOS(i).b;
      op <= CASOS(i).op;
      wait for 10 ns;

      if s /= CASOS(i).esperado or zero /= CASOS(i).zero then
        falhas := falhas + 1;
        report "FALHOU: " & CASOS(i).nome &
               "  s=" & to_hstring(s) & " (esperado " & to_hstring(CASOS(i).esperado) & ")" &
               "  zero=" & std_logic'image(zero)
          severity error;
      else
        report "ok:     " & CASOS(i).nome severity note;
      end if;
    end loop;

    if falhas = 0 then
      report "=== ULA: todos os " & integer'image(CASOS'length) & " casos passaram ===" severity note;
    else
      report "=== ULA: " & integer'image(falhas) & " caso(s) falharam ===" severity failure;
    end if;
    wait;
  end process;

end architecture sim;
