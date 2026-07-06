# Instruction Support Matrix

> **Last updated:** 2026-06-28  
> **Source of truth:** docs/architecture/overview.md + RTL source  
> **Legend:** ✅ Complete | ❌ Not Implemented | ⏳ Pending FPGA test

## Summary
| Metric                        | Count |
|-------------------------------|-------|
| RV32I total instructions      | 47    |
| Implemented                   | 47    |
| Simulation tested             | 47    |
| FPGA verified (on hardware)   | 0 (Deferred) |

### RV32I — Arithmetic
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| ADD         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| ADDI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| SUB         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |

### RV32I — Comparisons
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| SLT         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Signed set less than |
| SLTI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Signed set less than imm |
| SLTU        | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Unsigned set less than |
| SLTIU       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Unsigned set less than imm |

### RV32I — Logic
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| AND         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| ANDI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| OR          | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| ORI         | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| XOR         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |
| XORI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Verified in regression tb |

### RV32I — Shifts
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| SLL         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift left logical |
| SLLI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift left logical imm |
| SRL         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift right logical |
| SRLI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift right logical imm |
| SRA         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift right arithmetic |
| SRAI        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Shift right arithmetic imm |

### RV32I — Branches
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| BEQ         | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch equal |
| BNE         | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch not equal |
| BLT         | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch less than |
| BGE         | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch greater or equal |
| BLTU        | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch less than unsigned |
| BGEU        | B      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Branch greater or equal uns. |

### RV32I — Jumps
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| JAL         | J      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Jump and link |
| JALR        | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Jump and link register |

### RV32I — Loads
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| LB          | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load byte (sign-extended) |
| LH          | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load halfword (sign-extended) |
| LW          | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load word |
| LBU         | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load byte unsigned |
| LHU         | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load halfword unsigned |

### RV32I — Stores
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| SB          | S      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Store byte |
| SH          | S      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Store halfword |
| SW          | S      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Store word |

### RV32I — Upper Immediates
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| LUI         | U      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Load upper immediate |
| AUIPC       | U      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Add upper immediate to PC |

### RV32I — System / CSR
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| FENCE       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Decoded as NOP |
| FENCE.I     | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Decoded as NOP |
| ECALL       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Halts pipeline |
| EBREAK      | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Halts pipeline |
| CSRRW       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |
| CSRRS       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |
| CSRRC       | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |
| CSRRWI      | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |
| CSRRSI      | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |
| CSRRCI      | I      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 5 |

### M Extension — Multiply / Divide
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| MUL         | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 6 |
| MULH        | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 6 |
| MULHU       | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 6 |
| MULHSU      | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | Phase 6 |
| DIV         | R      | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Deferred to Phase 6 |
| DIVU        | R      | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Deferred to Phase 6 |
| REM         | R      | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Deferred to Phase 6 |
| REMU        | R      | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Deferred to Phase 6 |

### Packed-SIMD Extension (custom-0 opcode 0001011)
| Instruction | Format | Implemented | Sim Tested | FPGA Verified | Notes |
|-------------|--------|:-----------:|:----------:|:-------------:|-------|
| PADD8       | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | 4x 8-bit unsigned add |
| PSUB8       | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | 4x 8-bit unsigned sub |
| PMAXU8      | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | 4x unsigned 8-bit max |
| PMINU8      | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | 4x unsigned 8-bit min |
| PAVG8       | R      | ✅ Complete  | ✅ Complete | ⏳ Pending    | 4x unsigned 8-bit avg |