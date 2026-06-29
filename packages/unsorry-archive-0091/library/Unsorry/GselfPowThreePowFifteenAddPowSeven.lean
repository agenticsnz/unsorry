import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_seven (n : ℤ) : (n^3) ∣ (n^15 + n^7) := by
  exact ⟨n^12 + n^4, by ring⟩
