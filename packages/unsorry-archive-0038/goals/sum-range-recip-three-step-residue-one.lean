import Mathlib

theorem sum_range_recip_three_step_residue_one (n : ℕ) : ∑ k ∈ Finset.range n, (3 : ℚ) / ((3 * (k : ℚ) + 1) * (3 * (k : ℚ) + 4)) = 1 - 1 / (3 * (n : ℚ) + 1) := by
  sorry
