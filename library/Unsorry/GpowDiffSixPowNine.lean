import Mathlib

theorem gpow_diff_six_pow_nine (n : ℤ) : (n - 6) ∣ (n^9 - 10077696) := by
  exact ⟨n^8 + 6*n^7 + 36*n^6 + 216*n^5 + 1296*n^4 + 7776*n^3 + 46656*n^2 + 279936*n + 1679616, by ring⟩
