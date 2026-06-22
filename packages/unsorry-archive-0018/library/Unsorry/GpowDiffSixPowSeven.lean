import Mathlib

theorem gpow_diff_six_pow_seven (n : ℤ) : (n - 6) ∣ (n^7 - 279936) := by
  exact ⟨n^6 + 6*n^5 + 36*n^4 + 216*n^3 + 1296*n^2 + 7776*n + 46656, by ring⟩
