import Mathlib

theorem gpow_diff_six_pow_five (n : ℤ) : (n - 6) ∣ (n^5 - 7776) := by
  exact ⟨n^4 + 6*n^3 + 36*n^2 + 216*n + 1296, by ring⟩
