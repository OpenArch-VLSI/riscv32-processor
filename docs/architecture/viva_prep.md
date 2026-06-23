# Viva Preparation — RISC-V Pipeline SoC on PYNQ-Z2

Topics organized by section with key points to prepare. Refer to the linked doc files for details.

---

## 1. RISC-V ISA Fundamentals

> Refer: [architecture.md](./architecture.md) — RV32I Instruction Support Table

- What is RISC-V? Difference between RISC-V and ARM/x86.
- What does RV32I mean? (32-bit integer base ISA)
- Instruction formats: R, I, S, B, U, J — draw each and explain fields (opcode, rd, rs1, rs2, funct3, funct7, imm)
- How many RV32I instructions are supported? (47 implemented + 5 custom SIMD)
- Why is `x0` hardwired to zero and how is it handled in the register file?
- What is the difference between `SLL` and `SLLI`? `SLT` vs `SLTU`?
- What do `LUI` and `AUIPC` do and why are they U-type?
- Explain the PC update for `JAL` and `JALR` — difference between them.
- What are the 6 branch conditions (`BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`)?

---

## 2. 5-Stage Pipeline Architecture

> Refer: [pipeline.dot](../diagrams/pipeline.dot), [architecture.md](./architecture.md) — Pipeline Organization

- Name the 5 stages and what each does (IF, ID, EX, MEM, WB)
- Draw the pipeline datapath with all pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB)
- What signals pass through each pipeline register?
- What is the difference between a pipelined and non-pipelined (single-cycle) processor?
- What is CPI (Cycles Per Instruction) and IPC (Instructions Per Cycle)? What is the ideal CPI for a 5-stage pipeline?
- Why do we pipeline? (throughput improvement, not latency)
- How is the PC updated? (PC + 4 vs branch target)
- What module is in each stage? (`if_stage.sv`, `id_stage.sv`, `ex_stage.sv`, `mem_stage.sv`, `wb_stage.sv`)

---

## 3. Pipeline Hazards

> Refer: [architecture.md](./architecture.md) — Forwarding, Load-use stall, Branch flush rows

### 3a. Data Hazards — Forwarding
- What is a data hazard? Give an example (RAW dependency).
- What is forwarding (bypassing)? How does it solve data hazards?
- What are the two forwarding paths in this design? (EX/MEM → EX, MEM/WB → EX)
- How does the forwarding unit decide which path to use?
- Can forwarding solve ALL data hazards? (No — load-use hazard needs a stall)
- Name the WAW and WAR hazards — do they occur in this 5-stage in-order pipeline? (No, only RAW)

### 3b. Structural Hazards
- What is a structural hazard? (resource conflict)
- Does this design have structural hazards? (No — separate instruction ROM and data RAM)
- What would happen with a unified instruction and data memory?

### 3c. Control Hazards — Branch Flush
- What is a control hazard?
- How does this design handle branches? (flush-on-taken: IF/ID and ID/EX flushed, PC redirected)
- What signal triggers the flush? (`pc_sel` from the EX stage)
- How many pipeline bubbles are introduced per taken branch? (2 instructions in IF and ID)
- What is the performance impact of branch flushing? How can it be improved?
- Difference between flush, stall, and bubble.

### 3d. Load-Use Hazard
- What is a load-use hazard and why can't forwarding alone solve it?
- How does `hazard_detection_unit.sv` detect it?
- What happens during a load-use stall? (PC and IF/ID are stalled, ID/EX gets a bubble/NOP)
- Give an example: `LW x1, 0(x2)` followed by `ADD x3, x1, x4`

---

## 4. Memory System and MMIO

> Refer: [memory_map.dot](../diagrams/memory_map.dot), [architecture.md](./architecture.md) — Memory and MMIO Map

- Explain the address decode scheme: how does `mem_stage.sv` select RAM vs UART vs perf counters?
  - `addr[31:28] == 0x0` → Data RAM
  - `addr[31:28] == 0x8` → UART MMIO
  - `addr[31:28] == 0xC` → Performance counters
- What is MMIO (Memory-Mapped I/O)? Why use it instead of port-mapped I/O?
- Draw the full memory map table from `architecture.md`
- What are byte write enables and why are they needed?
- What is the difference between memory-mapped and port-mapped I/O?

---

## 5. Subword Memory Operations

> Refer: [architecture.md](./architecture.md) — Subword load/store, Misaligned Access Policy

- What are subword operations? (`LB`, `LH`, `LBU`, `LHU`, `SB`, `SH`)
- Difference between `LB` (sign-extended) and `LBU` (zero-extended)
- Difference between `LH` (sign-extended) and `LHU` (zero-extended)
- How does the MEM stage handle byte and halfword extraction on loads?
- How does the MEM stage handle byte and halfword writes on stores? (byte enables)
- What is the misaligned access policy? (address silently truncated — no exception raised)
- Why is misaligned access not supported? (trap CSR infrastructure needed, Phase 5)

---

## 6. UART Peripheral

> Refer: [architecture.md](./architecture.md) — UART MMIO addresses

- What is UART? How does serial communication work?
- UART MMIO register map:
  - `0x80000000` — Status register (bit 0: TX busy, bit 1: RX data valid)
  - `0x80000004` — TX data register (write byte to transmit)
  - `0x80000008` — RX data register (read byte, clears RX valid)
- How does the program check if TX is ready before sending?
- How does the program check if RX data is available?
- What baud rate is used? What is the clock frequency?
- Explain the UART TX and RX modules (`uart_tx.sv`, `uart_rx.sv`)

---

## 7. Performance Counters

> Refer: [architecture.md](./architecture.md) — Performance counters section

- What performance counters are implemented?
  - `0xC0000000` — Cycle counter
  - `0xC0000004` — Instruction counter
  - `0xC0000008` — Stall counter
  - `0xC000000C` — Flush counter
- Are they read-only or read-write? (Read-only via MMIO)
- How do you compute CPI from these counters? (CPI = cycles / instructions)
- How do you compute IPC? (IPC = instructions / cycles)
- Why are stall and flush counters useful?

---

## 8. Special Instructions

> Refer: [architecture.md](./architecture.md) — FENCE/FENCE.I, ECALL/EBREAK, Illegal instruction

- What do `FENCE` and `FENCE.I` do in the RISC-V spec? How are they handled here? (NOP)
- What do `ECALL` and `EBREAK` do? How are they implemented? (halt signal, freezes pipeline)
- What opcode do ECALL/EBREAK use? (`OPCODE_SYSTEM` = `7'b1110011`)
- How is `funct12` used to distinguish ECALL from EBREAK?
- What happens to the pipeline when halt is asserted? (PC frozen, effective_stall active)
- What is illegal instruction detection? How is it implemented? (unknown opcodes set `illegal_instr` flag and trigger halt)

---

## 9. ALU and Control Unit

> Refer: [architecture.md](./architecture.md) — Module Inventory

- What operations does the ALU support? (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
- How does `alu_control.sv` decide the ALU operation?
- What is the role of `control_unit.sv`? How does it decode the instruction opcode into control signals?
- What control signals does the control unit generate? (ALU op, mem read/write, reg write, branch, jump, etc.)
- How does `imm_gen.sv` generate immediates for different instruction formats?

---

## 10. FPGA Implementation and Results

> Refer: [architecture.md](./architecture.md) — Implemented Proof Points, Top-Level Structure; session_2026-06-02_2345_kaustubh.md — Vivado Build Results

- Target board: PYNQ-Z2 / Zynq-7000 (`xc7z020clg400-1`)
- Clock: 125 MHz board clock → 25 MHz CPU clock via `PLLE2_BASE`
- What is a PLL? Why downclock from 125 MHz to 25 MHz?
- What is the role of `fpga_top.sv`? (board wrapper — reset sync, PLL, LEDs, UART pins)

### Utilization Numbers
| Resource | Used | Available | % |
|----------|------|-----------|---|
| LUTs | 7,127 | 53200 | 13.4% |
| Registers | 1737 | 106400 | 1.63% |
| BRAM | 1 | 140 | 0.71% |
| DSP | 0 | 220 | 0.00% |

- What does WNS (Worst Negative Slack) mean? (+5.265 ns = timing met)
- What is the difference between synthesis, implementation, and routing?
- What is a bitstream?

---

## 11. Simulation and Verification

> Refer: [roadmap.md](../roadmap.md) — Verification Evidence; [architecture.md](./architecture.md) — Implemented Proof Points

- What does the testbench (`tb_top.sv`) verify? (pipeline, perf counters, UART, halt, subword ops)
- What does "self-checking testbench" mean?
- Simulation result: `*** ALL TESTS PASSED (pipeline + perf counters + UART) ***`
- What is the difference between simulation and synthesis?
- What tests are run for subword operations?

---

## 12. Assembly and Program Flow

> Refer: [roadmap.md](../roadmap.md) — Phase 1; [architecture.md](./architecture.md) — Assembly/program flow

- How is the program loaded into instruction memory? (ROM-style via `program_rom_init.svh`)
- What assembler flow is used? (local RV32I assembler + build script → `program.mem`)
- What is the current demo program? (`asm/demo_perf_uart.s` — 240 memory words)
- Difference between ROM-style memory and loadable RAM

---

## 13. Future Roadmap (Know the Planned Phases)

> Refer: [roadmap.md](../roadmap.md) — Full roadmap; [simd_unit.dot](../diagrams/simd_unit.dot); [multicore.dot](../diagrams/multicore.dot)

### Phase 3: Debugging and Reliability
- What debug infrastructure is planned? (MMIO debug registers, trace buffer, assertions)

### Phase 4: UART Monitor and Program Loader
- What does the UART monitor do? (load, run, reset commands over serial)

### Phase 5: Traps, Exceptions, and Timer Interrupts
- What trap CSRs were implemented? (`mepc`, `mcause`, `mtvec`, `mstatus`)
- What is a trap handler? What is the trap entry/return flow?
- What is `MRET`?

### Phase 6: RV32M Extension
- What instructions did RV32M add? (`MUL`, `MULH`, `DIV`, `REM`, etc.)
- Single-cycle vs multi-cycle multiply — trade-offs

### Phase 7: Running C Programs
- What was needed to run C on bare metal? (linker script, startup code, stack, UART putchar)

### Phase 8: Branch Prediction
- What prediction schemes are used? (static not-taken, backward-taken/forward-not-taken, 2-bit predictor)
- How do you measure branch prediction improvement? (CPI before/after)

### Phase 9: Packed-SIMD Extension
> Refer: [simd_unit.dot](../diagrams/simd_unit.dot)
- What is packed SIMD? (parallel operations on sub-word data in a single register)
- Custom instructions: `PADD8`, `PSUB8`, `PMAXU8`, `PMINU8`, `PAVG8`
- Uses RISC-V `custom-0` opcode space
- Why packed SIMD inside 32-bit registers instead of a separate vector register file?

### Phase 13: Dual-Core SoC
> Refer: [multicore.dot](../diagrams/multicore.dot)
- 2 cores, shared BRAM, mailbox, round-robin arbiter
- No caches, no coherency
- Why is dual-core deferred to the end? (depends on bus, traps, monitor, software)

---

## 14. Common Viva Questions

- Draw the complete 5-stage pipeline with all control signals.
- Explain a data hazard with a code example and show how forwarding resolves it.
- Explain a load-use hazard and why a stall is needed.
- What happens in the pipeline when a branch is taken?
- What is the difference between a stall and a flush?
- How do you calculate CPI? What is the ideal CPI?
- What is the difference between RISC and CISC?
- Why use SystemVerilog over Verilog?
- What is the difference between blocking (`=`) and non-blocking (`<=`) assignments?
- What is an FPGA? How does it differ from an ASIC?
- What is the Zynq-7000? (SoC with ARM PS + Xilinx PL)
- What is the difference between the PS (Processing System) and PL (Programmable Logic)?
- Why is this design on the PL side and not the PS?

---

## 15. Key Diagrams to Practice Drawing

> Render from `.dot` files with Graphviz or sketch by hand:

1. **Pipeline datapath** — from [pipeline.dot](../diagrams/pipeline.dot)
2. **Memory map** — from [memory_map.dot](../diagrams/memory_map.dot)
3. **Planned SIMD unit** — from [simd_unit.dot](../diagrams/simd_unit.dot)
4. **Planned dual-core** — from [multicore.dot](../diagrams/multicore.dot)
5. **Instruction formats** — R, I, S, B, U, J type field layouts
6. **Forwarding paths** — EX/MEM and MEM/WB back to EX stage inputs
7. **Hazard stall logic** — load-use detection and stall/bubble insertion
