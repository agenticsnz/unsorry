import Mathlib

theorem sum_hexagonal_numbers_closed_form (n : ℕ) : 6 * ∑ k ∈ Finset.range (n + 1), k * (2 * k - 1) = n * (n + 1) * (4 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    cases m with
    | zero => decide
    | succ p =>
      have h1 : 2 * (p + 1 + 1) - 1 = 2 * p + 3 := by omega
      have h2 : 4 * (p + 1) - 1 = 4 * p + 3 := by omega
      have h3 : 4 * (p + 1 + 1) - 1 = 4 * p + 7 := by omega
      rw [h1, h2, h3] at *
      ring