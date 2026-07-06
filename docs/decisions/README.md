# Architecture Decision Records

ADRs document significant design decisions: what was chosen, what alternatives
were considered, and why. They are immutable records — superseded decisions get
a new ADR, not an edit to the old one.

## ADR Lifecycle
`Proposed` → `Accepted` → `Superseded` | `Deprecated`

## Naming Convention
`NNN_short_snake_case_title.md` where NNN is zero-padded (001, 002, ...)

## When to Write an ADR
- Choosing between two or more non-trivial architectural options
- Deciding to defer or omit a feature intentionally
- Any decision that a future contributor might question or want to revisit

## ADR Index
| ID  | Title                        | Status   | Date       |
|-----|------------------------------|----------|------------|
| [001](001_initial_docs.md) | Initial Documentation System | Accepted | 2026-06-03 |
| [002](002_uart_mmio_layout.md) | UART MMIO Layout             | Accepted | 2026-06-03 |
| [003](003_hazard_strategy.md) | Hazard Handling Strategy     | Accepted | 2026-06-03 |
| [004](004_exception_handling.md) | Exception Handling Approach  | Accepted | 2026-06-03 |
| [005](005_cache_decision.md) | Cache Architecture Decision  | Accepted | 2026-06-03 |
