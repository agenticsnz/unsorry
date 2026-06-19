import Mathlib

theorem gpow_diff_two_pow_four (n : ℤ) : (n - 2) ∣ (n^4 - 16) := by
  exact ⟨n^3 + 2*n^2 + 4*n + 8, by ring⟩
