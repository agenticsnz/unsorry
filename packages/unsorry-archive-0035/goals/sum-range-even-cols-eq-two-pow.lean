import Mathlib

theorem sum_range_even_cols_eq_two_pow (n : ℕ) (hn : 1 ≤ n) : ∑ k ∈ Finset.range (n + 1), (2 * n).choose (2 * k) = 2 ^ (2 * n - 1) := by
  sorry
