import Mathlib

theorem gpow_diff_four_pow_three (n : ℤ) : (n - 4) ∣ (n^3 - 64) := by
  exact ⟨n^2 + 4*n + 16, by ring⟩
