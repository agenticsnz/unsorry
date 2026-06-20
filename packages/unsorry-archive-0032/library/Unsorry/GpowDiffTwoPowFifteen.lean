import Mathlib

theorem gpow_diff_two_pow_fifteen (n : ℤ) : (n - 2) ∣ (n^15 - 32768) := by
  exact ⟨n^14 + 2*n^13 + 4*n^12 + 8*n^11 + 16*n^10 + 32*n^9 + 64*n^8 + 128*n^7 + 256*n^6 + 512*n^5 + 1024*n^4 + 2048*n^3 + 4096*n^2 + 8192*n + 16384, by ring⟩
