import Mathlib

theorem gpow_diff_six_pow_three (n : ℤ) : (n - 6) ∣ (n^3 - 216) := by
  exact ⟨n^2 + 6*n + 36, by ring⟩
