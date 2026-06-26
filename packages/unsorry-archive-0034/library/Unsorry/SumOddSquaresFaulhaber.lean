import Mathlib

theorem sum_odd_squares_faulhaber (n : ℕ) : 3 * ∑ k ∈ Finset.range n, (2 * k + 1) ^ 2 = n * (2 * n - 1) * (2 * n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
    rw [h1]
    cases m with
    | zero => simp
    | succ k =>
      have h2 : 2 * (k + 1) - 1 = 2 * k + 1 := by omega
      rw [h2]
      ring