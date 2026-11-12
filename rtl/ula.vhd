-- =====================================================================
--  ula.vhd - Unidade Lógica e Aritmética de 16 bits
--
--  Código da operação (op), igual aos 3 bits baixos do opcode tipo R:
--    000  ADD  : s = a + b    (também usado por ADDI, LD, ST e alvo do desvio)
--    001  SUB  : s = a - b    (também usado por BEQ/BNE para comparar)
--    010  AND  : s = a AND b  (bit a bit)
--    011  OR   : s = a OR b   (bit a bit)
--    100  SLT  : s = 1 se a < b (com sinal), senão 0
--    101..111  : s = 0 (não usados)
--
--  zero = '1' quando o resultado é 0 (BEQ desvia se zero = '1' após SUB;
--  BNE desvia se zero = '0').
--  Overflow é ignorado (soma/subtração em complemento de 2 dão a volta).
--  Circuito puramente combinacional.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
  port (
    a    : in  std_logic_vector(15 downto 0);
    b    : in  std_logic_vector(15 downto 0);
    op   : in  std_logic_vector(2 downto 0);
    s    : out std_logic_vector(15 downto 0);
    zero : out std_logic
  );
end entity ula;

architecture rtl of ula is
  -- Constantes com os códigos da operação (deixam o código legível)
  constant OP_ADD : std_logic_vector(2 downto 0) := "000";
  constant OP_SUB : std_logic_vector(2 downto 0) := "001";
  constant OP_AND : std_logic_vector(2 downto 0) := "010";
  constant OP_OR  : std_logic_vector(2 downto 0) := "011";
  constant OP_SLT : std_logic_vector(2 downto 0) := "100";

  signal resultado : std_logic_vector(15 downto 0);
begin

  process (a, b, op)
  begin
    case op is
      when OP_ADD =>
        resultado <= std_logic_vector(signed(a) + signed(b));

      when OP_SUB =>
        resultado <= std_logic_vector(signed(a) - signed(b));

      when OP_AND =>
        resultado <= a and b;

      when OP_OR =>
        resultado <= a or b;

      when OP_SLT =>
        if signed(a) < signed(b) then
          resultado <= x"0001";
        else
          resultado <= x"0000";
        end if;

      when others =>
        resultado <= (others => '0');
    end case;
  end process;

  s    <= resultado;
  zero <= '1' when resultado = x"0000" else '0';

end architecture rtl;
