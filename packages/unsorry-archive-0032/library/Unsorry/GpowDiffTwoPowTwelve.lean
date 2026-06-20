import Mathlib

theorem gpow_diff_two_pow_twelve (n : ℤ) : (n - 2) ∣ (n^12 - 4096) := by
  exact ⟨n^11 + 2*n^10 + 4*n^9 + 8*n^8 + 16*n^7 + 32*n^6 + 64*n^5 + 128*n^4 + 256*n^3 + 512*n^2 + 1024*n + 2048, by ring⟩
