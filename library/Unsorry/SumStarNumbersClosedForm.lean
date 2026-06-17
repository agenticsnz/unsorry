import Mathlib

theorem sum_star_numbers_closed_form (n : ℕ) : ∑ k ∈ Finset.range n, (6 * (k + 1) * k + 1) = n * (2 * n ^ 2 - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    cases m with
    | zero => simp
    | succ p =>
      have h : 1 ≤ 2 * (p + 1) ^ 2 := by nlinarith
      have h2 : 1 ≤ 2 * (p + 1 + 1) ^ 2 := by nlinarith
      zify [h, h2]
      ring