# =====================================================================
#  rodar_testes.do - Compila tudo e roda todos os testbenches
#
#  No ModelSim:
#    1. File > Change Directory... -> escolha a pasta raiz do projeto
#       (a que tem rtl/, sim/ e mif/)
#    2. No console (Transcript), digite:   do sim/rodar_testes.do
#
#  Cada testbench termina com uma linha "=== ... ===" dizendo se passou.
# =====================================================================

onbreak {resume}

if {[file exists work]} { vdel -lib work -all }
vlib work

# ---- código da CPU (a ordem importa: o pacote vem primeiro) ----
vcom -2008 rtl/cpu16_pkg.vhd
vcom -2008 rtl/ula.vhd
vcom -2008 rtl/banco_regs.vhd
vcom -2008 rtl/registrador.vhd
vcom -2008 rtl/extensor_sinal.vhd
vcom -2008 rtl/memoria.vhd
vcom -2008 rtl/unidade_controle.vhd
vcom -2008 rtl/cpu.vhd

# ---- testbenches ----
vcom -2008 sim/tb_ula.vhd
vcom -2008 sim/tb_banco_regs.vhd
vcom -2008 sim/tb_extensor_sinal.vhd
vcom -2008 sim/tb_memoria.vhd
vcom -2008 sim/tb_cpu.vhd

# ---- execução ----
foreach tb {tb_ula tb_banco_regs tb_extensor_sinal tb_memoria tb_cpu} {
    echo "################ $tb ################"
    vsim -quiet -L altera_mf work.$tb
    run -all
    quit -sim
}
echo "################ fim dos testes ################"
