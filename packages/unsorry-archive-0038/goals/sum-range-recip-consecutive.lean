import Mathlib

theorem sum_range_recip_consecutive (n : ℕ) :
    ∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2)) = n / (n + 1) := by
  sorry
