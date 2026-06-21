# swarm/

The coordination contract every agent loads at session start.

| File | What |
|---|---|
| `protocol.aisp` | The swarm contract: claim semantics, TTLs, budgets, fidelity gate, decomposition rules, CI policy. Normative — see [SPEC-003-D](../docs/adrs/specs/SPEC-003-D-Swarm-Contract.md). Validates at ◊⁺⁺ Platinum (aisp-validator 0.3.0). |
| `AI_GUIDE.md` | The AISP 5.1 grammar reference, vendored verbatim from [bar181/aisp-open-core](https://github.com/bar181/aisp-open-core) (MIT License, © 2026 Bradley Ross, inventor of AISP — attribution per upstream license). Vendored so agent sessions need no network fetch; re-vendor deliberately when upstream releases a new spec version. |
| `agent.sh` | The prove/translate agent loop (lands with PR-6 / Phase 0). |
| `run.sh` | **Recommended one-command launcher** for the governed `--prove` flow ([ADR-058](../docs/adrs/ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md)): runs one resilient prover (`supervise.sh --prove`) and one metered dispatcher (`agent.sh --dispatch-queue`) together, stopped together on exit. Run exactly one dispatcher; add more provers with `supervise.sh --prove`. **If the scheduled `queue-dispatcher` workflow is enabled it already _is_ the one dispatcher — run a prover only (`supervise.sh --prove`) instead of `run.sh`.** Run from a **fork** (no upstream write) and it auto-enters fork-native mode ([ADR-068](../docs/adrs/ADR-068-Fork-Native-Contribution-Mode.md)): prover-only, claimless, submitting cross-repo PRs the upstream re-verifies + auto-merges (no dispatcher). |
| `sourcing.sh` | The goal-sourcing runner ([ADR-062](../docs/adrs/ADR-062-Swarm-Goal-Sourcing-Runner.md), [SPEC-062-A](../docs/adrs/specs/SPEC-062-A-Swarm-Goal-Sourcing-Runner.md)): fires up Claude to run one cycle of the `unsorry-goal-sourcing` skill (ADR-060) — pick a hard theme, gate candidates, promote triples, open one `chore(sourcing):` PR. The sourcing counterpart to `agent.sh`; bounded by default. `--if-pool-empty` ([ADR-067](../docs/adrs/ADR-067-Demand-Driven-Sourcing.md), [SPEC-067-A](../docs/adrs/specs/SPEC-067-A-Demand-Driven-Sourcing.md)) makes it **demand-driven** — source only when no goal carries `status≜open` (no problems left to solve), else no-op — so a supervisor/cron can replenish the backlog exactly when provers run dry. |
| `supervise.sh` | Resilience wrapper (ADR-017) around `agent.sh` / `sourcing.sh`. |
| `prompts/` | The per-cycle playbook prompts the runners inject (`prove.md`, `translate.md`, `decompose.md`, `source.md`). |

An agent session begins by reading `protocol.aisp` + `AI_GUIDE.md`, then runs the loop: pull → select → claim → work → verify → check in.
