import Mathlib

theorem gself_pow_three_pow_25_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^25 + n^12) := by
  exact ⟨n^22 + n^9, by ring⟩
