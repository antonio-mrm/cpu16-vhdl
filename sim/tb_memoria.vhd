-- =====================================================================
--  tb_memoria.vhd - Testbench da memória
--
--  Confere: (1) o .mif foi carregado (lê os endereços 00..05 e compara
--  com o programa), (2) escrita e leitura de volta, (3) we = '0' não grava.
--
--  ModelSim (rodar na pasta raiz do projeto; precisa da biblioteca
--  altera_mf, que já vem com o ModelSim-Intel FPGA):
--    vlib work
--    vcom -2008 rtl/memoria.vhd sim/tb_memoria.vhd
--    vsim -c -L altera_mf tb_memoria -do "run -all; quit"
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_memoria is
end entity tb_memoria;

architecture sim of tb_memoria is
  signal clk      : std_logic := '0';
  signal we       : std_logic := '0';
  signal endereco : std_logic_vector(7 downto 0) := (others => '0');
  signal dado_in  : std_logic_vector(15 downto 0) := (others => '0');
  signal dado_out : std_logic_vector(15 downto 0);
  signal fim      : boolean := false;
  constant T : time := 20 ns;

  type palavras_t is array (0 to 5) of std_logic_vector(15 downto 0);
  constant PROGRAMA : palavras_t := (x"5205", x"5403", x"0650", x"7610", x"6810", x"A005");
begin

  dut : entity work.memoria
    generic map (ARQ_MIF => "mif/programa.mif")   -- caminho a partir da raiz
    port map (clk => clk, we => we, endereco => endereco,
              dado_in => dado_in, dado_out => dado_out);

  clk <= not clk after T/2 when not fim;

  process
    variable falhas : natural := 0;

    -- coloca o endereço, espera a borda de subida e confere a saída
    procedure le(addr : natural; esperado : std_logic_vector(15 downto 0); msg : string) is
    begin
      endereco <= std_logic_vector(to_unsigned(addr, 8));
      wait until rising_edge(clk);
      wait for 1 ns;
      if dado_out /= esperado then
        falhas := falhas + 1;
        report "FALHOU: " & msg & "  Mem[" & integer'image(addr) & "]=" & to_hstring(dado_out) &
               " (esperado " & to_hstring(esperado) & ")" severity error;
      else
        report "ok:     " & msg severity note;
      end if;
    end procedure;

  begin
    -- 1. Conteúdo inicial vindo do .mif
    for i in PROGRAMA'range loop
      le(i, PROGRAMA(i), "mif carregado, endereco " & integer'image(i));
    end loop;
    le(16#20#, x"0000", "posicao nao usada vale 0");

    -- 2. Escrita (como um ST) e leitura de volta
    endereco <= x"10";
    dado_in  <= x"ABCD";
    we       <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    we <= '0';
    le(16#10#, x"ABCD", "escrita e leitura em 0x10");

    -- 3. Com we = '0' o conteúdo não muda
    endereco <= x"10";
    dado_in  <= x"FFFF";
    wait until rising_edge(clk);
    wait for 1 ns;
    le(16#10#, x"ABCD", "we=0 nao grava");

    if falhas = 0 then
      report "=== MEMORIA: todos os testes passaram ===" severity note;
    else
      report "=== MEMORIA: " & integer'image(falhas) & " falha(s) ===" severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture sim;
