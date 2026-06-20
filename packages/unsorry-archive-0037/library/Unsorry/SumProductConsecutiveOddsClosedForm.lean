import Mathlib

theorem sum_product_consecutive_odds_closed_form (n : ℕ) : 3 * ∑ k ∈ Finset.range (n + 1), (2 * k - 1) * (2 * k + 1) = n * (4 * n ^ 2 + 6 * n - 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h1 : 2 * (m + 1) - 1 = 2 * m + 1 := by omega
    rw [h1]
    cases m with
    | zero => decide
    | succ p =>
      have e1 : (p + 1) * (4 * (p + 1) ^ 2 + 6 * (p + 1) - 1)
          + 3 * ((2 * (p + 1) + 1) * (2 * (p + 1 + 1) + 1))
          = (p + 1 + 1) * (4 * (p + 1 + 1) ^ 2 + 6 * (p + 1 + 1) - 1) := by
        zify [show 1 ≤ 4 * (p + 1) ^ 2 + 6 * (p + 1) by nlinarith,
              show 1 ≤ 4 * (p + 1 + 1) ^ 2 + 6 * (p + 1 + 1) by nlinarith]
        ring
      exact e1