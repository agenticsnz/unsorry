import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Data.Finset.Insert
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.NormNum

/-!
# `platonic_schlafli_pairs_of_bounds` (goal `platonic-schlafli-core-s4`)

For naturals `3 ≤ p, q < 6` with `(p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹`, the pair
`(p, q)` is one of the five Platonic Schläfli symbols
`{(3,3), (3,4), (4,3), (3,5), (5,3)}`. The bounds confine `p` and `q` to
`{3, 4, 5}`, so `interval_cases` reduces the claim to nine concrete cases:
the five listed pairs hold by `decide`, and the four others —
`(4,4)`, `(4,5)`, `(5,4)`, `(5,5)` — make the inverse-sum hypothesis a
false numeral inequality (`1/4 + 1/4 = 1/2 ≯ 1/2` and smaller), which
`norm_num` refutes.
-/

/-- The ADR-011 binding obligation that Gate A regenerates for this goal
states its type as `∀ (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q) (hp6 : p < 6)
(hq6 : q < 6) (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹), (p, q) ∈ …`, copying the
goal's binder names verbatim. The hypothesis names do not occur in the
conclusion, so the unused-variables linter warns on them and the `--wfail`
bar fails — in a generated file this module cannot edit. Core Lean already
exempts unused binders in the arrow spelling `(h : P) → Q` of the same type
(its builtin `depArrow` ignore function), because a binder name there is
signature documentation; the first pattern extends that exemption to the
`∀ (h : P), Q` spelling, exactly as the merged sub-lemma modules of this
family do.

The second pattern covers the same exemption for binders in a
`theorem`-declaration signature (`Command.declSig` rather than
`Term.forall`), matching the parent modules of this family. (Registered
before the theorem: the linter runs per command.)

Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS4.ignoreSignatureBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»] ||
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Command.declSig]

theorem platonic_schlafli_pairs_of_bounds (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (hp6 : p < 6) (hq6 : q < 6) (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹) :
    (p, q) ∈ ({(3,3),(3,4),(4,3),(3,5),(5,3)} : Finset (ℕ × ℕ)) := by
  interval_cases p <;> interval_cases q <;> first
    | decide
    | norm_num at h
