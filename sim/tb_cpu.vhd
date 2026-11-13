-- =====================================================================
--  tb_cpu.vhd - Testbench da CPU completa
--
--  Roda o programa do mif/programa.mif, mostra cada instrução executada
--  (PC e código) e, no final, confere os registradores e o PC.
--
--  Programa (ver mif/programa.mif):
--    ADDI R1,R0,5 / ADDI R2,R0,3 / ADD R3,R1,R2 / ST R3,R0,16 /
--    LD R4,R0,16 / JMP 5
--  Esperado: R1=5, R2=3, R3=8, R4=8 e o PC parado em 5.
--  (R4 = 8 só acontece se o ST gravou e o LD leu a memória corretamente.)
--
--  ModelSim (na pasta raiz do projeto): do sim/rodar_testes.do
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu16_pkg.all;

entity tb_cpu is
end entity tb_cpu;

architecture sim of tb_cpu is
  signal clk    : std_logic := '0';
  signal rst    : std_logic := '1';
  signal fim    : boolean := false;
  signal pc, ir, rdm, ula : std_logic_vector(15 downto 0);
  signal estado : std_logic_vector(3 downto 0);
  constant T : time := 20 ns;
begin

  dut : entity work.cpu
    generic map (ARQ_MIF => "mif/programa.mif")
    port map (clk => clk, rst => rst, pc_out => pc, ir_out => ir,
              rdm_out => rdm, ula_out => ula, estado_out => estado);

  clk <= not clk after T/2 when not fim;

  -- Mostra cada instrução quando ela chega no DECODE
  -- (nesse momento o IR já tem a instrução e o PC já foi incrementado)
  rastro : process (clk)
  begin
    if rising_edge(clk) and rst = '0' and estado = E_DECODE then
      report "executando: endereco " &
             to_hstring(std_logic_vector(unsigned(pc) - 1)) &
             "  instrucao " & to_hstring(ir) severity note;
    end if;
  end process;

  verificacao : process
    -- acesso direto aos registradores dentro do banco (VHDL-2008)
    alias regs is << signal .tb_cpu.dut.u_banco.regs : regs_t >>;
    variable falhas : natural := 0;

    procedure confere(r : natural; esperado : std_logic_vector(15 downto 0)) is
    begin
      if regs(r) /= esperado then
        falhas := falhas + 1;
        report "FALHOU: R" & integer'image(r) & " = " & to_hstring(regs(r)) &
               " (esperado " & to_hstring(esperado) & ")" severity error;
      else
        report "ok:     R" & integer'image(r) & " = " & to_hstring(regs(r)) severity note;
      end if;
    end procedure;

  begin
    -- reset por 2 ciclos
    rst <= '1';
    wait for 2 * T;
    wait until falling_edge(clk);
    rst <= '0';

    -- o programa leva 21 ciclos até o JMP; 60 ciclos dá folga
    for i in 1 to 60 loop
      wait until rising_edge(clk);
    end loop;

    -- espera entrar no FETCH de uma instrução para conferir o PC
    wait until estado = E_FETCH;
    wait for 1 ns;

    confere(0, x"0000");
    confere(1, x"0005");
    confere(2, x"0003");
    confere(3, x"0008");
    confere(4, x"0008");

    if pc /= x"0005" then
      falhas := falhas + 1;
      report "FALHOU: PC = " & to_hstring(pc) & " (esperado 0005, preso no JMP)" severity error;
    else
      report "ok:     PC parado em 0005 (JMP)" severity note;
    end if;

    if falhas = 0 then
      report "=== CPU: programa executado corretamente ===" severity note;
    else
      report "=== CPU: " & integer'image(falhas) & " falha(s) ===" severity failure;
    end if;
    fim <= true;
    wait;
  end process;

end architecture sim;
