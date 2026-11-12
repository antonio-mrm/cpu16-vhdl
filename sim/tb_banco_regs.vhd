-- =====================================================================
--  tb_banco_regs.vhd - Testbench do banco de registradores
--
--  Confere: reset zera tudo, escrita/leitura em R1..R7, R0 sempre 0,
--  we = '0' não escreve, leitura simultânea nas duas portas.
--
--  ModelSim:
--    vlib work
--    vcom -2008 rtl/banco_regs.vhd sim/tb_banco_regs.vhd
--    vsim -c tb_banco_regs -do "run -all; quit"
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_banco_regs is
end entity tb_banco_regs;

architecture sim of tb_banco_regs is
  signal clk, rst, we   : std_logic := '0';
  signal ra1, ra2, wa   : std_logic_vector(2 downto 0) := "000";
  signal wd, rd1, rd2   : std_logic_vector(15 downto 0) := (others => '0');
  signal fim            : boolean := false;
  constant T : time := 20 ns;
begin

  dut : entity work.banco_regs
    port map (clk => clk, rst => rst, we => we, ra1 => ra1, ra2 => ra2,
              wa => wa, wd => wd, rd1 => rd1, rd2 => rd2);

  clk <= not clk after T/2 when not fim;

  estimulos : process
    variable falhas : natural := 0;

    -- escreve 'valor' em R[reg] (um ciclo de clock com we = '1')
    procedure escreve(reg : natural; valor : std_logic_vector(15 downto 0)) is
    begin
      wa <= std_logic_vector(to_unsigned(reg, 3));
      wd <= valor;
      we <= '1';
      wait until rising_edge(clk);
      wait for 1 ns;
      we <= '0';
    end procedure;

    -- lê R[reg] na porta 1 e confere
    procedure confere(reg : natural; esperado : std_logic_vector(15 downto 0); msg : string) is
    begin
      ra1 <= std_logic_vector(to_unsigned(reg, 3));
      wait for 1 ns;
      if rd1 /= esperado then
        falhas := falhas + 1;
        report "FALHOU: " & msg & "  R" & integer'image(reg) & "=" & to_hstring(rd1) &
               " (esperado " & to_hstring(esperado) & ")" severity error;
      else
        report "ok:     " & msg severity note;
      end if;
    end procedure;

  begin
    -- 1. Reset
    rst <= '1';
    wait for T;
    rst <= '0';
    for r in 0 to 7 loop
      confere(r, x"0000", "reset zera R" & integer'image(r));
    end loop;

    -- 2. Escrita e leitura em R1..R7 (valor diferente em cada um)
    for r in 1 to 7 loop
      escreve(r, std_logic_vector(to_unsigned(16#1110# * r, 16)));
    end loop;
    for r in 1 to 7 loop
      confere(r, std_logic_vector(to_unsigned(16#1110# * r, 16)), "escrita/leitura R" & integer'image(r));
    end loop;

    -- 3. R0 continua 0 mesmo tentando escrever
    escreve(0, x"BEEF");
    confere(0, x"0000", "R0 ignora escrita");

    -- 4. we = '0' não altera o registrador
    wa <= "011"; wd <= x"FFFF"; we <= '0';
    wait until rising_edge(clk);
    wait for 1 ns;
    confere(3, x"3330", "we=0 nao escreve");

    -- 5. Duas portas lendo registradores diferentes ao mesmo tempo
    ra1 <= "010"; ra2 <= "101";
    wait for 1 ns;
    if rd1 /= x"2220" or rd2 /= x"5550" then
      falhas := falhas + 1;
      report "FALHOU: leitura dupla  rd1=" & to_hstring(rd1) & " rd2=" & to_hstring(rd2) severity error;
    else
      report "ok:     leitura dupla R2 e R5" severity note;
    end if;

    -- 6. Reset no meio da execução zera tudo de novo
    rst <= '1';
    wait for 1 ns;
    rst <= '0';
    confere(7, x"0000", "reset assincrono zera R7");

    if falhas = 0 then
      report "=== BANCO DE REGISTRADORES: todos os testes passaram ===" severity note;
    else
      report "=== BANCO DE REGISTRADORES: " & integer'image(falhas) & " falha(s) ===" severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture sim;
