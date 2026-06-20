import Mathlib

theorem gpow_diff_five_pow_nine (n : ℤ) : (n - 5) ∣ (n^9 - 1953125) := by
  exact ⟨n^8 + 5*n^7 + 25*n^6 + 125*n^5 + 625*n^4 + 3125*n^3 + 15625*n^2 + 78125*n + 390625, by ring⟩
