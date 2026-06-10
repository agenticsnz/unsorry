# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-06-10

### Added

- `tools/gate_b/` — in-repo Gate B validator (GB001–GB018), CI workflow `gate-b.yml` (required job + advisory upstream aisp-validator job)
- `tools/gate_b/reaper.py` + `reaper.yml` — expired-claim reaper on a 15-min cron against the orphan `claims` branch
- `tools/fidelity/` — statement normalizer (NFC, canonical symbols, α-rename) + differ; content-address shas
- `swarm/agent.sh` — Phase-0 translation-only agent loop (ADR-007, SPEC-007-A)
- `swarm/prompts/translate.md` — one-shot translation prompt with pinned symbol palette
- `backlog/` seeded with 10 known-true statements (3 planted paraphrase pairs + 4 singletons) and matching `goals/` records
- ADR-007 Agent Identity and Budgets; SPEC-007-A Agent Loop Script
- Orphan `claims` branch created (ADR-004)

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
