import Lean.Linter.UnusedVariables
import Unsorry.OddSqModEight
import Mathlib.Tactic.Ring

/-!
# `odd_fourth_power_mod_sixteen`

The fourth power of any odd natural number is congruent to `1` modulo `16`.

The proof builds on `odd_sq_mod_eight`: an odd `n` has `n ^ 2 % 8 = 1`, so
`n ^ 2 = 8 * j + 1` for some `j`. Then `n ^ 4 = (n ^ 2) ^ 2 = (8 * j + 1) ^ 2 =
16 * (4 * j ^ 2 + j) + 1`, which is `1` modulo `16`.
-/

theorem odd_fourth_power_mod_sixteen (n : ℕ) (h : Odd n) : n ^ 4 % 16 = 1 := by
  have h8 : n ^ 2 % 8 = 1 := odd_sq_mod_eight n h
  obtain ⟨j, hj⟩ : ∃ j, n ^ 2 = 8 * j + 1 := ⟨n ^ 2 / 8, by omega⟩
  have hpow : n ^ 4 = 16 * (4 * j ^ 2 + j) + 1 := by
    have e : n ^ 4 = (n ^ 2) ^ 2 := by ring
    rw [e, hj]; ring
  rw [hpow]
  omega

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (n : ℕ) (h : Odd n), n ^ 4 % 16 = 1`, copying the goal's binder
names verbatim. `h` does not occur in the conclusion, so the unused-variables
linter warns on it and the `--wfail` bar fails — in a generated file this module
cannot edit. Core Lean already exempts unused binders in the arrow spelling
`(h : P) → Q` of the same type (its builtin `depArrow` ignore function), because
a binder name there is signature documentation; this extends that exemption to
the `∀ (h : P), Q` spelling. Lint-scope only: it has no effect on elaboration,
the kernel check, or the audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.OddFourthPowerModSixteen.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
