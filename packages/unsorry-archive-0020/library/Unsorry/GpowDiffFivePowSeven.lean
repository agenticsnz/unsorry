import Mathlib

theorem gpow_diff_five_pow_seven (n : ℤ) : (n - 5) ∣ (n^7 - 78125) := by
  exact ⟨n^6 + 5*n^5 + 25*n^4 + 125*n^3 + 625*n^2 + 3125*n + 15625, by ring⟩
