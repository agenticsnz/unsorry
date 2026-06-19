# SPEC-074-A: Proof Import Narrowing

Implements [ADR-074](../ADR-074-Proof-Import-Narrowing.md).

## 1. Goal

After a proof verifies locally, replace its broad `import Mathlib` with the smallest
known import set that still builds and passes the axiom audit, falling back to
`import Mathlib` on any failure — shrinking the mathlib closure Gate A must load,
without ever rejecting a sound proof.

## 2. Components

### 2.1 `tools/proof/min_imports.py` (pure candidate generator)

- `candidate_imports(source: str) -> list[str] | None`
  - Returns `None` (no narrowing) unless the file's import lines are **exactly**
    `["import Mathlib"]`. A proof that already chose tight imports, or has no/multiple
    imports, is left untouched.
  - Builds the candidate from `FEATURE_MODULES` (regex token → module). Math modules
    are emitted first, in table order.
  - Appends `import Mathlib.Tactic` (the umbrella) iff any `TACTIC_TOKENS` token is
    present — tactic modules are needed to re-elaborate but are not in the constant
    closure.
  - Returns `None` if no math feature matched (a tactic-only set would miss the
    proof's lemmas and fall back anyway).
- `rewrite_imports(source, modules) -> str` — replaces only the single
  `import Mathlib` line with `modules`; the rest of the file (e.g. `set_option … in`,
  the proof) is preserved verbatim.
- `main(argv)` / `python3 -m tools.proof.min_imports <module.lean>` — prints the
  narrowed module to stdout and returns `0`; returns `1` when there is no narrowing;
  `2` on usage error.

`FEATURE_MODULES` is the extension point: add a `(regex, "import …")` row per proof
family. Initial coverage: `\bZMod\b → import Mathlib.Data.ZMod.Basic` (measured,
#2397).

### 2.2 `swarm/agent.sh` :: `minimize_proof_imports prwt camel`

Invoked once, immediately after `prove_local_verify` succeeds. Steps:

1. No-op unless `UNSORRY_MIN_IMPORTS` is `1` (the default).
2. Run `python3 -m tools.proof.min_imports library/Unsorry/<camel>.lean` into a temp
   file. If it returns non-zero or empty (no narrowing), return — the proof keeps its
   imports.
3. Back up the original module (outside the worktree), write the narrowed module.
4. Re-run `prove_local_verify` (the `--wfail` build + binding build + axiom audit).
   - Success → keep the narrowed module.
   - Failure → restore the original byte-for-byte.
5. Always return `0` — narrowing is best-effort and never fails the proof.

## 3. Invariants

- **I1 (soundness preserved).** The narrowed module is committed only if it re-passes
  the same gates the original passed; otherwise the original is restored unchanged.
- **I2 (goals untouched).** Only `library/Unsorry/<Camel>.lean` is rewritten;
  `goals/*.lean` (ADR-018) are never read or written.
- **I3 (no regression).** An unmatched proof, a mis-mapped set, or any tooling error
  leaves the original `import Mathlib` proof exactly as it was.

## 4. Tests

`tools/proof/tests/test_min_imports.py`: ZMod proof narrows to ZMod.Basic + Tactic;
math-before-tactic ordering; already-narrow / multi-import / no-feature → `None`;
ZMod-without-tactics skips the umbrella; `rewrite_imports` preserves the body and is
idempotent; CLI rc 0/1/2 paths. The `agent.sh` hook is exercised end-to-end by Gate A
in CI (a narrowed proof must build + audit there too).
