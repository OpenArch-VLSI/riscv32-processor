# Changelog

All notable changes to this project are documented here.

## [2026-06-22] Documentation Overhaul

### Fixed
- Stripped leaked tool instructions from 5 ADR files and 4 session logs.
- Replaced corrupted ADRs with real architectural decision records.
- Removed dead links to non-existent session files.
- Replaced phantom generator banners with manual-maintenance notices.
- Removed personal filesystem paths from documentation and TCL scripts.

### Changed
- Reconciled utilization numbers to canonical post-Phase-10 values:
  Slice LUTs 7,127 / 53,200 (13.4%), WNS +5.265 ns.
- Updated instruction support matrix: 47 implemented (was 41).
- Updated verification status with Phase 5-10 test results.
- Refreshed architecture overview with BHT, CSR, timer, SIMD modules.
- Merged `status.md` and `roadmap.md` into unified `docs/roadmap.md`.
- Renamed `Docs/` to `docs/` (lowercase) for cross-platform compatibility.
- Renamed key files for consistency:
  `architecture.md` -> `overview.md`,
  `instruction_support.md` -> `instruction-set.md`,
  `verification.md` -> `test-plan.md`,
  `hardware_setup.md` -> `setup.md`.
- Updated `README.md` to reflect Phase 10 feature set.

### Added
- Rendered SVG diagrams from `.dot` sources (pipeline, memory map, SIMD, multicore).
- Extracted `memory-map.md` as standalone reference.
- Created `docs/README.md` documentation index.
- Created this `CHANGELOG.md`.
