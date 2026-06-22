import Mathlib

theorem gpow_diff_twelve_pow_three (n : ℤ) : (n - 12) ∣ (n^3 - 1728) := by
  exact ⟨n^2 + 12*n + 144, by ring⟩
