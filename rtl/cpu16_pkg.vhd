-- =====================================================================
--  cpu16_pkg.vhd - Definições compartilhadas da CPU
--
--  Opcodes, códigos dos estados da unidade de controle e o tipo do
--  banco de registradores. Todos os outros arquivos usam:
--      use work.cpu16_pkg.all;
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;

package cpu16_pkg is

  -- ---------------- Opcodes (bits 15..12 da instrução) ----------------
  constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant OP_AND  : std_logic_vector(3 downto 0) := "0010";
  constant OP_OR   : std_logic_vector(3 downto 0) := "0011";
  constant OP_SLT  : std_logic_vector(3 downto 0) := "0100";
  constant OP_ADDI : std_logic_vector(3 downto 0) := "0101";
  constant OP_LD   : std_logic_vector(3 downto 0) := "0110";
  constant OP_ST   : std_logic_vector(3 downto 0) := "0111";
  constant OP_BEQ  : std_logic_vector(3 downto 0) := "1000";
  constant OP_BNE  : std_logic_vector(3 downto 0) := "1001";
  constant OP_JMP  : std_logic_vector(3 downto 0) := "1010";

  -- ------------- Estados da unidade de controle (LEDG[3:0]) -----------
  constant E_FETCH     : std_logic_vector(3 downto 0) := x"0";
  constant E_DECODE    : std_logic_vector(3 downto 0) := x"1";
  constant E_EXEC_R    : std_logic_vector(3 downto 0) := x"2";
  constant E_WB_R      : std_logic_vector(3 downto 0) := x"3";
  constant E_EXEC_I    : std_logic_vector(3 downto 0) := x"4";
  constant E_WB_ADDI   : std_logic_vector(3 downto 0) := x"5";
  constant E_MEM_READ  : std_logic_vector(3 downto 0) := x"6";
  constant E_WB_LD     : std_logic_vector(3 downto 0) := x"7";
  constant E_MEM_WRITE : std_logic_vector(3 downto 0) := x"8";
  constant E_BRANCH    : std_logic_vector(3 downto 0) := x"9";
  constant E_JUMP      : std_logic_vector(3 downto 0) := x"A";

  -- -------------------- Banco de registradores ------------------------
  type regs_t is array (0 to 7) of std_logic_vector(15 downto 0);

end package cpu16_pkg;
