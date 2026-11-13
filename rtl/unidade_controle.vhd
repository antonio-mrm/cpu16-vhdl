-- =====================================================================
--  unidade_controle.vhd - Máquina de estados da CPU multiciclo
--
--  Lê o opcode (IR[15..12]) e gera os sinais de controle do caminho de
--  dados. Cada borda de subida do clock avança um estado.
--
--  Sequência de estados por instrução:
--    Tipo R (ADD..SLT): FETCH -> DECODE -> EXEC_R -> WB_R            (4)
--    ADDI             : FETCH -> DECODE -> EXEC_I -> WB_ADDI         (4)
--    LD               : FETCH -> DECODE -> EXEC_I -> MEM_READ -> WB_LD (5)
--    ST               : FETCH -> DECODE -> EXEC_I -> MEM_WRITE       (4)
--    BEQ / BNE        : FETCH -> DECODE -> BRANCH                    (3)
--    JMP              : FETCH -> DECODE -> JUMP                      (3)
--    Opcode inválido  : FETCH -> DECODE -> FETCH (NOP)               (2)
--
--  Sinais de controle (todos '0' / "00" quando não citados):
--    pc_write      : carrega o PC incondicionalmente
--    pc_write_cond : carrega o PC se a condição do desvio for verdadeira
--    pc_source     : 00 = saída da ULA (PC+1) | 01 = SaídaULA (alvo do
--                    desvio) | 10 = endereço do JMP
--    i_ou_d        : endereço da memória: 0 = PC | 1 = SaídaULA
--    mem_write     : escreve na memória (ST)
--    ir_write      : carrega o IR com a instrução lida
--    reg_write     : escreve no banco de registradores
--    mem_to_reg    : dado escrito no banco: 0 = SaídaULA | 1 = RDM
--    ula_src_a     : entrada A da ULA: 0 = PC | 1 = registrador A
--    ula_src_b     : entrada B da ULA: 00 = registrador B | 01 = 1 |
--                    10 = imediato estendido
--    ula_op        : 00 = soma | 01 = subtração | 10 = campo do opcode
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use work.cpu16_pkg.all;

entity unidade_controle is
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;                     -- ativo alto
    opcode        : in  std_logic_vector(3 downto 0);  -- IR[15..12]

    pc_write      : out std_logic;
    pc_write_cond : out std_logic;
    pc_source     : out std_logic_vector(1 downto 0);
    i_ou_d        : out std_logic;
    mem_write     : out std_logic;
    ir_write      : out std_logic;
    reg_write     : out std_logic;
    mem_to_reg    : out std_logic;
    ula_src_a     : out std_logic;
    ula_src_b     : out std_logic_vector(1 downto 0);
    ula_op        : out std_logic_vector(1 downto 0);

    estado_out    : out std_logic_vector(3 downto 0)   -- para os LEDs
  );
end entity unidade_controle;

architecture rtl of unidade_controle is
  signal estado, prox : std_logic_vector(3 downto 0);
begin

  -- ---------------- Registrador de estado ----------------
  process (clk, rst)
  begin
    if rst = '1' then
      estado <= E_FETCH;
    elsif rising_edge(clk) then
      estado <= prox;
    end if;
  end process;

  estado_out <= estado;

  -- ---------------- Próximo estado ----------------
  process (estado, opcode)
  begin
    case estado is
      when E_FETCH =>
        prox <= E_DECODE;

      when E_DECODE =>
        case opcode is
          when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_SLT => prox <= E_EXEC_R;
          when OP_ADDI | OP_LD | OP_ST                   => prox <= E_EXEC_I;
          when OP_BEQ | OP_BNE                           => prox <= E_BRANCH;
          when OP_JMP                                    => prox <= E_JUMP;
          when others                                    => prox <= E_FETCH;  -- NOP
        end case;

      when E_EXEC_R =>
        prox <= E_WB_R;

      when E_EXEC_I =>
        case opcode is
          when OP_LD  => prox <= E_MEM_READ;
          when OP_ST  => prox <= E_MEM_WRITE;
          when others => prox <= E_WB_ADDI;
        end case;

      when E_MEM_READ =>
        prox <= E_WB_LD;

      when others =>          -- WB_R, WB_ADDI, WB_LD, MEM_WRITE, BRANCH, JUMP
        prox <= E_FETCH;
    end case;
  end process;

  -- ---------------- Sinais de controle de cada estado ----------------
  process (estado)
  begin
    -- valores padrão: nada é escrito
    pc_write      <= '0';
    pc_write_cond <= '0';
    pc_source     <= "00";
    i_ou_d        <= '0';
    mem_write     <= '0';
    ir_write      <= '0';
    reg_write     <= '0';
    mem_to_reg    <= '0';
    ula_src_a     <= '0';
    ula_src_b     <= "00";
    ula_op        <= "00";

    case estado is
      when E_FETCH =>                 -- IR <- Mem[PC]; PC <- PC + 1
        i_ou_d    <= '0';
        ir_write  <= '1';
        ula_src_a <= '0';             -- PC
        ula_src_b <= "01";            -- constante 1
        ula_op    <= "00";            -- soma
        pc_source <= "00";
        pc_write  <= '1';

      when E_DECODE =>                -- SaídaULA <- PC + imm (alvo do desvio)
        ula_src_a <= '0';             -- PC (já incrementado)
        ula_src_b <= "10";            -- imediato
        ula_op    <= "00";

      when E_EXEC_R =>                -- SaídaULA <- A op B
        ula_src_a <= '1';
        ula_src_b <= "00";
        ula_op    <= "10";            -- operação vem do opcode

      when E_WB_R | E_WB_ADDI =>      -- R[Ri] <- SaídaULA
        reg_write  <= '1';
        mem_to_reg <= '0';

      when E_EXEC_I =>                -- SaídaULA <- A + imm
        ula_src_a <= '1';
        ula_src_b <= "10";
        ula_op    <= "00";

      when E_MEM_READ =>              -- RDM <- Mem[SaídaULA]
        i_ou_d <= '1';

      when E_WB_LD =>                 -- R[Ri] <- RDM
        reg_write  <= '1';
        mem_to_reg <= '1';

      when E_MEM_WRITE =>             -- Mem[SaídaULA] <- B
        i_ou_d    <= '1';
        mem_write <= '1';

      when E_BRANCH =>                -- compara A - B; se condição, PC <- SaídaULA
        ula_src_a     <= '1';
        ula_src_b     <= "00";
        ula_op        <= "01";        -- subtração
        pc_source     <= "01";
        pc_write_cond <= '1';

      when E_JUMP =>                  -- PC <- endereço da instrução
        pc_source <= "10";
        pc_write  <= '1';

      when others =>
        null;
    end case;
  end process;

end architecture rtl;
