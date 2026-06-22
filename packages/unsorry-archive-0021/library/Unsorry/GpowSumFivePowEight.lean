import Mathlib

theorem gpow_sum_five_pow_eight (n : ℤ) : (n + 5) ∣ (n^8 - 390625) := by
  exact ⟨n^7 - 5*n^6 + 25*n^5 - 125*n^4 + 625*n^3 - 3125*n^2 + 15625*n - 78125, by ring⟩
