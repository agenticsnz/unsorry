import Mathlib

theorem gpow_diff_three_pow_three (n : ℤ) : (n - 3) ∣ (n^3 - 27) := by
  exact ⟨n^2 + 3*n + 9, by ring⟩
