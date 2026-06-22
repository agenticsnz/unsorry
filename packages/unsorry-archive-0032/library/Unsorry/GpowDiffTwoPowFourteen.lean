import Mathlib

theorem gpow_diff_two_pow_fourteen (n : ℤ) : (n - 2) ∣ (n^14 - 16384) := by
  exact ⟨n^13 + 2*n^12 + 4*n^11 + 8*n^10 + 16*n^9 + 32*n^8 + 64*n^7 + 128*n^6 + 256*n^5 + 512*n^4 + 1024*n^3 + 2048*n^2 + 4096*n + 8192, by ring⟩
