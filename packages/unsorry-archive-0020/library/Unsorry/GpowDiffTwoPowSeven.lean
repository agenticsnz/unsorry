import Mathlib

theorem gpow_diff_two_pow_seven (n : ℤ) : (n - 2) ∣ (n^7 - 128) := by
  exact ⟨n^6 + 2*n^5 + 4*n^4 + 8*n^3 + 16*n^2 + 32*n + 64, by ring⟩
