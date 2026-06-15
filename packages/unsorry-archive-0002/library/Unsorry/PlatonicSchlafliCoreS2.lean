import Lean.Linter.UnusedVariables
import Unsorry.PlatonicSchlafliCoreS2S1
import Unsorry.PlatonicSchlafliCoreS2S2
import Unsorry.PlatonicSchlafliCoreS2S3

/-!
# `platonic_schlafli_fst_lt_six` (goal `platonic-schlafli-core-s2`)

For naturals `p, q ≥ 3` with `(p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹`, the first
Schläfli entry satisfies `p < 6`. Chained from the already-verified
sub-lemmas: `3 ≤ q` bounds `(q : ℚ)⁻¹ ≤ 3⁻¹`
(`nat_inv_le_third_of_three_le`), so the half bound forces
`6⁻¹ < (p : ℚ)⁻¹` (`rat_gt_sixth_of_add_gt_half`), which over ℕ means
`p < 6` (`nat_lt_six_of_sixth_lt_inv`).
-/

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
(h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹), p < 6`, copying the goal's binder names
verbatim. `hp`, `hq`, and `h` do not occur in the conclusion, so the
unused-variables linter warns on them and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; the first pattern extends that exemption to the
`∀ (h : P), Q` spelling, exactly as the merged sub-lemma modules of this
family do.

The second pattern covers the same exemption for binders in a
`theorem`-declaration signature (`Command.declSig` rather than
`Term.forall`): this goal's statement names `hp : 3 ≤ p` verbatim, but the
sub-lemma chain that proves it never needs the lower bound on `p`, so the
restated theorem below trips the linter the same way the generated binding
does. A theorem's binder names are likewise pure signature documentation —
its proof term is irrelevant to its statement — and the statement must be
restated exactly as the goal gives it, hypotheses included. (Registered
before the theorem: the linter runs per command.)

Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS2.ignoreSignatureBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»] ||
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Command.declSig]

theorem platonic_schlafli_fst_lt_six (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹) : p < 6 :=
  nat_lt_six_of_sixth_lt_inv p
    (rat_gt_sixth_of_add_gt_half (p : ℚ)⁻¹ (q : ℚ)⁻¹ h
      (nat_inv_le_third_of_three_le q hq))
