import Mathlib

theorem gpow_diff_eight_pow_eleven (n : ℤ) : (n - 8) ∣ (n^11 - 8589934592) := by
  exact ⟨n^10 + 8*n^9 + 64*n^8 + 512*n^7 + 4096*n^6 + 32768*n^5 + 262144*n^4 + 2097152*n^3 + 16777216*n^2 + 134217728*n + 1073741824, by ring⟩
