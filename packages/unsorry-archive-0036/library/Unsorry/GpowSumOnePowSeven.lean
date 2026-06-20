import Mathlib

theorem gpow_sum_one_pow_seven (n : ℤ) : (n + 1) ∣ (n^7 + 1) := by
  exact ⟨n^6 - n^5 + n^4 - n^3 + n^2 - n + 1, by ring⟩
