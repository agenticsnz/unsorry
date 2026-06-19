import Mathlib

theorem gpow_diff_two_pow_ten (n : ℤ) : (n - 2) ∣ (n^10 - 1024) := by
  exact ⟨n^9 + 2*n^8 + 4*n^7 + 8*n^6 + 16*n^5 + 32*n^4 + 64*n^3 + 128*n^2 + 256*n + 512, by ring⟩
