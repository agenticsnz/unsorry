import Mathlib

theorem gpow_diff_five_pow_twelve (n : ℤ) : (n - 5) ∣ (n^12 - 244140625) := by
  exact ⟨n^11 + 5*n^10 + 25*n^9 + 125*n^8 + 625*n^7 + 3125*n^6 + 15625*n^5 + 78125*n^4 + 390625*n^3 + 1953125*n^2 + 9765625*n + 48828125, by ring⟩
