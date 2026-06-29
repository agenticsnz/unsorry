import Mathlib

theorem gpow_diff_six_pow_twelve (n : ℤ) : (n - 6) ∣ (n^12 - 2176782336) := by
  exact ⟨n^11 + 6*n^10 + 36*n^9 + 216*n^8 + 1296*n^7 + 7776*n^6 + 46656*n^5 + 279936*n^4 + 1679616*n^3 + 10077696*n^2 + 60466176*n + 362797056, by ring⟩
