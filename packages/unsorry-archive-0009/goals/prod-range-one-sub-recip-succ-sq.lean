import Mathlib

theorem prod_range_one_sub_recip_succ_sq (n : ℕ) (hn : 1 ≤ n) : ∏ k ∈ Finset.Icc 1 n, ((1 : ℚ) - 1 / (((k : ℚ) + 1) ^ 2)) = ((n : ℚ) + 2) / (2 * ((n : ℚ) + 1)) := by
  sorry
