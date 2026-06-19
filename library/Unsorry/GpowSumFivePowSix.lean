import Mathlib

theorem gpow_sum_five_pow_six (n : ℤ) : (n + 5) ∣ (n^6 - 15625) := by
  exact ⟨n^5 - 5*n^4 + 25*n^3 - 125*n^2 + 625*n - 3125, by ring⟩
