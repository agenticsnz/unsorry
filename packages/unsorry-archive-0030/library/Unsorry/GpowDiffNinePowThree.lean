import Mathlib

theorem gpow_diff_nine_pow_three (n : ℤ) : (n - 9) ∣ (n^3 - 729) := by
  exact ⟨n^2 + 9*n + 81, by ring⟩
