# Especificação da ISA — CPU 16 bits

> Decisões aprovadas pelo grupo em 12/11/2026 (Etapa 1).
> Este arquivo é a base da seção "Especificação" do PDF.

## 1. Visão geral

- Palavra de 16 bits; instruções de 16 bits.
- 8 registradores de uso geral de 16 bits (R0–R7), endereçados por 3 bits.
- Memória única para instruções e dados (arquitetura von Neumann), inicializada por `.mif`.
- Endereçamento por palavra: cada endereço guarda 16 bits; o PC soma **1** a cada instrução.
- CPU **multiciclo**: unidade de controle é uma máquina de estados (o enunciado pede LEDs mostrando o estado).

## 2. Registradores

| Registrador | Endereço | Tamanho | Observação |
|---|---|---|---|
| R0 | 000 | 16 bits | constante zero (escrita ignorada). Permite `ADDI Ri, R0, k` para carregar constantes |
| R1–R7 | 001–111 | 16 bits | uso geral; zerados no reset |

Registradores internos (não visíveis ao programador): PC, IR (instrução), RDM (dado lido da memória), A e B (saídas do banco), SaídaULA.

## 3. Formatos

```
Tipo R:  | opcode 15..12 | Ri 11..9 | Rj 8..6 | Rk 5..3 | não usado 2..0 |
Tipo I:  | opcode 15..12 | Ri 11..9 | Rj 8..6 |      imediato 5..0       |
Tipo J:  | opcode 15..12 |              end 11..0                       |
```

- Imediato: 6 bits em complemento de 2 → de **−32 a +31**, estendido com sinal para 16 bits.
- `end` (JMP): 12 bits, estendido com zeros para 16 bits → alcança os endereços 0 a 4095.

## 4. Opcodes

| Instrução | Opcode | Tipo | Operação |
|---|---|---|---|
| ADD  Ri, Rj, Rk | 0000 | R | Ri ← Rj + Rk |
| SUB  Ri, Rj, Rk | 0001 | R | Ri ← Rj − Rk |
| AND  Ri, Rj, Rk | 0010 | R | Ri ← Rj AND Rk (bit a bit) |
| OR   Ri, Rj, Rk | 0011 | R | Ri ← Rj OR Rk (bit a bit) |
| SLT  Ri, Rj, Rk | 0100 | R | Ri ← 1 se Rj < Rk (com sinal), senão 0 |
| ADDI Ri, Rj, imm | 0101 | I | Ri ← Rj + imm |
| LD   Ri, Rj, imm | 0110 | I | Ri ← Mem[Rj + imm] |
| ST   Ri, Rj, imm | 0111 | I | Mem[Rj + imm] ← Ri |
| BEQ  Ri, Rj, imm | 1000 | I | se Ri = Rj: PC ← PC + imm |
| BNE  Ri, Rj, imm | 1001 | I | se Ri ≠ Rj: PC ← PC + imm |
| JMP  end | 1010 | J | PC ← end |
| (livres) | 1011–1111 | — | sem uso (tratar como NOP ou voltar ao fetch) |

Decisões:

1. **AND/OR**: o enunciado escreve `&&` e `||`, mas implementamos a operação **bit a bit** (como em MIPS), que é o uso normal numa CPU e o que a ULA precisa para manipular bits.
2. **SLT com sinal**: compara em complemento de 2, coerente com o imediato, que também tem sinal.
3. **Desvio relativo ao PC já incrementado**: como o PC é incrementado no fetch,
   `alvo = (endereço do BEQ) + 1 + imm`. Exemplo: um `BEQ` em 0x05 com `imm = −3` vai para 0x03.
4. **Memória de 256 palavras × 16 bits** (endereço de 8 bits). Basta para os testes; o JMP usa só os 8 bits baixos.
5. **Códigos 1011–1111**: a CPU volta ao FETCH sem fazer nada (NOP).

### Código da ULA

Os opcodes 0000–0100 foram escolhidos para que os **3 bits baixos do opcode tipo R** sejam
o próprio código da operação da ULA — a unidade de controle só repassa `opcode(2 downto 0)`.

| op ULA | Operação | Usada por |
|---|---|---|
| 000 | a + b | ADD, ADDI, LD, ST, cálculo do alvo do desvio |
| 001 | a − b | SUB, BEQ/BNE (flag `zero`) |
| 010 | a AND b | AND |
| 011 | a OR b | OR |
| 100 | a < b ? 1 : 0 | SLT |

## 5. Atenção: quem é lido do banco de registradores

Nas instruções tipo R, os operandos são **Rj e Rk**. Mas em `ST`, `BEQ` e `BNE` o segundo operando é **Ri** (campo 11..9).
Então a 2ª porta de leitura do banco precisa de um **mux** escolhendo entre o campo Rk (5..3) e o campo Ri (11..9).

| Porta | Campo da instrução |
|---|---|
| Leitura 1 (A) | sempre Rj (8..6) |
| Leitura 2 (B) | Rk (5..3) em tipo R; Ri (11..9) em ST/BEQ/BNE |
| Escrita | sempre Ri (11..9) |

## 6. Exemplos de codificação

| Assembly | Binário | Hex |
|---|---|---|
| `ADDI R1, R0, 5` | 0101 001 000 000101 | 0x5205 |
| `ADD R3, R1, R2` | 0000 011 001 010 000 | 0x0650 |
| `BEQ R1, R2, -3` | 1000 001 010 111101 | 0x82BD |
| `JMP 0x010` | 1010 000000010000 | 0xA010 |

## 7. Máquina de estados (base: multiciclo do Patterson)

| # | Estado | O que faz |
|---|---|---|
| 0 | FETCH | IR ← Mem[PC]; PC ← PC + 1 |
| 1 | DECODE | A ← R[Rj]; B ← R[Rk ou Ri]; SaídaULA ← PC + imm (alvo do desvio) |
| 2 | EXEC_R | SaídaULA ← A op B |
| 3 | WB_R | R[Ri] ← SaídaULA |
| 4 | EXEC_I | SaídaULA ← A + imm (ADDI, LD, ST) |
| 5 | WB_ADDI | R[Ri] ← SaídaULA |
| 6 | MEM_READ | RDM ← Mem[SaídaULA] |
| 7 | WB_LD | R[Ri] ← RDM |
| 8 | MEM_WRITE | Mem[SaídaULA] ← B |
| 9 | BRANCH | compara A e B; se condição, PC ← SaídaULA |
| 10 | JUMP | PC ← end |

LEDs verdes: número do estado em binário em `LEDG[3:0]`.

### Memória síncrona: clock invertido

A memória da FPGA (altsyncram) é **síncrona**: ela registra o endereço numa borda de clock e só então entrega o dado.
**Decisão:** a memória usa o clock **invertido** em relação à CPU.

- Na borda de subida, a CPU muda de estado e coloca o endereço (PC ou SaídaULA).
- Na borda de descida (meio do ciclo), a memória registra o endereço e entrega o dado.
- Na próxima borda de subida, o dado já está pronto para ser guardado no IR ou no RDM.

A memória é o componente `altsyncram` (o mesmo que o IP Catalog gera) instanciado direto em `rtl/memoria.vhd`, o que permite carregar o `.mif` tanto no Quartus quanto na simulação do ModelSim.

Assim cada acesso à memória cabe em **um estado**, a máquina de estados fica igual à do livro e não são
necessários estados de espera. Com o clock manual pelo botão, a borda de descida acontece quando o botão é solto.
