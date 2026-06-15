import Lean.Linter.UnusedVariables
import Unsorry.PlatonicSchlafliCoreS2
import Unsorry.PlatonicSchlafliCoreS3
import Unsorry.PlatonicSchlafliCoreS4

/-!
# `platonic_schlafli_pairs` (goal `platonic-schlafli-core`)

For naturals `p, q ≥ 3` with `(p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹`, the pair
`(p, q)` is one of the five Platonic Schläfli symbols
`{(3,3), (3,4), (4,3), (3,5), (5,3)}`. Chained from the already-verified
sub-lemmas: the inverse-sum bound forces `p < 6`
(`platonic_schlafli_fst_lt_six`) and `q < 6`
(`platonic_schlafli_snd_lt_six`), and with both entries confined to
`{3, 4, 5}` the case analysis `platonic_schlafli_pairs_of_bounds`
identifies the five admissible pairs.
-/

/-- The ADR-011 binding obligation that Gate A regenerates for this goal
states its type as `∀ (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
(h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹), (p, q) ∈ …`, copying the goal's binder
names verbatim. The hypothesis names do not occur in the conclusion, so the
unused-variables linter warns on them and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this pattern extends that exemption to the `∀ (h : P), Q`
spelling, exactly as the merged modules of this family do. (Registered
before the theorem: the linter runs per command.)

Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCore.ignoreSignatureBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]

theorem platonic_schlafli_pairs (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹) :
    (p, q) ∈ ({(3,3),(3,4),(4,3),(3,5),(5,3)} : Finset (ℕ × ℕ)) :=
  platonic_schlafli_pairs_of_bounds p q hp hq
    (platonic_schlafli_fst_lt_six p q hp hq h)
    (platonic_schlafli_snd_lt_six p q hp hq h) h
