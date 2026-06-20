import Mathlib

theorem gpow_sum_one_pow_four (n : ℤ) : (n + 1) ∣ (n^4 - 1) := by
  exact ⟨n^3 - n^2 + n - 1, by ring⟩
