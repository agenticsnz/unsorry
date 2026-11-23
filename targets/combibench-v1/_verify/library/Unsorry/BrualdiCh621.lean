import Mathlib.Combinatorics.Derangements.Finite

/-!
# Brualdi, Chapter 6, Exercise 21

The number of derangements `D n` is even if and only if `n` is odd.

Proof idea: we prove by induction the joint statement
`(Even (D n) ↔ Odd n) ∧ (Even (D (n + 1)) ↔ Odd (n + 1))`, using the
recurrence `D (n + 2) = (n + 1) * (D n + D (n + 1))` together with the base
values `D 0 = 1` and `D 1 = 0`. If `n` is odd, the factor `n + 1` is even, so
`D (n + 2)` is even. If `n` is even, then `n + 1` is odd, `D n` is odd and
`D (n + 1)` is even, so the product is odd.
-/

theorem brualdi_ch6_21 (n : ℕ) : Even (numDerangements n) ↔ Odd n := by
  have key : ∀ m : ℕ, (Even (numDerangements m) ↔ Odd m) ∧
      (Even (numDerangements (m + 1)) ↔ Odd (m + 1)) := by
    intro m
    induction m with
    | zero => simp
    | succ k ih =>
      obtain ⟨h0, h1⟩ := ih
      refine ⟨h1, ?_⟩
      rw [numDerangements_add_two, Nat.even_mul,
        Nat.even_add (m := numDerangements k), h0, h1]
      rcases Nat.even_or_odd k with hk | hk
      · have h1' : ¬ Even (k + 1) := by
          rw [Nat.even_add_one]; exact not_not.mpr hk
        have h2' : ¬ Odd (k + 1 + 1) := by
          rw [Nat.not_odd_iff_even]; exact hk.add_one.add_one
        have h3' : ¬ Odd k := by
          rw [Nat.not_odd_iff_even]; exact hk
        have h4' : Odd (k + 1) := hk.add_one
        simp [h1', h2', h3', h4']
      · have h1' : Even (k + 1) := hk.add_one
        have h2' : Odd (k + 1 + 1) := hk.add_one.add_one
        simp [h1', h2']
  exact (key n).1
