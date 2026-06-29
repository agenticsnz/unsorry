# ADR-074: Deterministic Proof Import Narrowing (Best-Effort, Verify-Fallback)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-074 |
| **Initiative** | unsorry — Gate A latency / cost |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-19 |
| **Status** | Accepted |

## Context

Every Gate A job that touches a proof module — the library build
(`lake build UnsorryLibrary --wfail`), the kernel replay (leanchecker), and the
**axiom audit** (`lake exe axiom_audit`) — must load the module's transitive import
closure into memory. The prover almost always emits the broad `import Mathlib` as the
first line of `library/Unsorry/<Camel>.lean`, so that closure is *all of mathlib*
(~10 GB of oleans). The prove prompt already asks for tight imports (`prove.md` rule
2), but the LLM ignores it: `import Mathlib` always builds, and the prompt rightly
prioritises soundness, so there is no incentive to risk a narrower set.

The cost is concentrated in the axiom audit, now the Gate A critical-path step after
the active library was drained to ~12 modules (ADR-041 bulk sweep). Measured on a real
ZMod divisibility proof (#2397): narrowing `import Mathlib` to
`import Mathlib.Data.ZMod.Basic` + `import Mathlib.Tactic` cut the axiom-audit step
from **281 s to 141 s (~2x)**, and the module still built and audited cleanly — the
narrow set is sufficient for a tactic-heavy proof (`decide` / `push_cast` /
`exact_mod_cast`).

Computing a *provably minimal* import set in general is hard: tactic blocks need their
defining modules imported to re-elaborate, but those modules leave no constant in the
finished term, so they cannot be inferred from the proof's constant closure (this is
why mathlib's `shake` is non-trivial). The system is currently **CI-bound, not
prover-bound** (a deep queue of proofs waits on Gate A while provers sit idle), so it
is cheap to spend prover-side work to relieve the scarce CI step.

## WH(Y) Decision Statement

**In the context of** proof modules that ship `import Mathlib` and so force every Gate
A build / replay / audit to load mathlib's entire olean closure (the axiom audit, the
critical-path step, costs ~281 s of that),
**facing** the choice between a general minimal-imports tool (a `shake`-class Lean
executable or a second LLM pass — accurate but heavy, and a wrong answer would reject
a sound proof), strengthening the prove prompt (already tried and ignored, and a
hard "no `import Mathlib`" rule would burn proof attempts and lower the success rate),
and doing nothing (pay ~281 s/proof forever),
**we decided for** a **deterministic, best-effort narrowing pass with a verify
fallback**: after a proof verifies locally, `tools.proof.min_imports` maps observable
source features (e.g. `ZMod` → `Mathlib.Data.ZMod.Basic`; any tactic → the
`Mathlib.Tactic` umbrella) to a candidate import set; `swarm/agent.sh` writes it,
**re-verifies** (`lake build --wfail` + axiom audit), and on **any** failure restores
the original file byte-for-byte — gated by `UNSORRY_MIN_IMPORTS` (default on),
**and neglected** a general Lean/LLM minimiser (heavy, and unnecessary while a handful
of feature rows cover the live backlog) and a prompt-only fix (unreliable, and risks
proof throughput),
**to achieve** a ~2x faster axiom audit (and cheaper build/replay) on every proof the
narrower covers, shrinking Gate A's critical path with no change to soundness,
**accepting that** narrowing only helps proof families with a `FEATURE_MODULES` row
(unmatched proofs keep `import Mathlib` — a no-op, never a regression), that it costs
the prover one extra (cheaper, narrow) re-verify per matched proof — affordable while
CI is the bottleneck — and that the per-proof closure shrink is ~2x, not larger,
because the tactic umbrella still pulls a broad dependency set (a future ADR may add a
`shake`-class pass for a tighter set if non-tactic proof families come to dominate).

## Consequences

- **Soundness is unchanged.** Narrowing is applied only when the narrowed module
  *re-passes* `lake build --wfail` + `lake exe axiom_audit`; otherwise the original
  is restored. CI re-runs the same gates, so a narrow set that builds locally builds
  in CI (confirmed by #2397). Goal modules (`goals/*.lean`, immutable per ADR-018)
  are never touched — only prover-authored `library/Unsorry/*.lean` proof modules.
- **Coverage is incremental.** `FEATURE_MODULES` starts with the `ZMod` family that
  dominates the current backlog; new rows are added as new families appear. The
  fallback guarantees an unmatched or mis-mapped proof is never rejected.
- **Reversible.** `UNSORRY_MIN_IMPORTS=0` disables the pass entirely.

See `docs/adrs/specs/SPEC-074-A-Proof-Import-Narrowing.md`.
