import Mathlib

theorem gpow_diff_two_pow_eleven (n : ℤ) : (n - 2) ∣ (n^11 - 2048) := by
  exact ⟨n^10 + 2*n^9 + 4*n^8 + 8*n^7 + 16*n^6 + 32*n^5 + 64*n^4 + 128*n^3 + 256*n^2 + 512*n + 1024, by ring⟩
