import Mathlib

theorem sum_decagonal_closed_form (n : ℕ) : 6 * ∑ k ∈ Finset.range (n + 1), k * (4 * k - 3) = n * (n + 1) * (8 * n - 5) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h1 : 4 * (m + 1) - 3 = 4 * m + 1 := by omega
    rw [h1]
    cases m with
    | zero => simp
    | succ p =>
      have hr : 8 * (p + 1 + 1) - 5 = 8 * p + 11 := by omega
      have hl : 8 * (p + 1) - 5 = 8 * p + 3 := by omega
      rw [hr, hl]
      ring