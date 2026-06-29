import Mathlib

theorem gpow_sum_five_pow_five (n : ℤ) : (n + 5) ∣ (n^5 + 3125) := by
  exact ⟨n^4 - 5*n^3 + 25*n^2 - 125*n + 625, by ring⟩
