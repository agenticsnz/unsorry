import Mathlib

theorem gpow_diff_eight_pow_nine (n : ℤ) : (n - 8) ∣ (n^9 - 134217728) := by
  exact ⟨n^8 + 8*n^7 + 64*n^6 + 512*n^5 + 4096*n^4 + 32768*n^3 + 262144*n^2 + 2097152*n + 16777216, by ring⟩
