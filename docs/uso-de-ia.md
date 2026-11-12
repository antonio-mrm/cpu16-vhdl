# Registro de uso de IA

Seção obrigatória do relatório: "quais partes foram desenvolvidas com uso de IA e por quê".
Anotem aqui conforme o projeto avança.

| Data | Parte do projeto | Ferramenta | O que a IA fez | Por quê / o que o grupo revisou |
|---|---|---|---|---|
| 12/11 | Estrutura do repositório, `.gitignore`, pinagem da DE2-115 no `.qsf`, rascunho da especificação da ISA | Claude | Gerou os arquivos iniciais | Agilizar a configuração; pinagem conferida com o manual da placa pelo grupo |
| 12/11 | ULA (`rtl/ula.vhd`) e testbench (`sim/tb_ula.vhd`); decisões finais da ISA | Claude | Escreveu a ULA e o testbench como modelo para os demais componentes; redigiu as decisões | Servir de padrão de código para o grupo; o grupo aprovou as decisões e roda o testbench no ModelSim |
| 12/11 | Banco de registradores, registrador genérico, extensor de sinal e testbenches | Claude | Escreveu os componentes e os testbenches | Acelerar a etapa 2; o grupo revisa o código e roda os testbenches no ModelSim |
| 12/11 | Memória (`rtl/memoria.vhd`), testbench e `mif/programa.mif`; pinagem com padrões de tensão a partir do arquivo oficial do professor | Claude | Escreveu a instância do altsyncram, o programa de teste básico e reorganizou a pinagem | Evitar o assistente do IP Catalog e permitir carregar o .mif na simulação; codificação das instruções conferida |
