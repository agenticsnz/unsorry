import Mathlib

theorem sum_range_recip_five_step_residue_one (n : ℕ) : ∑ k ∈ Finset.range n, (5 : ℚ) / ((5 * (k : ℚ) + 1) * (5 * (k : ℚ) + 6)) = 1 - 1 / (5 * (n : ℚ) + 1) := by
  sorry
