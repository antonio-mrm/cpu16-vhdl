-- =====================================================================
--  banco_regs.vhd - Banco de 8 registradores de 16 bits (R0..R7)
--
--  - 2 portas de leitura (combinacionais): rd1 = R[ra1], rd2 = R[ra2]
--  - 1 porta de escrita (síncrona, borda de subida): se we = '1',
--    R[wa] <= wd
--  - R0 vale sempre 0: escritas em R0 são ignoradas
--  - rst = '1' zera todos os registradores
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_regs is
  port (
    clk : in  std_logic;
    rst : in  std_logic;                      -- ativo alto
    we  : in  std_logic;                      -- habilita escrita
    ra1 : in  std_logic_vector(2 downto 0);   -- endereço leitura 1 (Rj)
    ra2 : in  std_logic_vector(2 downto 0);   -- endereço leitura 2 (Rk ou Ri)
    wa  : in  std_logic_vector(2 downto 0);   -- endereço escrita (Ri)
    wd  : in  std_logic_vector(15 downto 0);  -- dado a escrever
    rd1 : out std_logic_vector(15 downto 0);
    rd2 : out std_logic_vector(15 downto 0)
  );
end entity banco_regs;

architecture rtl of banco_regs is
  type regs_t is array (0 to 7) of std_logic_vector(15 downto 0);
  signal regs : regs_t := (others => (others => '0'));
begin

  escrita : process (clk, rst)
  begin
    if rst = '1' then
      regs <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if we = '1' and wa /= "000" then        -- R0 não pode ser escrito
        regs(to_integer(unsigned(wa))) <= wd;
      end if;
    end if;
  end process;

  rd1 <= regs(to_integer(unsigned(ra1)));
  rd2 <= regs(to_integer(unsigned(ra2)));

end architecture rtl;
