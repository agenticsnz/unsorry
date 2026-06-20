import Mathlib

theorem sum_heptagonal_closed_form (n : ℕ) : 6 * ∑ k ∈ Finset.range (n + 1), (5 * k ^ 2 - 3 * k) = 2 * n * (n + 1) * (5 * n - 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h1 : 3 * (m + 1) ≤ 5 * (m + 1) ^ 2 := by nlinarith
    have h2 : 2 ≤ 5 * (m + 1) := by nlinarith
    cases m with
    | zero => simp
    | succ p =>
      have h3 : 2 ≤ 5 * (p + 1) := by nlinarith
      zify [h1, h2, h3]
      ring