import Mathlib

theorem gpow_diff_five_pow_eleven (n : ℤ) : (n - 5) ∣ (n^11 - 48828125) := by
  exact ⟨n^10 + 5*n^9 + 25*n^8 + 125*n^7 + 625*n^6 + 3125*n^5 + 15625*n^4 + 78125*n^3 + 390625*n^2 + 1953125*n + 9765625, by ring⟩
