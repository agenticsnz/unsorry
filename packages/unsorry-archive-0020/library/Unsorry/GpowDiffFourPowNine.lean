import Mathlib

theorem gpow_diff_four_pow_nine (n : ℤ) : (n - 4) ∣ (n^9 - 262144) := by
  exact ⟨n^8 + 4*n^7 + 16*n^6 + 64*n^5 + 256*n^4 + 1024*n^3 + 4096*n^2 + 16384*n + 65536, by ring⟩
