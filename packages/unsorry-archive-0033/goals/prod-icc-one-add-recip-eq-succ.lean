import Mathlib

theorem prod_icc_one_add_recip_eq_succ (n : ℕ) (hn : 1 ≤ n) : ∏ k ∈ Finset.Icc 1 n, ((2 * (k : ℚ) + 1) / (2 * (k : ℚ) - 1)) = 2 * (n : ℚ) + 1 := by
  sorry
