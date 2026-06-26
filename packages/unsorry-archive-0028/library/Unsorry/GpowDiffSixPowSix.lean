import Mathlib

theorem gpow_diff_six_pow_six (n : ℤ) : (n - 6) ∣ (n^6 - 46656) := by
  exact ⟨n^5 + 6*n^4 + 36*n^3 + 216*n^2 + 1296*n + 7776, by ring⟩
