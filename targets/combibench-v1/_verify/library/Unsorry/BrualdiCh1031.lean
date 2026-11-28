import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Data.ZMod.Defs

/-!
# Brualdi Chapter 10, Exercise 31

We show that `{0, 3, 4, 9, 11}` is a `(21, 5, 1)` cyclic difference set in `ZMod 21`:
every nonzero residue modulo `21` occurs with multiplicity `k = 1` among the `5 * 4 = 20`
ordered differences `i - j` of distinct elements `i, j` in `{0, 3, 4, 9, 11}`.
Since `ZMod 21` is finite, this universal statement for `k = 1` holds by kernel reduction.
-/

def isDifferenceSet (n : ℕ) (B : Finset (ZMod n)) : Prop :=
  ∃ k, ∀ x : (ZMod n),  x ≠ 0 → ∑ i ∈ B, ∑ j ∈ B \ {i}, List.count x [i - j] = k

theorem brualdi_ch10_31 : isDifferenceSet 21 {0, 3, 4, 9, 11} :=
  ⟨1, by decide⟩
