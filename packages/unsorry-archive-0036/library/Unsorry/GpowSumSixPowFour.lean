import Mathlib

theorem gpow_sum_six_pow_four (n : ℤ) : (n + 6) ∣ (n^4 - 1296) := by
  exact ⟨n^3 - 6*n^2 + 36*n - 216, by ring⟩
