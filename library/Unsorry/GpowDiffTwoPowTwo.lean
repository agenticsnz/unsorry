import Mathlib

theorem gpow_diff_two_pow_two (n : ℤ) : (n - 2) ∣ (n^2 - 4) := by
  exact ⟨n + 2, by ring⟩
