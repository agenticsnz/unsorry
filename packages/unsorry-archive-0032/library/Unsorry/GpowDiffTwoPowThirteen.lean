import Mathlib

theorem gpow_diff_two_pow_thirteen (n : ℤ) : (n - 2) ∣ (n^13 - 8192) := by
  exact ⟨n^12 + 2*n^11 + 4*n^10 + 8*n^9 + 16*n^8 + 32*n^7 + 64*n^6 + 128*n^5 + 256*n^4 + 512*n^3 + 1024*n^2 + 2048*n + 4096, by ring⟩
