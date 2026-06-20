import Mathlib

theorem gpow_sum_one_pow_nine (n : ℤ) : (n + 1) ∣ (n^9 + 1) := by
  exact ⟨n^8 - n^7 + n^6 - n^5 + n^4 - n^3 + n^2 - n + 1, by ring⟩
