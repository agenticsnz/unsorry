import Mathlib

theorem sum_range_three_mul_add_one (n : ℕ) : 2 * (∑ k ∈ Finset.range n, (3 * k + 1)) = n * (3 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => simp
    | succ p =>
      have h1 : 3 * (p + 1) - 1 = 3 * p + 2 := by omega
      have h2 : 3 * (p + 1 + 1) - 1 = 3 * p + 5 := by omega
      rw [h1, h2]
      ring