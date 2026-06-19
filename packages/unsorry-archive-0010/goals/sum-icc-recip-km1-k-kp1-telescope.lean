import Mathlib

theorem sum_icc_recip_km1_k_kp1_telescope (n : ℕ) (hn : 2 ≤ n) : (∑ k ∈ Finset.Icc 2 n, (1 : ℚ) / (((k : ℚ) - 1) * k * (k + 1))) = 1 / 4 - 1 / (2 * (n : ℚ) * (n + 1)) := by
  sorry
