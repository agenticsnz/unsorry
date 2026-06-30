import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^15 + n^12) := by
  exact ⟨n^12 + n^9, by ring⟩
