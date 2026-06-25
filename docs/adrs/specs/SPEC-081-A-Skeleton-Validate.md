# SPEC-081-A: `skeleton-validate` — Curated-Package Intake Validator

Implements: [ADR-081](../ADR-081-Problem-Admission-And-Intake-Pipeline.md) · Status: Accepted · Updated: 2026-06-24

> **Accepted** — ADR-080 (admissibility policy) and ADR-081 (intake contract) are ratified
> (#5643); build proceeds (M2–M3).
>
> **Dovetail with ADR-078 (Leo / #3232).** ADR-078 closes by asking for exactly
> this artifact — *"the target-registry format, the registration-time full-battery
> probe, and the credit function."* `skeleton-validate` **is** that registration-time
> validator: it admits a sponsor-registered target and runs the structural checks
> below. ADR-078's **full-battery "credited-vs-glue" probe** plugs in here as
> **check 7** (a node earns credit only if `nlinarith`/`positivity`/`field_simp`/
> `gcongr` ∪ the ADR-035 battery cannot close it); its definition and the **credit
> function** remain ADR-078's to own — this spec only invokes them. The two-level
> gate: **ADR-080 admits the domain** (kernel-grade verifier), **ADR-078 registers
> the target** (sponsor skeleton), and `skeleton-validate` enforces both at intake.

## What this adds

A deterministic, stdlib-only validator, `python3 -m tools.intake.skeleton_validate
<package-dir>`, that decides whether a submitted **curated skeleton package** is
well-formed enough to admit into the queue. It is the machine form of ADR-081's
intake gate: a package either passes wholly (every leaf obligation becomes a queued
goal) or is rejected wholly (never partially queued). It does **not** judge
mathematical correctness — that stays the kernel's job at Gate A; this only checks
the package is *structurally* a real, consumable, curated skeleton.

## Inputs — a "skeleton package"

A directory (PR-staged) carrying, relative to the package root:
- `skeleton.aisp` — manifest: `top≜<goal-id>` (the package's root statement),
  `supplier≜<vetted-id>`, `domain≜math|software|construction`, and the pinned
  verifier context `toolchain≜…; mathlib≜…` (plus, for `software`, a
  `spec≜<path>; framework≜<path>` attachment — ADR-081 open question #1).
- `goals/<id>.aisp` + `goals/<id>.lean` for every obligation (the root and each
  sub), each a standard open-goal record (`status≜open`, `⟦Λ:Artifact⟧{lean≜…;
  sha≜∅}`) whose `.lean` ends in `sorry`.
- `decompositions/<parent>.<supplier>.aisp` for every internal node (the edges).

## Checks (each a pure predicate over parsed records; all must pass)

1. **Manifest well-formed.** `skeleton.aisp` parses; `top`, `supplier`, `domain`,
   and verifier-context fields present and non-empty; `top` resolves to a goal in
   `goals/`.
2. **Curated-target provenance.** `supplier` is a vetted id (checked against the
   ADR-054 trust registry / ADR-080 curated-target list). Self-minted packages are
   rejected — this is what keeps ADR-078's credit accounting farm-proof.
3. **Every obligation is a well-formed open goal.** For each `goals/<id>.aisp`:
   record parses, `status≜open`, `phase≜prove`, `⟦Λ:Artifact⟧.lean` points at an
   existing `goals/<id>.lean`, `sha≜∅`. The `.lean` syntactically ends in a `sorry`
   obligation (textual check here; type-checking is check 6).
4. **Edges sound and acyclic.** Every `decompositions/*.aisp` `parent` resolves to a
   package goal; every `sub` id resolves to a package goal; the parent→sub graph is
   a **DAG** (no cycles), connected, and rooted at `top`. No orphan goals (every
   non-`top` goal is some node's `sub`).
5. **No degenerate padding.** Flag pass-through nodes (a parent with a single
   statement-identical sub) or chains added only to inflate the graph. Under
   ADR-078's credit model padding is largely *moot* (padded nodes are glue → earn
   zero, check 7), so this is advisory by default; a hard fail under `--strict`.
6. **Verifier context resolves + top statement type-checks.** The pinned
   `toolchain`/`mathlib` are valid; a package shell builds; the **`top` statement
   type-checks** under that context (its proof is the `sorry`; the *statement* must
   be sound). Invokes Lean — gated behind `--build` so the cheap structural checks
   (1–5) run anywhere, fast.
7. **Credited-vs-glue classification (ADR-078, `--build`).** Run ADR-078's
   registration-time **full battery** (the ADR-035 set ∪ `nlinarith`/`positivity`/
   `field_simp`/`gcongr`) on each leaf obligation: a node it closes is **glue**
   (permitted, earns zero); a node it cannot close is **credited**. A target with
   **zero** credited obligations is rejected (nothing to credit — sponsor-side
   anti-farm). The battery + credit function are **ADR-078's to define**; this check
   only invokes them and records the credited/glue label per node.

## CLI / contract

```
python3 -m tools.intake.skeleton_validate <package-dir> [--strict] [--build] [--json]
```
- Exit codes (mirroring Gate B): **0** admit · **1** rejected (one or more checks
  failed) · **2** internal/usage error.
- Default run does checks 1–5 (pure, no Lean). `--build` adds check 6. `--json`
  emits a structured report (per-check pass/fail + offending ids) for CI.
- On admit, prints the list of leaf obligation ids that would be queued; emits no
  side effects (queueing is a separate step — this only decides).

## Where it lives / reuse

- New package `tools/intake/` (`skeleton_validate.py`, `__main__.py`, `tests/`).
- **Reuse, do not re-implement:** `tools.gate_b.records.parse_record` (AISP parsing);
  `tools.archive.apply.decomposition_components` / the edge-walking already used for
  the ADR-078 graph; the goal-record field accessors. The DAG/edge logic overlaps
  the binding-defer check added for archiving — factor shared graph helpers if it
  reduces duplication.

## Integration

- **Intake tool first**, run by the onboarding operator on a candidate package
  (fast, checks 1–5).
- **CI check on the package PR** (`--build`) so an admitted package is gated the same
  way everything else is — a `skeleton-validate` job mirroring the Gate B pattern.
  (ADR-081 open question #2: tool vs. blocking gate — spec provides both; the PR job
  is the enforcement point.)

## Tests (`tools/intake/tests/`)

Pure-predicate unit tests with fixture packages (no network, no Lean for 1–5):
- valid package admits (exit 0, lists leaves);
- missing/blank manifest field → reject;
- self-minted / unvetted `supplier` → reject;
- a goal whose `.lean` lacks `sorry`, or `status≠open` → reject;
- dangling `sub` id, missing `parent`, and an introduced **cycle** → reject;
- orphan goal (not reachable from `top`) → reject;
- pass-through padding → warn (default) / fail (`--strict`);
- `--json` shape is stable (CI contract).
Check 6 (`--build`) is exercised by a CI fixture package, not the hermetic unit run.

## Out of scope
- Mathematical correctness of any proof (Gate A / the kernel).
- Authoring skeletons or autoformalising the top statement (ADR-081 funnel steps
  1–2 — human/supplier work; possible future autoformalisation assist).
- The credit accounting itself (ADR-078); this only guarantees the graph it reads is sound.
