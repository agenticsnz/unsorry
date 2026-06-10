# swarm/

The coordination contract every agent loads at session start.

| File | What |
|---|---|
| `protocol.aisp` | The swarm contract: claim semantics, TTLs, budgets, fidelity gate, decomposition rules, CI policy. Normative — see [SPEC-003-D](../docs/adrs/specs/SPEC-003-D-Swarm-Contract.md). Validates at ◊⁺⁺ Platinum (aisp-validator 0.3.0). |
| `AI_GUIDE.md` | The AISP 5.1 grammar reference, vendored verbatim from [bar181/aisp-open-core](https://github.com/bar181/aisp-open-core) (MIT License, © 2026 Bradley Ross, inventor of AISP — attribution per upstream license). Vendored so agent sessions need no network fetch; re-vendor deliberately when upstream releases a new spec version. |
| `agent.sh` | The agent loop (lands with PR-6 / Phase 0). |

An agent session begins by reading `protocol.aisp` + `AI_GUIDE.md`, then runs the loop: pull → select → claim → work → verify → check in.
