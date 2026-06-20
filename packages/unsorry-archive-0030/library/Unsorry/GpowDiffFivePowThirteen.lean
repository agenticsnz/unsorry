import Mathlib

theorem gpow_diff_five_pow_thirteen (n : ℤ) : (n - 5) ∣ (n^13 - 1220703125) := by
  exact ⟨n^12 + 5*n^11 + 25*n^10 + 125*n^9 + 625*n^8 + 3125*n^7 + 15625*n^6 + 78125*n^5 + 390625*n^4 + 1953125*n^3 + 9765625*n^2 + 48828125*n + 244140625, by ring⟩
