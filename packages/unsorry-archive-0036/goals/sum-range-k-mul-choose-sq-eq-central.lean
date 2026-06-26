import Mathlib

theorem sum_range_k_mul_choose_sq_eq_central (n : ℕ) (hn : 1 ≤ n) : ∑ k ∈ Finset.range (n + 1), k * n.choose k ^ 2 = n * (2 * n - 1).choose (n - 1) := by
  sorry
