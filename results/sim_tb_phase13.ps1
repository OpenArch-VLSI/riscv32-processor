$src = Get-ChildItem -Path ..\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sources_1\imports\src\*.sv | Select-Object -ExpandProperty FullName
$src = $src | Where-Object { $_ -notmatch 'dual_core_top\.sv$' }
$src += "..\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sources_1\imports\src\dual_core_top.sv"
$tb = "..\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sim_1\imports\tb_phase13.sv"

$xvlog_args = @("-sv") + $src + @($tb)
& C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat $xvlog_args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat --timescale 1ns/1ps -debug typical tb_phase13 -snapshot tb_phase13_snap
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_phase13_snap -R
