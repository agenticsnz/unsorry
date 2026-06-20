import Mathlib

theorem gpow_diff_six_pow_eleven (n : ℤ) : (n - 6) ∣ (n^11 - 362797056) := by
  exact ⟨n^10 + 6*n^9 + 36*n^8 + 216*n^7 + 1296*n^6 + 7776*n^5 + 46656*n^4 + 279936*n^3 + 1679616*n^2 + 10077696*n + 60466176, by ring⟩
