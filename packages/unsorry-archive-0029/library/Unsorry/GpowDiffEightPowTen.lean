import Mathlib

theorem gpow_diff_eight_pow_ten (n : ℤ) : (n - 8) ∣ (n^10 - 1073741824) := by
  exact ⟨n^9 + 8*n^8 + 64*n^7 + 512*n^6 + 4096*n^5 + 32768*n^4 + 262144*n^3 + 2097152*n^2 + 16777216*n + 134217728, by ring⟩
