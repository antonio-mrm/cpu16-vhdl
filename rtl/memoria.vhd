-- =====================================================================
--  memoria.vhd - Memória de 256 palavras x 16 bits (instruções + dados)
--
--  Usa o bloco de RAM interno da FPGA (altsyncram, o mesmo componente
--  que o IP Catalog gera), inicializado pelo arquivo .mif.
--
--  Funcionamento (síncrono):
--    - na borda de subida de clk, registra o endereço; se we = '1',
--      grava 'dado_in' nesse endereço
--    - 'dado_out' mostra o conteúdo do endereço registrado
--
--  IMPORTANTE: na CPU, esta memória recebe o clock INVERTIDO
--  (clk => not clk_cpu). Assim o endereço é registrado no meio do ciclo
--  e o dado já está pronto na próxima borda de subida da CPU
--  (ver docs/especificacao-isa.md, seção 7).
--
--  O generic ARQ_MIF é o caminho do .mif:
--    - no Quartus o caminho é relativo à pasta quartus/ -> "../mif/..."
--    - no ModelSim é relativo à pasta onde o vsim roda  -> "mif/..."
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity memoria is
  generic (
    ARQ_MIF : string := "../mif/programa.mif"
  );
  port (
    clk      : in  std_logic;
    we       : in  std_logic;                     -- '1' = escrita (ST)
    endereco : in  std_logic_vector(7 downto 0);  -- 256 posições
    dado_in  : in  std_logic_vector(15 downto 0);
    dado_out : out std_logic_vector(15 downto 0)
  );
end entity memoria;

architecture rtl of memoria is
begin

  ram : altsyncram
    generic map (
      operation_mode                => "SINGLE_PORT",
      intended_device_family        => "Cyclone IV E",
      lpm_type                      => "altsyncram",
      lpm_hint                      => "ENABLE_RUNTIME_MOD=NO",
      width_a                       => 16,     -- palavra de 16 bits
      widthad_a                     => 8,      -- endereço de 8 bits
      numwords_a                    => 256,    -- 256 palavras
      width_byteena_a               => 1,
      outdata_reg_a                 => "UNREGISTERED",  -- só o endereço é registrado
      outdata_aclr_a                => "NONE",
      clock_enable_input_a          => "BYPASS",
      clock_enable_output_a         => "BYPASS",
      power_up_uninitialized        => "FALSE",
      read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
      init_file                     => ARQ_MIF
    )
    port map (
      clock0    => clk,
      address_a => endereco,
      data_a    => dado_in,
      wren_a    => we,
      q_a       => dado_out
    );

end architecture rtl;
