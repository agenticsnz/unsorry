import Mathlib

theorem gpow_diff_seven_pow_two (n : ℤ) : (n - 7) ∣ (n^2 - 49) := by
  exact ⟨n + 7, by ring⟩
