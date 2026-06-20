import Mathlib

theorem gpow_diff_two_pow_eighteen (n : ℤ) : (n - 2) ∣ (n^18 - 262144) := by
  exact ⟨n^17 + 2*n^16 + 4*n^15 + 8*n^14 + 16*n^13 + 32*n^12 + 64*n^11 + 128*n^10 + 256*n^9 + 512*n^8 + 1024*n^7 + 2048*n^6 + 4096*n^5 + 8192*n^4 + 16384*n^3 + 32768*n^2 + 65536*n + 131072, by ring⟩
