import Mathlib

theorem gpow_diff_two_pow_eight (n : ℤ) : (n - 2) ∣ (n^8 - 256) := by
  exact ⟨n^7 + 2*n^6 + 4*n^5 + 8*n^4 + 16*n^3 + 32*n^2 + 64*n + 128, by ring⟩
