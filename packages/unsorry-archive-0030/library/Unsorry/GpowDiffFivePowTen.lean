import Mathlib

theorem gpow_diff_five_pow_ten (n : ℤ) : (n - 5) ∣ (n^10 - 9765625) := by
  exact ⟨n^9 + 5*n^8 + 25*n^7 + 125*n^6 + 625*n^5 + 3125*n^4 + 15625*n^3 + 78125*n^2 + 390625*n + 1953125, by ring⟩
