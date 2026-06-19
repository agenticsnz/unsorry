import Mathlib

theorem gpow_diff_seven_pow_three (n : ℤ) : (n - 7) ∣ (n^3 - 343) := by
  exact ⟨n^2 + 7*n + 49, by ring⟩
