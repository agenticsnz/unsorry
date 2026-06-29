import Mathlib

theorem gpow_diff_two_pow_seventeen (n : ℤ) : (n - 2) ∣ (n^17 - 131072) := by
  exact ⟨n^16 + 2*n^15 + 4*n^14 + 8*n^13 + 16*n^12 + 32*n^11 + 64*n^10 + 128*n^9 + 256*n^8 + 512*n^7 + 1024*n^6 + 2048*n^5 + 4096*n^4 + 8192*n^3 + 16384*n^2 + 32768*n + 65536, by ring⟩
