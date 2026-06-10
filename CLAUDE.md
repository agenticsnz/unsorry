# unsorry Project Guidelines

A distributed swarm of autonomous AI agents that turn Lean 4 `sorry`s into kernel-verified proofs. Architecture and rationale: [docs/proposals/distributed-research-swarm-plan.md](docs/proposals/distributed-research-swarm-plan.md).

## Development Protocols

All development work must follow the protocols in [`docs/protocols.md`](docs/protocols.md) (vendored from [cgbarlow/protocols](https://github.com/cgbarlow/protocols), adopted by ADR-001). These are non-negotiable: ADRs for every significant decision (`docs/adrs/`, WH(Y) format), specs for every implementation ADR (`docs/adrs/specs/`), TDD, feature branches (no direct commits to `main`), Keep-a-Changelog + semver with a GitHub release per tag, production-ready code only, DRY, latest stable dependencies, README accuracy.

The optional Svelte `{@html}` protocol (§13) does not apply — there is no frontend.

## Dev commands

- `lake build` — build both packages (`UnsorryLibrary` = verified library under `library/`, zero-sorry bar; `UnsorryGoals` = open goals under `goals/`, sorries expected). Toolchain auto-installs via elan from `lean-toolchain`; mathlib arrives as a binary cache (`lake exe cache get` runs via the require hook — never build mathlib from source, ADR-002).
- `lake build UnsorryLibrary --wfail` — the Gate A strictness bar locally.
- `python3 -m tools.gate_b validate .` — Gate B locally.
- `python3 -m pytest tools -q` — full Python test suite.
- `./swarm/agent.sh --self-test` — agent loop self-tests.

## Key structural decisions

- **Claims live on the dedicated unprotected `claims` branch**, never on `main` (ADR-004). First-push-wins via git's atomic non-fast-forward rejection.
- **Merges to `main` are autonomous** once required checks (Gate A soundness, Gate B hygiene) are green — `gh pr merge --auto --squash`, no required reviewers (ADR-005). Never use admin bypass as a normal path.
- **mathlib4 is pinned to release tags** and never built from source; toolchain bumps only in dedicated PRs (ADR-002).
- **Coordination artifacts are AISP**; the load-bearing validator is in-repo (`tools/gate_b/`, lands with its implementation PR), upstream `aisp-validator` is advisory only (ADR-003).
