# Getting Started — RISC-V Pipeline Project

This guide is for someone with **minimal coding background** who wants to continue developing this FPGA processor project using an AI coding assistant (CommandCode or similar). You don't need to write code — you tell the AI what you want, and it reads the project, does the work, and keeps everything documented automatically.

---

## Table of Contents

1. [What Is This Project?](#what-is-this-project)
2. [What You Need Installed](#what-you-need-installed)
3. [Folder Structure — Where Everything Lives](#folder-structure--where-everything-lives)
4. [How the AI Agent Works With This Project](#how-the-ai-agent-works-with-this-project)
5. [The Prompt Template — What to Tell the AI](#the-prompt-template--what-to-tell-the-ai)
6. [What the AI Does During a Session](#what-the-ai-does-during-a-session)
7. [Checking What the AI Did — Session Logs and Git History](#checking-what-the-ai-did--session-logs-and-git-history)
8. [Common Tasks and How to Ask For Them](#common-tasks-and-how-to-ask-for-them)
9. [The 13-Phase Roadmap — Where the Project Is Going](#the-13-phase-roadmap--where-the-project-is-going)
10. [Safety Nets — Git, Hooks, and Why Docs Stay Fresh](#safety-nets--git-hooks-and-why-docs-stay-fresh)
11. [Troubleshooting](#troubleshooting)

---

## What Is This Project?

You have a **computer processor** designed inside an **FPGA chip** (a chip you can reprogram). Think of it like this:

- A normal computer (like your laptop) has a fixed CPU inside it — you can't change how it works.
- An **FPGA** is a blank chip where you can build your own CPU from scratch by writing code.
- This project has built a **RISC-V processor** — a simple but real CPU — on a board called the **PYNQ-Z2**.

**Current status:** The processor is designed, programmed onto the FPGA, and passes all simulation tests (computer-simulated tests, not physical). It has 5 pipeline stages (fetches instructions, decodes them, executes, reads memory, writes results), talks through a serial port (UART, like old-school terminal), counts its own performance, and can be controlled by a monitor program over that serial port.

**What's left:** Physical testing on the real PYNQ-Z2 board (when available), adding trap/exception handling, multiply/divide instructions, and eventually running small C programs.

---

## What You Need Installed

These are already set up on your machine (the project wouldn't exist without them), but if you move to a new computer, reinstall these:

| Software | What It's For | How to Check It's Installed |
|----------|---------------|---------------------------|
| **Git** (with Git Bash) | Tracks changes. Every AI session is committed like a save point. | Open Git Bash, type `git --version` |
| **Python 3.x** | Runs helper scripts (program loader). | Type `python --version` in terminal |
| **Xilinx Vivado** (2024.x or 2025.x) | The FPGA design software. Builds and simulates the processor. | Look for "Vivado" in your Start Menu |
| **CommandCode** (or any AI coding assistant) | The AI agent that does the work. | Already on your machine. |

**Important:** Vivado MUST be installed for simulations and bitstream generation. The AI can do RTL code changes without it, but it can't test them.

---

## Folder Structure — Where Everything Lives

When you open the project folder (`riscv32-processor`), here's what you'll find:

```
riscv32-processor/
│
├── docs/                          ← 📚 ALL DOCUMENTATION (the brain of the project)
│   ├── GETTING_STARTED.md         ← 👈 YOU ARE HERE — this guide
│   ├── ai_context.md              ← 🔴 THE PRIMARY BRAIN. AI reads this first.
│   │                                Project state, priorities, file list, rules.
│   ├── board_arrival_checklist.md ← Mandatory physical verification
│   ├── known_issues.md            ← Open bugs and limitations
│   ├── no_board_execution_plan.md ← What to do without the board
│   ├── README.md                  ← Project landing page
│   ├── roadmap.md                 ← 13-phase long-term plan
│   ├── architecture/              ← How the processor is built
│   │   ├── instruction-set.md     ← Which RISC-V instructions work
│   │   ├── memory-map.md          ← Address spaces and internal bus
│   │   ├── overview.md            ← Full technical design
│   │   ├── uart-monitor.md        ← Serial terminal command reference
│   │   └── viva_prep.md           ← Notes and prep
│   ├── decisions/                 ← Architecture Decision Records
│   ├── diagrams/                  ← Graphviz source files (.dot)
│   ├── guides/                    ← Tutorials and step-by-step verification guides
│   ├── hardware/                  ← Hardware specific guides
│   │   ├── board_arrival_shopping_list.md ← Required purchases
│   │   └── setup.md               ← Board setup guide (pins, UART wiring)
│   ├── updates/                   ← 📝 SESSION LOGS (every AI session leaves one)
│   │   ├── README.md              ← Index of all sessions
│   │   └── session_2026-06-04_*.md ← Individual session records
│   └── verification/              ← Test results and performance data
│
├── riscv_pipeline_offline/        ← 🔧 THE ACTUAL PROCESSOR DESIGN
│   └── riscv_pipeline_offline.srcs/
│       └── sources_1/imports/src/ ← ALL THE VERILOG CODE (.sv files)
│           ├── top.sv              ← Main CPU — connects all 5 stages
│           ├── fpga_top.sv         ← Board wrapper — PYNQ-Z2 pins, PLL, UART mux
│           ├── if_stage.sv         ← Instruction Fetch (reads program memory)
│           ├── id_stage.sv         ← Instruction Decode (figures out what to do)
│           ├── ex_stage.sv         ← Execute (ALU, branches, calculations)
│           ├── mem_stage.sv        ← Memory (reads/writes data RAM, MMIO)
│           ├── wb_stage.sv         ← Writeback (stores results to registers)
│           ├── pipeline_registers.sv ← Connects one stage to the next
│           ├── forwarding_unit.sv  ← Speeds up by forwarding data early
│           ├── hazard_detection_unit.sv ← Detects load-use stalls
│           ├── control_unit.sv     ← Main decoder — opcode → control signals
│           ├── alu.sv              ← Arithmetic Logic Unit (math operations)
│           ├── imm_gen.sv          ← Immediate value generator
│           ├── reg_file.sv         ← 32 registers (x0-x31)
│           ├── data_mem.sv         ← Data RAM
│           ├── instr_mem.sv        ← Instruction memory (program + loader)
│           ├── uart_monitor.sv     ← Serial terminal command interface
│           ├── uart_peripheral.sv  ← UART TX/RX wrapper
│           ├── uart_tx.sv          ← UART transmitter
│           └── uart_rx.sv          ← UART receiver
│       └── sim_1/imports/         ← Simulation testbench
│           └── tb_top.sv           ← Self-checking test harness
│
├── tools/                         ← 🛠️ HELPER SCRIPTS
│   ├── check_docs_stale.ps1       ← Doc freshness checker (run by hooks)
│   ├── install_hooks.ps1          ← Installs git hooks after git init
│   └── mem_to_load_commands.py    ← Program loader (converts .mem → UART commands)
│
├── results/                       ← 📊 PERFORMANCE METRICS AND TEST OUTPUTS
│
├── .gitignore                     ← Files git should ignore
├── .githooks/                     ← Centralized hook directory (may be empty)
└── .git/                          ← Git version control data
```

**Rule of thumb:**
- `docs/` = documentation and project memory
- `riscv_pipeline_offline/.../src/*.sv` = the actual processor code
- `tools/` = helper scripts
- `docs/ai_context.md` = what the AI reads first

---

## How the AI Agent Works With This Project

Every time an AI agent opens this project, it follows a **boot sequence** (written in `docs/ai_context.md`):

1. **Reads** `ai_context.md` — learns the current project state, what's done, what's next
2. **Reads** `status.md` and `architecture.md` — understands the technical details
3. **Reads the latest session log** — learns what the previous agent did
4. **Does the work you asked for**
5. **Before exiting**, completes a mandatory 6-item checklist:
   - Updates `ai_context.md` (project state, priorities, recent updates)
   - Updates `docs/roadmap.md`
   - Writes a session log to `docs/updates/session_<date>_<agent>.md`
   - Appends a link in `docs/updates/README.md`
   - Runs `check_docs_stale.ps1` to verify everything is fresh

This means **you never lose track** of what the AI did. Every session leaves a paper trail.

**Important:** If the AI ever says "done" without updating the docs, remind it to re-read `docs/ai_context.md` and complete the PRE-EXIT CHECKLIST.

---

## The Prompt Template — What to Tell the AI

When you start a new session with the AI, use this template. Copy the entire block and paste it into the AI chat.

### ⭐ BASIC PROMPT (Copy This)

```
I'm working on a 5-stage RV32I pipelined processor on the PYNQ-Z2 FPGA.
The project is at: <repo>

Before doing anything, read these files in order:
1. docs/ai_context.md
2. docs/roadmap.md
3. docs/architecture/overview.md
4. docs/roadmap.md
5. docs/updates/ - the most recent session log

[INSERT YOUR REQUEST HERE - see examples below]

After completing the work, update:
- docs/ai_context.md (project state, priorities, recent updates)
- docs/roadmap.md
- Write a session log to docs/updates/
- Append to docs/updates/README.md
```

### Example Requests

**"Show me what's done and what's left":**
```
Tell me the current project status. What phase are we on? What's the next thing to do?
```

**"Run the simulation":**
```
Open Vivado, run the xsim simulation with fpga_top as the top module, and tell me if all tests pass.
```

**"Fix a bug":**
```
The UART monitor's 'regs' command sometimes shows wrong values for x0. Investigate and fix the issue.
```

**"Add a new feature (Phase 5)":**
```
Start Phase 5: Implement trap handling. Add mepc, mcause, and mtvec CSRs. 
When the CPU hits ECALL/EBREAK/illegal instruction, save the PC to mepc, 
write the cause to mcause, and jump to mtvec.
```

**"Test a new program on the processor":**
```
Write a new assembly program that calculates the first 10 Fibonacci numbers, 
store them in memory starting at address 0x100, then print them over UART.
Add it as a new test case in the testbench.
```

**"Understand the architecture":**
```
Explain how the 5-stage pipeline works in this processor. 
Walk me through what happens to a single ADD instruction.
```

---

## What the AI Does During a Session

Here's what happens behind the scenes when you give the AI a task:

1. **Boot-up:** The AI reads `ai_context.md` (the "primary brain"), then reads the planning docs, then the latest session log. This takes about 10-30 seconds.

2. **Investigation:** If the task is vague ("fix the UART bug"), the AI will explore the Verilog files, grep for relevant code, read simulation logs, and understand the problem before touching anything.

3. **Implementation:** The AI modifies files directly. You'll see it editing `.sv` (Verilog), `.ps1` (PowerShell), `.py` (Python), and `.md` (Markdown) files.

4. **Testing:** After making changes, the AI will:
   - Run Vivado xsim simulation to verify the changes
   - Check for compilation errors
   - Verify that existing tests still pass

5. **Documentation Update (MANDATORY):** Before the AI exits:
   - Updates `docs/ai_context.md` with the new state and what was done
   - Updates `docs/roadmap.md` with completed tasks
   - Creates `docs/updates/session_YYYY-MM-DD_HHMM_agentname.md`
   - Appends a link to `docs/updates/README.md`
   - Runs the doc freshness checker to verify everything

6. **Git Commit:** The AI may commit the changes to git (like a save point).

**One session = one task** is a good rule. Don't ask for 5 different things in one message — the AI works best with one focused request at a time.

---

## Checking What the AI Did — Session Logs and Git History

### Session Logs

Every AI session leaves a file in `docs/updates/`. The filename tells you when and who:

```
session_2026-06-04_1028_codex.md
         ^^^^^^^^ ^^^^ ^^^^^
         date     time agent
```

Each log contains:
- **Machine Fingerprint** — which computer, who was logged in
- **Work Summary** — what was accomplished (bullet points)
- **Files Created** — new files the AI made
- **Files Modified** — existing files the AI changed
- **Docs Updated** — which documentation files were refreshed
- **Next Steps** — what the AI recommends doing next

To see the full index: open `docs/updates/README.md`

### Git History

Every change is committed to git (like Windows File History, but for code). To see all changes:

```bash
git log --oneline    # Short list of all commits
git log --stat       # Full list showing which files changed
git show <commit>    # Show the full details of one commit
```

**Each commit** corresponds to a code change. The commit message tells you what was done.

### If You Need to Go Back

```bash
git log --oneline    # Find the commit hash
git checkout <hash>  # Temporarily go back to that state
git checkout master  # Return to latest
```

---

## The 13-Phase Roadmap — Where the Project Is Going

The project is organized into 13 phases. Think of them as chapters in a book:

| Phase | Name | Status | What It Means |
|-------|------|--------|---------------|
| 0 | Hardware Demo | 50% (deferred) | Bitstream exists. Waiting for the physical PYNQ-Z2 board to do the real test. |
| 1 | Software Tooling | Regression baseline locked (9/9 PASS, see tools/run_phase1_regression.ps1). Still needs standalone ALU/branch/load-store/UART/perf-counter test programs and expected UART output files. | C toolchain builds 9 programs from source; expected-output regression in tests/expected/ verifies bit-identical reproduction. |
| 2 | RV32I Base | ✅ 100% | All basic RISC-V instructions work. Simulated and verified. |
| 3 | Debug Features | ✅ 100% | Debug registers and trace buffer let you see what the CPU is doing. |
| 4 | UART Monitor | 85% | A serial terminal interface with 7 commands (load, run, reset, etc.). All RTL code written. Needs physical board test. |
| 5 | Traps & Timers | 0% (next) | Exception handling and timer interrupts — the next phase to work on. |
| 6 | Multiply/Divide | 0% | RV32M extension (hardware multiply and divide). |
| 7 | Run C Programs | 0% | Toolchain for compiling C code to run on this processor. |
| 8 | Branch Prediction | Complete in simulation — CPI=1.258 (see results/phase8_cpi_metrics.txt) | 64-entry BHT dynamic branch predictor, CPI data captured from branch_sort.mem. |
| 9 | Custom Packed-SIMD Extension | Complete in simulation — 9/9 tb_phase9.sv tests PASS, verified 2026-06-28 | Custom "packed" instructions for parallel data processing. |
| 10 | Benchmark Demos | 0% | Real workloads to measure performance. |
| 11 | Memory System | 15% | Clean up the bus and peripheral architecture. |
| 12 | Optional Peripherals | Complete in simulation — 9/9 tb_phase12.sv tests PASS (incl. waveform-verified PWM disable), verified 2026-06-28 | LED control, button/switch input, PWM peripheral implemented. |
| 13 | Dual-Core | 0% | Two CPUs working together. Very ambitious, do last. |

**Current next step:** Phase 5 (traps and timer interrupts) — but first, Phase 4 needs physical board verification when the PYNQ-Z2 is available.

---

## Safety Nets — Git, Hooks, and Why Docs Stay Fresh

This project has **three layers of protection** to make sure no work gets lost and all changes are documented:

### Layer 1: Git Version Control

Every code change is committed to git. Think of it like save points in a game — you can always go back to a previous state. The AI does this automatically.

### Layer 2: Git Hooks (Pre-Commit and Pre-Push)

Before the AI can save (commit) or upload (push) changes, a script called `check_docs_stale.ps1` runs. It checks:
- Has the session log been updated after the last code change?
- Is the session log indexed in `docs/updates/README.md`?
- Are `docs/ai_context.md` and `docs/roadmap.md` fresher than the last session log?

If any check fails, the commit is **BLOCKED**. The AI must fix the documentation before it can proceed. This is the mechanical enforcement — no human intervention needed.

### Layer 3: The PRE-EXIT CHECKLIST in ai_context.md

When the AI reads `docs/ai_context.md`, the first thing it sees is a mandatory checklist. It cannot claim "done" until all 6 items are checked off. If the AI skips this, it's breaking its own instructions — remind it to re-read the file.

### What If a Git Hook Blocks Me?

If you're doing emergency work and need to skip the check:

```bash
git commit --no-verify   # Skip pre-commit hook
git push --no-verify     # Skip pre-push hook
```

**Only use this in emergencies.** The hooks exist to protect the project from undocumented changes.

---

## Troubleshooting

### "The AI says the checker failed and it can't commit"

This means the AI modified source files but didn't write a session log. Tell the AI:
> "Write a session log to docs/updates/, append the link to docs/updates/README.md, touch the timestamp, then rerun check_docs_stale.ps1."

### "The git hooks aren't working"

Run this in Git Bash or PowerShell:
```powershell
powershell -File tools/install_hooks.ps1
```

### "Vivado isn't on PATH"

The AI will tell you to open Vivado manually or set the PATH. You can also launch the AI from Vivado's Tcl Console if needed.

### "I want to see what the AI changed without reading code"

- Open `docs/updates/README.md` — click the latest session link
- Read the "Work Summary" section — it's written in plain English
- Look at "Files Modified" to see which files were touched

### "I don't understand what a Verilog file does"

Ask the AI: "Explain what `if_stage.sv` does in simple terms." It will give you a plain-English explanation.

### "The AI made a mistake, I want to undo"

```bash
git log --oneline              # Find the commit BEFORE the mistake
git reset --hard <good-commit> # Go back to before the mistake
```

**Warning:** `git reset --hard` permanently deletes changes after that point. Only use this if you're sure.

---

## Quick Reference Card

| Task | Command / Prompt |
|------|-----------------|
| Start a new AI session | Paste the [prompt template](#-basic-prompt-copy-this) with your request |
| Check recent work | Open `docs/updates/README.md` |
| See all git commits | `git log --oneline` |
| Install/reinstall hooks | `powershell -File tools/install_hooks.ps1` |
| Check doc freshness manually | `powershell -File tools/check_docs_stale.ps1 -Strict` |
| Undo last commit | `git reset --soft HEAD~1` |
| Skip hook (emergency) | `git commit --no-verify` |
| See current project status | Read `docs/ai_context.md` section "Current Project State" |
| See what's next | Read `docs/ai_context.md` section "Next Priorities" |
| Understand the design | Read `docs/architecture/overview.md` |

---

*This guide was written for the project owner on 2026-06-04. If the project structure changes significantly, ask the AI to update this file.*
