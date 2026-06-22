import Mathlib

theorem gpow_sum_eight_pow_three (n : ℤ) : (n + 8) ∣ (n^3 + 512) := by
  exact ⟨n^2 - 8*n + 64, by ring⟩
