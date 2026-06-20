# SPEC-080-A: `skeleton-validate` — Curated-Package Intake Validator

Implements: [ADR-080](../ADR-080-Problem-Admission-And-Intake-Pipeline.md) · Status: Draft · Updated: 2026-06-20

> **DRAFT** — design spec accompanying draft ADR-080. Build only once ADR-079
> (admissibility policy) and ADR-080 (intake contract) are ratified.

## What this adds

A deterministic, stdlib-only validator, `python3 -m tools.intake.skeleton_validate
<package-dir>`, that decides whether a submitted **curated skeleton package** is
well-formed enough to admit into the queue. It is the machine form of ADR-080's
intake gate: a package either passes wholly (every leaf obligation becomes a queued
goal) or is rejected wholly (never partially queued). It does **not** judge
mathematical correctness — that stays the kernel's job at Gate A; this only checks
the package is *structurally* a real, consumable, curated skeleton.

## Inputs — a "skeleton package"

A directory (PR-staged) carrying, relative to the package root:
- `skeleton.aisp` — manifest: `top≜<goal-id>` (the package's root statement),
  `supplier≜<vetted-id>`, `domain≜math|software|construction`, and the pinned
  verifier context `toolchain≜…; mathlib≜…` (plus, for `software`, a
  `spec≜<path>; framework≜<path>` attachment — ADR-080 open question #1).
- `goals/<id>.aisp` + `goals/<id>.lean` for every obligation (the root and each
  sub), each a standard open-goal record (`status≜open`, `⟦Λ:Artifact⟧{lean≜…;
  sha≜∅}`) whose `.lean` ends in `sorry`.
- `decompositions/<parent>.<supplier>.aisp` for every internal node (the edges).

## Checks (each a pure predicate over parsed records; all must pass)

1. **Manifest well-formed.** `skeleton.aisp` parses; `top`, `supplier`, `domain`,
   and verifier-context fields present and non-empty; `top` resolves to a goal in
   `goals/`.
2. **Curated-target provenance.** `supplier` is a vetted id (checked against the
   ADR-054 trust registry / ADR-079 curated-target list). Self-minted packages are
   rejected — this is what keeps ADR-078 scoring farm-proof.
3. **Every obligation is a well-formed open goal.** For each `goals/<id>.aisp`:
   record parses, `status≜open`, `phase≜prove`, `⟦Λ:Artifact⟧.lean` points at an
   existing `goals/<id>.lean`, `sha≜∅`. The `.lean` syntactically ends in a `sorry`
   obligation (textual check here; type-checking is check 6).
4. **Edges sound and acyclic.** Every `decompositions/*.aisp` `parent` resolves to a
   package goal; every `sub` id resolves to a package goal; the parent→sub graph is
   a **DAG** (no cycles), connected, and rooted at `top`. No orphan goals (every
   non-`top` goal is some node's `sub`).
5. **No over-decomposition padding (ADR-078).** Flag degenerate nodes — a parent
   with a single sub that is statement-identical (a pass-through), or chains added
   only to inflate depth. Configurable threshold; reported as a hard fail in
   `--strict`, a warning otherwise.
6. **Verifier context resolves + top statement type-checks.** The pinned
   `toolchain`/`mathlib` are valid; a package shell builds; the **`top` statement
   type-checks** under that context (its proof is the `sorry`; the *statement* must
   be sound). This is the only step that invokes Lean — gated behind `--build` so
   the cheap structural checks (1–5) can run anywhere, fast.

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
  (ADR-080 open question #2: tool vs. blocking gate — spec provides both; the PR job
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
- Authoring skeletons or autoformalising the top statement (ADR-080 funnel steps
  1–2 — human/supplier work; possible future autoformalisation assist).
- The scoring itself (ADR-078); this only guarantees the graph it scores is sound.
