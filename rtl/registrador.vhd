-- =====================================================================
--  registrador.vhd - Registrador genérico com habilitação
--
--  Usado para PC, IR, RDM, A, B e SaídaULA.
--  Na borda de subida, se en = '1', q <= d. rst = '1' zera.
--  Largura configurável pelo generic N (padrão 16 bits).
--
--  Exemplo de uso:
--    pc_reg : entity work.registrador
--      generic map (N => 16)
--      port map (clk => clk, rst => rst, en => pc_en, d => pc_prox, q => pc);
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;

entity registrador is
  generic (N : positive := 16);
  port (
    clk : in  std_logic;
    rst : in  std_logic;                       -- ativo alto
    en  : in  std_logic;                       -- habilita carga
    d   : in  std_logic_vector(N-1 downto 0);
    q   : out std_logic_vector(N-1 downto 0)
  );
end entity registrador;

architecture rtl of registrador is
begin
  process (clk, rst)
  begin
    if rst = '1' then
      q <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        q <= d;
      end if;
    end if;
  end process;
end architecture rtl;
