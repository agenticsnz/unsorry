import Mathlib

theorem gpow_diff_six_pow_eight (n : ℤ) : (n - 6) ∣ (n^8 - 1679616) := by
  exact ⟨n^7 + 6*n^6 + 36*n^5 + 216*n^4 + 1296*n^3 + 7776*n^2 + 46656*n + 279936, by ring⟩
