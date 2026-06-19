import Mathlib

theorem gself_pow_three_pow_twelve_add_pow_ten (n : ℤ) : (n^3) ∣ (n^12 + n^10) := by
  exact ⟨n^9 + n^7, by ring⟩
