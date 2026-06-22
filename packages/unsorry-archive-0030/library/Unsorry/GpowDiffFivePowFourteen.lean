import Mathlib

theorem gpow_diff_five_pow_fourteen (n : ℤ) : (n - 5) ∣ (n^14 - 6103515625) := by
  exact ⟨n^13 + 5*n^12 + 25*n^11 + 125*n^10 + 625*n^9 + 3125*n^8 + 15625*n^7 + 78125*n^6 + 390625*n^5 + 1953125*n^4 + 9765625*n^3 + 48828125*n^2 + 244140625*n + 1220703125, by ring⟩
