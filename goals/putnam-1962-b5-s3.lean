import Mathlib

theorem putnam_1962_b5_sum_ge_top_three (n : ℤ) (hn : n ≥ 3) : (1 : ℝ) + ((n - 1 : ℝ) / n) ^ (n : ℝ) + ((n - 2 : ℝ) / n) ^ (n : ℝ) ≤ ∑ i ∈ Finset.Icc 1 n, ((i : ℝ) / n) ^ (n : ℝ) := by
  sorry
