import Mathlib

theorem sum_heptagonal_numbers_closed_form (n : ℕ) : 3 * ∑ k ∈ Finset.range (n + 1), k * (5 * k - 3) = n * (n + 1) * (5 * n - 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => decide
    | succ p =>
      have e1 : 5 * (p + 1) - 2 = 5 * p + 3 := by omega
      have e2 : 5 * (p + 1 + 1) - 2 = 5 * p + 8 := by omega
      have e3 : 5 * (p + 1 + 1) - 3 = 5 * p + 7 := by omega
      rw [e1, e2, e3]
      ring