import Mathlib

theorem gpow_diff_two_pow_three (n : ℤ) : (n - 2) ∣ (n^3 - 8) := by
  exact ⟨n^2 + 2*n + 4, by ring⟩
