-- =====================================================================
--  cpu.vhd - CPU multiciclo de 16 bits (caminho de dados + controle +
--            memória)
--
--  Liga todos os componentes da Etapa 2 com os multiplexadores e a
--  unidade de controle. Não tem nada específico da placa: botões,
--  debouncer e displays ficam no cpu16_top.vhd (Etapa 5).
--
--  Registradores internos (todos da entidade 'registrador'):
--    PC        : endereço da próxima instrução
--    IR        : instrução atual
--    RDM       : dado lido da memória (MDR)
--    A, B      : valores lidos do banco de registradores
--    SaidaULA  : resultado da ULA guardado para o estado seguinte
--  RDM, A, B e SaidaULA carregam em todo ciclo (como no Patterson).
--
--  Saídas de depuração: PC, IR, RDM, saída da ULA e estado atual,
--  usadas pelos displays/LEDs e pelo testbench.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu16_pkg.all;

entity cpu is
  generic (
    ARQ_MIF : string := "../mif/programa.mif"
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;                       -- ativo alto
    pc_out     : out std_logic_vector(15 downto 0);
    ir_out     : out std_logic_vector(15 downto 0);
    rdm_out    : out std_logic_vector(15 downto 0);
    ula_out    : out std_logic_vector(15 downto 0);
    estado_out : out std_logic_vector(3 downto 0)
  );
end entity cpu;

architecture rtl of cpu is

  -- ---------- sinais de controle ----------
  signal pc_write, pc_write_cond, i_ou_d, mem_write : std_logic;
  signal ir_write, reg_write, mem_to_reg, ula_src_a : std_logic;
  signal pc_source, ula_src_b, ula_op               : std_logic_vector(1 downto 0);

  -- ---------- registradores ----------
  signal pc, ir, rdm, reg_a, reg_b, saida_ula : std_logic_vector(15 downto 0);

  -- ---------- fios do caminho de dados ----------
  signal pc_prox, ula_a, ula_b, ula_s     : std_logic_vector(15 downto 0);
  signal imm16, end_jmp, dado_banco       : std_logic_vector(15 downto 0);
  signal rd1, rd2, mem_q                  : std_logic_vector(15 downto 0);
  signal mem_end                          : std_logic_vector(7 downto 0);
  signal ra2                              : std_logic_vector(2 downto 0);
  signal ula_codigo                       : std_logic_vector(2 downto 0);
  signal zero, condicao, pc_en, clk_mem   : std_logic;

  -- campos da instrução
  alias opcode   : std_logic_vector(3 downto 0)  is ir(15 downto 12);
  alias campo_ri : std_logic_vector(2 downto 0)  is ir(11 downto 9);
  alias campo_rj : std_logic_vector(2 downto 0)  is ir(8 downto 6);
  alias campo_rk : std_logic_vector(2 downto 0)  is ir(5 downto 3);
  alias campo_im : std_logic_vector(5 downto 0)  is ir(5 downto 0);
  alias campo_en : std_logic_vector(11 downto 0) is ir(11 downto 0);

begin

  -- =================== Unidade de controle ===================
  u_controle : entity work.unidade_controle
    port map (
      clk => clk, rst => rst, opcode => opcode,
      pc_write => pc_write, pc_write_cond => pc_write_cond,
      pc_source => pc_source, i_ou_d => i_ou_d, mem_write => mem_write,
      ir_write => ir_write, reg_write => reg_write, mem_to_reg => mem_to_reg,
      ula_src_a => ula_src_a, ula_src_b => ula_src_b, ula_op => ula_op,
      estado_out => estado_out
    );

  -- =================== PC ===================
  -- BEQ (opcode 1000, bit 12 = 0) desvia se zero = 1
  -- BNE (opcode 1001, bit 12 = 1) desvia se zero = 0
  condicao <= zero when ir(12) = '0' else not zero;
  pc_en    <= pc_write or (pc_write_cond and condicao);

  end_jmp <= "0000" & campo_en;              -- endereço do JMP estendido com zeros

  with pc_source select
    pc_prox <= ula_s     when "00",          -- PC + 1 (FETCH)
               saida_ula when "01",          -- alvo do desvio (calculado no DECODE)
               end_jmp   when others;        -- JMP

  u_pc : entity work.registrador
    port map (clk => clk, rst => rst, en => pc_en, d => pc_prox, q => pc);

  -- =================== Memória ===================
  -- clock invertido: registra o endereço no meio do ciclo da CPU
  clk_mem <= not clk;
  mem_end <= pc(7 downto 0) when i_ou_d = '0' else saida_ula(7 downto 0);

  u_memoria : entity work.memoria
    generic map (ARQ_MIF => ARQ_MIF)
    port map (clk => clk_mem, we => mem_write, endereco => mem_end,
              dado_in => reg_b, dado_out => mem_q);

  u_ir : entity work.registrador
    port map (clk => clk, rst => rst, en => ir_write, d => mem_q, q => ir);

  u_rdm : entity work.registrador
    port map (clk => clk, rst => rst, en => '1', d => mem_q, q => rdm);

  -- =================== Banco de registradores ===================
  -- 2ª porta de leitura: Rk nas instruções tipo R (ADD, SUB, AND, OR,
  -- SLT) e Ri nas demais (ST grava Ri; BEQ/BNE comparam Ri com Rj).
  ra2 <= campo_rk when (opcode = OP_ADD or opcode = OP_SUB or opcode = OP_AND or
                        opcode = OP_OR  or opcode = OP_SLT)
         else campo_ri;

  dado_banco <= saida_ula when mem_to_reg = '0' else rdm;

  u_banco : entity work.banco_regs
    port map (clk => clk, rst => rst, we => reg_write,
              ra1 => campo_rj, ra2 => ra2, wa => campo_ri,
              wd => dado_banco, rd1 => rd1, rd2 => rd2);

  u_a : entity work.registrador
    port map (clk => clk, rst => rst, en => '1', d => rd1, q => reg_a);

  u_b : entity work.registrador
    port map (clk => clk, rst => rst, en => '1', d => rd2, q => reg_b);

  -- =================== ULA ===================
  u_extensor : entity work.extensor_sinal
    port map (imm6 => campo_im, imm16 => imm16);

  ula_a <= pc when ula_src_a = '0' else reg_a;

  with ula_src_b select
    ula_b <= reg_b   when "00",
             x"0001" when "01",
             imm16   when others;

  with ula_op select
    ula_codigo <= "000"                when "00",   -- soma
                  "001"                when "01",   -- subtração
                  ir(14 downto 12)     when others; -- tipo R: 3 bits baixos do opcode

  u_ula : entity work.ula
    port map (a => ula_a, b => ula_b, op => ula_codigo, s => ula_s, zero => zero);

  u_saida_ula : entity work.registrador
    port map (clk => clk, rst => rst, en => '1', d => ula_s, q => saida_ula);

  -- =================== Saídas de depuração ===================
  pc_out  <= pc;
  ir_out  <= ir;
  rdm_out <= rdm;
  ula_out <= ula_s;

end architecture rtl;
