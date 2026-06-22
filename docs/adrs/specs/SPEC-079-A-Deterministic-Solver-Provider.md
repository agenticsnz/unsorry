# SPEC-079-A: Deterministic Solver Provider

Implements: [ADR-079](../ADR-079-Deterministic-Solver-Provider.md) · Status: Draft (proposed with ADR-079) · Updated: 2026-06-20 · Refines [SPEC-013-A](SPEC-013-A-Model-Effort-Policy.md), reuses [SPEC-035-A](SPEC-035-A-Non-Trivial-Theorem-Enforcement.md)

This SPEC is a design sketch accompanying a **Proposed** ADR. It fixes enough of the "how" to argue concretely; the family→template table of §3 is the maintained surface and is expected to grow under review.

## 1. A provider, on the existing seam, off by default

ADR-013 already routes a solve attempt through a resolved `(provider, model, effort)` triple (`agent.sh resolve_model_effort`, `UNSORRY_MODEL` / `UNSORRY_EFFORT`). This SPEC adds one resolvable provider, `python` / `sympy`, selected the same way every other provider is — by configuration, not a code path bolted beside the dispatch:

```
UNSORRY_PROVIDER=python  UNSORRY_MODEL=sympy   # opt in
# unset / any other value → existing behaviour, byte-for-byte
```

Guardrails, so "off by default / additive" is real and not just asserted (HIGH-1 from review):

- **Optional dependency, import-guarded.** sympy is an optional install. If it is absent, the `python` provider reports unavailable at resolution and the run proceeds on the existing providers; it never raises into the solve loop.
- **No change to selection defaults or ordering.** The default resolved provider is unchanged. When `UNSORRY_PROVIDER` is unset the resolver returns exactly what it returns today, and the solve path is byte-identical (acceptance test 6). The deterministic provider is only ever reached when explicitly resolved.
- **No queue/claim change.** The provider sits inside an agent's solve step; it does not alter the claims branch, queue fairness, or the merge path.
- **Board-submission guard (the sequencing invariant made enforceable).** ADR-079 states the provider is safe against the board only once credit attaches to non-trivial sponsor-authored obligations (ADR-078) or ADR-035 is blocking, and only once provenance is corroborated (ADR-023/037). That is enforced, not just asserted: when a run is board-bound (its output is a credited submission) the resolver **refuses** the `python`/`sympy` provider unless **both** (i) a credit-reform attestation is set (ADR-078 registered-target mode, or ADR-035 configured blocking) **and** (ii) corroborated provenance (ADR-023/037) is in force. Requirement (ii) is there because the residual relabeling path (a deterministic artifact submitted as a model's work) is a provenance problem those ADRs own; the guard refuses board use until the owner of that problem is active. In every non-board context — pre-pass, glue discharge, autoformalisation coverage — it resolves normally. Acceptance test 9 pins the refusal.

The provider's contract is any provider's: given an obligation's Lean statement, return a candidate `by …` block or "no solve". On a candidate, the **existing** verification path runs unchanged — Gate A re-elaborates, the kernel re-checks (ADR-006/048). A `python`/`sympy` candidate that does not kernel-check is discarded exactly as a model's would be (acceptance test 7).

## 2. Tier 1 — the battery as a solver

`tools/sourcing/check_triviality.py` already elaborates a goal under `import Mathlib` and runs the ADR-035 battery to *reject* trivial sourced atoms. Tier 1 calls the same battery to *solve*: try each tactic in the ADR-035 set, emit `by <tactic>` for the first that closes the goal. No new proving capability, and by construction every tier-1 output is **trivial by ADR-035** (a single battery tactic closed it).

## 3. Tier 2 — sympy-assisted construction (a governed surface)

Tier 2 covers goals the bare battery cannot close because they need a *computed witness*. Python computes the witness deterministically; the emitted proof is a fixed template instantiated with it. Seed family→template map:

| Family | sympy computes | Emitted Lean |
|--------|----------------|--------------|
| Integer divisibility `a ∣ b` | quotient `k = b / a` | `⟨k, by norm_num⟩` (or `by decide` when small) |
| Factorisation `n = ∏ pᵢ^eᵢ` | `factorint(n)` | `by norm_num [Nat.factorization]` with the witness map |
| `ZMod` / CRT / power-residue | residue / CRT witness | `by decide` (concrete `ZMod n` is `DecidableEq`) |
| Polynomial / `ring` identity | `expand(lhs - rhs) == 0` | `by ring` |
| Linear-combination identity | coefficients `cᵢ` over the hypotheses | `by linear_combination Σ cᵢ * hᵢ` |
| Concrete numeric (in)equality | the evaluated relation | `by norm_num` |

This table is **a CODEOWNERS-gated surface** (HIGH-3 from review). It lives with the solver tooling, so it inherits ADR-019 code-owner review. Adding a family requires, in the same PR: a new row, its construction function, a fixture (§6), and an explicit **credit-posture assertion** for the family — either "outputs probe trivial under ADR-035/078 (glue)", or, if not, a justification that they remain mechanical template work plus a note that they are reachable against the board only through the §1 board-submission guard. The reviewer checks that assertion in-band; a family whose outputs could drift into credit-relevant space without that guard is not merged. No family does general reasoning — each is a decidable or normalising closer fed a witness Python already holds.

## 4. Attribution (honest, by ADR-023)

Every deterministic solve writes its provenance line as:

```
⟦Π:Provenance⟧{solver≜<cfg.solver>; agent≜<id>; provider≜python; model≜sympy; …}
```

`provider≜python; model≜sympy` is the standard record for a deterministic solve and is **never** an LLM provider. This is the corrected attribution from #3217 (the `template-*` solves recorded `provider≜claude`), made the documented default (acceptance test 3).

## 5. Credit posture (what this SPEC does and does not claim)

This SPEC does **not** define what scores. Credit is decided by ADR-035 (the triviality probe), ADR-078 (credited vs glue obligations), and ADR-023/037 (provenance). A deterministic solve earns whatever those grant any proof with the same statement and recorded provenance. The honest accounting:

- **Tier-1 output is trivial by ADR-035 by construction** and so is glue / zero-credit wherever those gates apply.
- **Tier-2 output is mechanical template work but is not uniformly trivial-by-ADR-035.** Some families (`ring` / `decide` / `norm_num` / ZMod-decide) are in that battery; others (`linear_combination`) are not, and need not fall to ADR-078's fuller battery either. For those, whether the proof is credited is governed by the existing probe and provenance machinery, not by this SPEC.
- **The "deterministic ⇒ glue" treatment rides on honest provenance.** A contributor can record a false `provider` and a deterministic solve can be dressed as a model's — including by generating a proof off the board and submitting the artifact through a normal `prove(...)` PR. That path exists today because sympy is public, independent of whether this provider is in the repo, so this SPEC neither creates nor widens it; it is the un-kernel-enforceable residue ADR-013 names, owned by ADR-023/037. The §1 board-submission guard's requirement (ii) is why board enablement waits on that ownership.
- **Farm-bounding depends on ADR-078.** A zero-cost factory for easy goals is a farm vector wherever credit attaches to easy or atomic goals. Under ADR-078 (credit on non-trivial sponsor-authored obligations) or a blocking ADR-035, the factory can only discharge glue and pre-pass work. Absent both, the provider should stay off against the board (ADR-079 Residue).

Sanctioned uses, none needing credit: discharge `glue` obligations of an ADR-078 target at zero LLM cost; run as a **pre-pass** before an LLM is dispatched (ADR-013 records a failed attempt costs a full wall plus a build); generate Phase-1 autoformalisation coverage. The provider must **not** be pointed at the ADR-043 sourcing queue to mint standalone atoms.

## 6. Acceptance criteria

1. `test_tier1_closes_and_attributes` — a battery-closable goal returns `by <tactic>` with provenance `provider≜python; model≜sympy`; the candidate kernel-checks.
2. `test_tier2_constructs_witness` — for one fixture per §3 family, the provider emits a candidate that kernel-checks using a sympy-computed witness.
3. `test_never_llm_attribution` — no deterministic solve writes an LLM `provider`/`model` in its provenance line (asserted over both tiers).
4. `test_tier1_probes_trivial` — every tier-1 output probes `trivial` under the ADR-035 battery (the solver and the gate agree).
5. `test_off_by_default` — with `UNSORRY_PROVIDER` unset, the resolved provider and the full solve path are byte-identical to pre-change behaviour (the non-breaking guarantee).
6. `test_missing_sympy_is_inert` — with sympy absent, resolving the `python` provider reports unavailable and the run continues on existing providers without raising.
7. `test_unverified_candidate_discarded` — a deliberately wrong constructed candidate (bad witness) is rejected by the existing Gate A path, not trusted on the provider's return.
8. `test_new_family_is_codeowned` — a change to the §3 family table / construction surface is reported by the CODEOWNERS check as requiring code-owner review.
9. `test_board_use_blocked_without_credit_reform` — a board-bound run with no credit-reform attestation cannot resolve the `python`/`sympy` provider (the §1 board-submission guard refuses); the same run in a non-board context (pre-pass / glue / coverage) resolves it normally.

## 7. Out of scope (for this SPEC)

The internal solve-loop wiring of `agent.sh` beyond the `resolve_model_effort` selection point; concurrency/caching of the deterministic pass; the full enumerated family catalogue (only the §3 seed families are specified); any change to credit weights (ADR-078's surface); and provenance spoof-resistance / attestation across distributed agents (ADR-023/037's surface, named in §5 as the residue this SPEC does not close).
