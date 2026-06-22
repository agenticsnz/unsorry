import Mathlib

theorem gpow_diff_six_pow_ten (n : ℤ) : (n - 6) ∣ (n^10 - 60466176) := by
  exact ⟨n^9 + 6*n^8 + 36*n^7 + 216*n^6 + 1296*n^5 + 7776*n^4 + 46656*n^3 + 279936*n^2 + 1679616*n + 10077696, by ring⟩
