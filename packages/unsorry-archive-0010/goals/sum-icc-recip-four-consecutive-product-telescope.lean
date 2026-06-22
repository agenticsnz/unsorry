import Mathlib

theorem sum_icc_recip_four_consecutive_product_telescope (n : ℕ) (hn : 1 ≤ n) :
    ∑ k ∈ Finset.Icc 1 n, (1 : ℚ) / (k * (k + 1) * (k + 2) * (k + 3))
      = 1 / 18 - 1 / (3 * (n + 1) * (n + 2) * (n + 3)) := by
  sorry
