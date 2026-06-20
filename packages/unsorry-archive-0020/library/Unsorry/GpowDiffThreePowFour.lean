import Mathlib

theorem gpow_diff_three_pow_four (n : ℤ) : (n - 3) ∣ (n^4 - 81) := by
  exact ⟨n^3 + 3*n^2 + 9*n + 27, by ring⟩
