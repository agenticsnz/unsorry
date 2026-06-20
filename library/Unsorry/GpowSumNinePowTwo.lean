import Mathlib

theorem gpow_sum_nine_pow_two (n : ℤ) : (n + 9) ∣ (n^2 - 81) := by
  exact ⟨n - 9, by ring⟩
