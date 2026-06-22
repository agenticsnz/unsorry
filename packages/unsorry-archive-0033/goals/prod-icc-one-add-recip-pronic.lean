import Mathlib

theorem prod_icc_one_add_recip_pronic (n : ℕ) (hn : 1 ≤ n) : ∏ k ∈ Finset.Icc 1 n, ((1 : ℚ) + 1 / ((k : ℚ) ^ 2 + 2 * (k : ℚ))) = (2 * ((n : ℚ) + 1)) / ((n : ℚ) + 2) := by
  sorry
