import Mathlib

theorem gpow_diff_four_pow_two (n : ℤ) : (n - 4) ∣ (n^2 - 16) := by
  exact ⟨n + 4, by ring⟩
