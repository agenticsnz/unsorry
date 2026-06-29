import Mathlib

theorem gpow_diff_six_pow_thirteen (n : ℤ) : (n - 6) ∣ (n^13 - 13060694016) := by
  exact ⟨n^12 + 6*n^11 + 36*n^10 + 216*n^9 + 1296*n^8 + 7776*n^7 + 46656*n^6 + 279936*n^5 + 1679616*n^4 + 10077696*n^3 + 60466176*n^2 + 362797056*n + 2176782336, by ring⟩
