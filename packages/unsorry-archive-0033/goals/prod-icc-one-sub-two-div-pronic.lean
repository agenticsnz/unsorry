import Mathlib

theorem prod_icc_one_sub_two_div_pronic (n : ℕ) (hn : 2 ≤ n) : ∏ k ∈ Finset.Icc 2 n, ((1 : ℚ) - 2 / ((k : ℚ) * ((k : ℚ) + 1))) = ((n : ℚ) + 2) / (3 * (n : ℚ)) := by
  sorry
