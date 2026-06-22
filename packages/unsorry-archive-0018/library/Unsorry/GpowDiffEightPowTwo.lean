import Mathlib

theorem gpow_diff_eight_pow_two (n : ℤ) : (n - 8) ∣ (n^2 - 64) := by
  exact ⟨n + 8, by ring⟩
