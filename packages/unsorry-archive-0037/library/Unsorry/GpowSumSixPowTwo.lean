import Mathlib

theorem gpow_sum_six_pow_two (n : ℤ) : (n + 6) ∣ (n^2 - 36) := by
  exact ⟨n - 6, by ring⟩
