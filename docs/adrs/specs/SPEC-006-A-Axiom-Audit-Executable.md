# SPEC-006-A: Axiom Audit Executable (`lake exe axiom_audit`)

Implements: [ADR-006](../ADR-006-Gate-A-Soundness-Enforcement.md) · Status: Living · Updated: 2026-06-10

The authoritative Gate A check. Lands with PR-8 as `AxiomAudit/Main.lean` + a `lean_exe` target (`supportInterpreter = true`).

## Interface

```
lake exe axiom_audit [--allow-sorry] <Module> [Module ...]
```

- Module names are dot-separated; hyphenated components (goal modules like `goals.nat-zero-lt-succ`) are parsed with raw `Name.mkStr` per component — **never** `String.toName`, which mangles hyphens (verified failure mode: "anonymous name" import error).
- `--allow-sorry`: extends the whitelist with `sorryAx` — used for `UnsorryGoals` only, never the library.
- Exit codes: `0` clean · `1` ≥1 violation · `2` usage error.

## Behaviour

1. `importModules` the requested modules (`trustLevel := 0`).
2. Iterate `env.constants`; audit exactly the declarations whose defining module (`env.getModuleIdxFor?` → `env.header.moduleNames`) is one of the requested modules; skip `Name.isInternal` declarations.
3. Per declaration, `Lean.collectAxioms` (transitive; the v4.23+ fix means axioms reachable through axioms — e.g. `native_decide` artifacts — are included).
4. Violation: any axiom ∉ {`propext`, `Classical.choice`, `Quot.sound`} (∪ {`sorryAx`} under `--allow-sorry`). One `VIOLATION <decl>: depends on axiom <ax>` line per offence on stderr.
5. Footprint report: JSON array `[{"decl": "...", "axioms": ["..."]}, …]` for **all** audited declarations (violations or not) on stdout — consumed by the CI artifact + PR comment step (SPEC-006-B).

## Verified detection matrix (sandbox, Lean v4.30.0 / mathlib v4.30.0)

| Escape hatch | Surfaces as | Caught |
|---|---|---|
| `by sorry`, `admit`, macro-hidden sorry | `sorryAx` | ✅ (whitelist miss) |
| `axiom evil : False` + uses | `evil` on the axiom and every dependent | ✅ |
| `native_decide` | generated `<decl>._native.native_decide.ax_*` axiom | ✅ |
| clean mathlib proof | `[]` or subset of whitelist | ✅ passes |

## Acceptance criteria (PR-8, TDD)

1. `AuditFixtures` lake lib (NOT in `defaultTargets`, never imported by `UnsorryLibrary`) carries one module per escape hatch: bare sorry, term-level `sorryAx`, new axiom + dependent, `native_decide`, and a clean control.
2. `tools/gate_a/test_audit.sh` builds the fixtures and asserts: each bad fixture module → exit 1 with the expected axiom named on stderr; control → exit 0 with `[]`-or-whitelist footprint; `--allow-sorry` flips only the sorry fixtures.
3. The script is shellcheck-clean and runs in gate-a.yml after the library build.
