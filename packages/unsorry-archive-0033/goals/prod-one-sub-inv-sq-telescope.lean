import Mathlib

theorem prod_one_sub_inv_sq (n : ℕ) (hn : 2 ≤ n) :
    ∏ k ∈ Finset.Icc 2 n, ((1 : ℚ) - 1 / (k : ℚ) ^ 2) = ((n : ℚ) + 1) / (2 * (n : ℚ)) := by
  sorry
