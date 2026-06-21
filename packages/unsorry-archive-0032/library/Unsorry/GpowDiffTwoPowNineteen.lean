import Mathlib

theorem gpow_diff_two_pow_nineteen (n : ℤ) : (n - 2) ∣ (n^19 - 524288) := by
  exact ⟨n^18 + 2*n^17 + 4*n^16 + 8*n^15 + 16*n^14 + 32*n^13 + 64*n^12 + 128*n^11 + 256*n^10 + 512*n^9 + 1024*n^8 + 2048*n^7 + 4096*n^6 + 8192*n^5 + 16384*n^4 + 32768*n^3 + 65536*n^2 + 131072*n + 262144, by ring⟩
