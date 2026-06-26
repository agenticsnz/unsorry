import Mathlib

theorem gpow_sum_one_pow_five (n : ℤ) : (n + 1) ∣ (n^5 + 1) := by
  exact ⟨n^4 - n^3 + n^2 - n + 1, by ring⟩
