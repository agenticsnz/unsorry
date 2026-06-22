import Mathlib

theorem gpow_diff_two_pow_five (n : ℤ) : (n - 2) ∣ (n^5 - 32) := by
  exact ⟨n^4 + 2*n^3 + 4*n^2 + 8*n + 16, by ring⟩
