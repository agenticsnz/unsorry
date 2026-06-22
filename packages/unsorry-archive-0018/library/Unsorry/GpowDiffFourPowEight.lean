import Mathlib

theorem gpow_diff_four_pow_eight (n : ℤ) : (n - 4) ∣ (n^8 - 65536) := by
  exact ⟨n^7 + 4*n^6 + 16*n^5 + 64*n^4 + 256*n^3 + 1024*n^2 + 4096*n + 16384, by ring⟩
