# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Phase-2 Stage B — affinity-weighted, gap-based goal selection (ADR-010, SPEC-010-A): selection now ranks claimable goals by (affinity desc, gap asc, id asc), skipping below-τ_v patterns; +1 affinity on a merge (folded into the prove PR), -10 on a failed attempt (a gated demote PR); affinity is an advisory `aff` field on goal records that degrades to 0 on absence/garbage. 5 new agent self-tests (24 total). ADR-010 Accepted
- Phase-2 plan (proposed): [`docs/proposals/phase2-plan.md`](docs/proposals/phase2-plan.md), candidate-target shortlist [`docs/phase2-targets.md`](docs/phase2-targets.md), and three ADRs — ADR-009 (goal decomposition on prove-budget exhaustion), ADR-010 (affinity-weighted gap-based selection), ADR-011 (statement-binding gate, closing the meaningfulness gap the W3 red team exposed)
- README: "Why this matters" and "The goal, honestly" — the purpose, value, and honest limits of the work, with Phase-2 links


## [1.0.0] - 2026-06-10

### Added

- Contributor-readiness checklist evidence (`docs/metrics/checklist-evidence.md`): all six items (a)–(f) adversarially verified `sufficient` at high confidence; the public contributor invitation opens (#79)
- README quickstart verified to run clean from a fresh clone (checklist item (f))


## [0.6.0] - 2026-06-10

### Added

- Phase-1 swarm run 001 (W4): 3 prover agents drove `claude` to write real Lean proofs; 3 theorems proved and merged into the verified library by a non-author agent (`prover-alpha`) end-to-end; metrics at `docs/metrics/phase1-run-001.{md,json}` (#75)
- First merged proofs: `int_add_neg_thm`, `int_neg_neg_thm`, `and_comm_imp_thm` in `library/Unsorry/`

### Fixed

- Prove cycle recompiled mathlib from source: the PR worktree has no `.lake`, so verification rebuilt all of mathlib and blew the attempt budget (phase1-run-001). `run_proof` now restores the prebuilt cache (`lake exe cache get`, best-effort) in the worktree before the first build (SPEC-007-A)

### Added

- Phase-1 backlog: 20 known-true prove-phase goals (`goals/*.aisp` + statement `.lean` files carrying `sorry`) spanning Nat/Int algebra, order, divisibility, gcd, parity, list and propositional facts; minimal imports, all type-check, all audit clean under `--allow-sorry`

## [0.5.0] - 2026-06-10

### Added

- Gate A red-team round 001 (W3): 9 adversarial bypass vectors as real PRs (#56–#64); 9/9 blocked after the autoImplicit fix. Evidence at `docs/metrics/gate-a-redteam-001.md` — checklist item (a)

### Fixed

- Gate A autoImplicit bypass found by the W3 red team (PR #64): a `set_option autoImplicit true` split across lines defeated the per-line diff lint and let a vacuous (sound-but-meaningless) theorem into `library/`. New authoritative whole-file, whitespace-collapsed check `tools/gate_a/check_library_options.py` (12 tests) — `autoImplicit`/`relaxedAutoImplicit` re-enables in the verified library now fail Gate A regardless of source formatting (SPEC-006-B)

## [0.4.0] - 2026-06-10

### Added

- Lean 4 project: `lean-toolchain` pinned to `leanprover/lean4:v4.30.0`, `lakefile.toml` with two packages — `UnsorryLibrary` (verified, zero-sorry) and `UnsorryGoals` (sorries expected) — mathlib required at release tag `v4.30.0`, manifest committed (ADR-002, ADR-006)
- First verified lemma `nat_zero_lt_succ` with content-addressed index entry `library/index/4c71a8b4….aisp` (goal `nat-zero-lt-succ`)
- ADR-006 Gate A Soundness Enforcement; SPEC-006-A (axiom audit executable), SPEC-006-B (gate-a workflow)
- `lake exe axiom_audit` — per-declaration transitive axiom audit (whitelist `propext`/`Classical.choice`/`Quot.sound`, `--allow-sorry` for goals); `AuditFixtures` adversarial lib + 16-assertion acceptance script `tools/gate_a/test_audit.sh`
- **Gate A live**: `gate-a.yml` (always-report detect job; lean-action mathlib cache; `--wfail` library build; axiom audit; leanchecker kernel replay; audit self-test; textual lint belt; axiom-footprint artifact + sticky PR comment) — required status check on `main` alongside `gate-b` (ADR-005, ADR-006, SPEC-006-B)

## [0.3.0] - 2026-06-10

### Added

- Phase-0 swarm trial run 001: four agent identities on two models, 39 claim cycles, 38 autonomous PR merges, TTL reap observed; metrics + evidence at `docs/metrics/phase0-run-001.{md,json}` (#47)
- `docs/metrics/METRICS.md` — metric definitions and run index

### Fixed

- Translation convergence race under overlapping PRs — convergence sweep, SPEC-007-A step 1b (#8)
- Fidelity normalizer false positives on redundant parentheses — normalization step 5; both trial flags adjudicated equivalent and resolved (#50)

### Changed

- All 10 Phase-0 backlog goals now `translated`; all 3 planted paraphrase pairs converged to byte-equal content addresses
- README roadmap: Phase 0 ticked with metrics link

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
