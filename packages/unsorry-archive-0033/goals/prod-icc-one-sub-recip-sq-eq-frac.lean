import Mathlib

theorem prod_icc_one_sub_recip_sq_eq_frac (n : ℕ) (hn : 2 ≤ n) : ∏ k ∈ Finset.Icc 2 n, (((k : ℚ) ^ 2 - 1) / (k : ℚ) ^ 2) = ((n : ℚ) + 1) / (2 * (n : ℚ)) := by
  sorry
