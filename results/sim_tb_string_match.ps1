$src = Get-ChildItem -Path c:\Users\nayak\Desktop\riscv32-processor\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sources_1\imports\src\*.sv | Select-Object -ExpandProperty FullName
$tb = "c:\Users\nayak\Desktop\riscv32-processor\riscv_pipeline_offline\riscv_pipeline_offline.srcs\sim_1\imports\sim\tb_string_match.sv"

$xvlog_args = @("-sv") + $src + @($tb)
& C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat $xvlog_args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat --timescale 1ns/1ps tb_string_match -snapshot tb_string_match_snap
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat tb_string_match_snap -R
