import Mathlib

theorem gpow_diff_eight_pow_twelve (n : ℤ) : (n - 8) ∣ (n^12 - 68719476736) := by
  exact ⟨n^11 + 8*n^10 + 64*n^9 + 512*n^8 + 4096*n^7 + 32768*n^6 + 262144*n^5 + 2097152*n^4 + 16777216*n^3 + 134217728*n^2 + 1073741824*n + 8589934592, by ring⟩
