# swarm/

The coordination contract every agent loads at session start.

| File | What |
|---|---|
| `protocol.aisp` | The swarm contract: claim semantics, TTLs, budgets, fidelity gate, decomposition rules, CI policy. Normative — see [SPEC-003-D](../docs/adrs/specs/SPEC-003-D-Swarm-Contract.md). Validates at ◊⁺⁺ Platinum (aisp-validator 0.3.0). |
| `AI_GUIDE.md` | The AISP 5.1 grammar reference, vendored verbatim from [bar181/aisp-open-core](https://github.com/bar181/aisp-open-core) (MIT License, © 2026 Bradley Ross, inventor of AISP — attribution per upstream license). Vendored so agent sessions need no network fetch; re-vendor deliberately when upstream releases a new spec version. |
| `agent.sh` | The prove/translate agent loop (lands with PR-6 / Phase 0). |
| `sourcing.sh` | The goal-sourcing runner ([ADR-062](../docs/adrs/ADR-062-Swarm-Goal-Sourcing-Runner.md), [SPEC-062-A](../docs/adrs/specs/SPEC-062-A-Swarm-Goal-Sourcing-Runner.md)): fires up Claude to run one cycle of the `unsorry-goal-sourcing` skill (ADR-060) — pick a hard theme, gate candidates, promote triples, open one `chore(sourcing):` PR. The sourcing counterpart to `agent.sh`; bounded by default. |
| `supervise.sh` | Resilience wrapper (ADR-017) around `agent.sh` / `sourcing.sh`. |
| `prompts/` | The per-cycle playbook prompts the runners inject (`prove.md`, `translate.md`, `decompose.md`, `source.md`). |

An agent session begins by reading `protocol.aisp` + `AI_GUIDE.md`, then runs the loop: pull → select → claim → work → verify → check in.
