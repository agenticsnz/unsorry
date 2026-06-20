import Mathlib

theorem sum_pronic_eq_thrice_tetrahedral (n : ℕ) : 3 * ∑ k ∈ Finset.range n, k * (k + 1) = (n - 1) * n * (n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => simp
    | succ p =>
      simp only [Nat.add_sub_cancel]
      ring