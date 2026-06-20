import Mathlib

theorem sum_range_four_mul_add_one (n : ℕ) : ∑ k ∈ Finset.range n, (4 * k + 1) = n * (2 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    cases m with
    | zero => simp
    | succ p =>
      have h : 2 * (p + 1) - 1 = 2 * p + 1 := by omega
      have h2 : 2 * (p + 1 + 1) - 1 = 2 * p + 3 := by omega
      rw [h, h2]; ring