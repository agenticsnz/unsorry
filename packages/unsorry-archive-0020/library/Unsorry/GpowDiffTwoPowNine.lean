import Mathlib

theorem gpow_diff_two_pow_nine (n : ℤ) : (n - 2) ∣ (n^9 - 512) := by
  exact ⟨n^8 + 2*n^7 + 4*n^6 + 8*n^5 + 16*n^4 + 32*n^3 + 64*n^2 + 128*n + 256, by ring⟩
