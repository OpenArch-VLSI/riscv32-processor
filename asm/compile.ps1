riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x00000000 -o core0_demo.elf core0_demo.s
riscv-none-elf-objcopy -O binary core0_demo.elf core0_demo.bin
python bin2hex.py core0_demo.bin core0_demo.mem

riscv-none-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext 0x00000000 -o core1_demo.elf core1_demo.s
riscv-none-elf-objcopy -O binary core1_demo.elf core1_demo.bin
python bin2hex.py core1_demo.bin core1_demo.mem
