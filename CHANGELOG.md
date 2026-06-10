# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `swarm/protocol.aisp` — the swarm contract (validates ◊⁺⁺ Platinum with aisp-validator 0.3.0); SPEC-003-D
- `swarm/AI_GUIDE.md` — AISP 5.1 grammar vendored from bar181/aisp-open-core (MIT, attribution: Bradley Ross)
- Record schemas: goal (SPEC-003-A), claim (SPEC-003-B), translation + decomposition + normalization/content-addressing (SPEC-003-C), claim lifecycle + reaper (SPEC-004-A)
- `claims/README.md` — pointer to the claims-branch mechanism (ADR-004)
- Gate B fixture corpus under `tools/gate_b/tests/fixtures/` (valid trees + 12 violation trees, TDD seed for the validator)

## [0.1.0] - 2026-06-10

### Added

- Vendored development protocols at `docs/protocols.md` (from [cgbarlow/protocols](https://github.com/cgbarlow/protocols)), adopted as binding (ADR-001)
- ADR-001 — Adopt Development Protocols
- ADR-002 — Lean 4 + mathlib4 Pinned to Release Tags
- ADR-003 — AISP Coordination Format with In-Repo Validation
- ADR-004 — Claims on a Dedicated Branch, First-Push-Wins
- ADR-005 — Autonomous Merge Policy
- `CLAUDE.md` development guide
- This changelog
