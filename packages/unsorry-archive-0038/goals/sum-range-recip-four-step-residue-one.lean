import Mathlib

theorem sum_range_recip_four_step_residue_one (n : ℕ) : ∑ k ∈ Finset.range n, (4 : ℚ) / ((4 * (k : ℚ) + 1) * (4 * (k : ℚ) + 5)) = 1 - 1 / (4 * (n : ℚ) + 1) := by
  sorry
