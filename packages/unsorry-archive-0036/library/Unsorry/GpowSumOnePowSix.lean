import Mathlib

theorem gpow_sum_one_pow_six (n : ℤ) : (n + 1) ∣ (n^6 - 1) := by
  exact ⟨n^5 - n^4 + n^3 - n^2 + n - 1, by ring⟩
