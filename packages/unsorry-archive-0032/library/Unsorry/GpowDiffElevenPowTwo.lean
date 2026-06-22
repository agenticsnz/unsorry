import Mathlib

theorem gpow_diff_eleven_pow_two (n : ℤ) : (n - 11) ∣ (n^2 - 121) := by
  exact ⟨n + 11, by ring⟩
