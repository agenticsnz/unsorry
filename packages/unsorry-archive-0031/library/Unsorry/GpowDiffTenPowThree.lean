import Mathlib

theorem gpow_diff_ten_pow_three (n : ℤ) : (n - 10) ∣ (n^3 - 1000) := by
  exact ⟨n^2 + 10*n + 100, by ring⟩
