# CPU 16 bits em VHDL — DE2-115

Projeto de Lab. de Arquitetura de Sistemas Computacionais (PUC-Campinas).
CPU multiciclo de 16 bits com 11 instruções (ADD, SUB, AND, OR, SLT, ADDI, LD, ST, BEQ, BNE, JMP),
implementada na placa **Terasic DE2-115** (Cyclone IV E – EP4CE115F29C7) com **Quartus Prime 20.1 Lite**.

## Estrutura

```
rtl/       código VHDL sintetizável (componentes + cpu16_top.vhd)
sim/       testbenches para o ModelSim
mif/       programas de teste (.mif) que inicializam a memória
quartus/   projeto do Quartus (.qpf) e configurações + pinagem (.qsf)
docs/      especificação, diagramas e o PDF final
```

## Como abrir no Quartus

1. `File > Open Project` → `quartus/cpu16.qpf`
2. Cada novo arquivo de `rtl/` precisa ser adicionado ao projeto
   (`Project > Add/Remove Files`, ou uma linha `VHDL_FILE` no `cpu16.qsf`).
3. A pinagem da DE2-115 já está no `cpu16.qsf`. Conferir com a tabela do manual
   da placa (DE2-115 User Manual) antes da primeira gravação.

## Uso da placa

| Recurso | Função |
|---|---|
| KEY[0] | clock manual da CPU (com debouncer) |
| KEY[1] | reset |
| HEX0–HEX3 | valor do PC |
| HEX4–HEX7 | RDM (SW17 = 0) ou saída da ULA (SW17 = 1) |
| LEDG | estado atual da unidade de controle |

## Fluxo de trabalho com git

- Não versionar arquivos gerados pela compilação (já estão no `.gitignore`).
- Um branch por componente/tarefa (ex.: `ula`, `banco-regs`, `controle`), com merge na `main` depois que o testbench passar.
- Registrar em `docs/uso-de-ia.md` o que for feito com ajuda de IA (é seção obrigatória do relatório).

## Cronograma

| Etapa | Datas | Entrega |
|---|---|---|
| 0. Organização | 12–13/11 | repositório, grupo no Canvas, divisão de tarefas |
| 1. Especificação | 13–15/11 | `docs/especificacao-isa.md` fechado |
| 2. Componentes | 15–18/11 | ULA, banco de regs, PC, IR, RDM, extensor, muxes, memória + testbenches |
| 3. Controle + integração | 18–20/11 | máquina de estados, `cpu16_top`, simulação completa |
| 4. Programas de teste | 20–22/11 | `.mif` cobrindo as 11 instruções |
| 5. FPGA | 22–24/11 | debouncer, displays, SW17, LEDs, teste na placa |
| 6. Documento | 24–26/11 | PDF de especificação |
| Entrega / apresentação | 27/11 | |
