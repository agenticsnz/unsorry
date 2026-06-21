import Mathlib

theorem gpow_diff_two_pow_sixteen (n : ℤ) : (n - 2) ∣ (n^16 - 65536) := by
  exact ⟨n^15 + 2*n^14 + 4*n^13 + 8*n^12 + 16*n^11 + 32*n^10 + 64*n^9 + 128*n^8 + 256*n^7 + 512*n^6 + 1024*n^5 + 2048*n^4 + 4096*n^3 + 8192*n^2 + 16384*n + 32768, by ring⟩
