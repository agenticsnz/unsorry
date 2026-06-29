import Mathlib

theorem gpow_diff_two_pow_six (n : ℤ) : (n - 2) ∣ (n^6 - 64) := by
  exact ⟨n^5 + 2*n^4 + 4*n^3 + 8*n^2 + 16*n + 32, by ring⟩
