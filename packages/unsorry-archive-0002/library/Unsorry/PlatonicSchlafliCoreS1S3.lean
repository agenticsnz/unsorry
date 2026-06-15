import Lean.Linter.UnusedVariables
import Mathlib.Data.Nat.Notation

/-!
# `nat_six_le_of_not_lt_six` (goal `platonic-schlafli-core-s1-s3`)

For a natural number `n` with `¬ n < 6`, totality of the order on `ℕ` gives
`6 ≤ n`: this is core's `Nat.le_of_not_lt`.
-/

theorem nat_six_le_of_not_lt_six (n : ℕ) (h : ¬ n < 6) : 6 ≤ n :=
  Nat.le_of_not_lt h

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (n : ℕ) (h : ¬ n < 6), 6 ≤ n`, copying the goal's binder names
verbatim. `h` does not occur in the conclusion, so the unused-variables linter
warns on it and the `--wfail` bar fails — in a generated file this module
cannot edit. Core Lean already exempts unused binders in the arrow spelling
`(h : P) → Q` of the same type (its builtin `depArrow` ignore function),
because a binder name there is signature documentation; this extends that
exemption to the `∀ (h : P), Q` spelling. Lint-scope only: it has no effect on
elaboration, the kernel check, or the audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS1S3.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
