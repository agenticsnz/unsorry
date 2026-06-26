import Mathlib

theorem gself_pow_three_pow_twelve_add_pow_nine (n : ℤ) : (n^3) ∣ (n^12 + n^9) := by
  exact ⟨n^9 + n^6, by ring⟩
