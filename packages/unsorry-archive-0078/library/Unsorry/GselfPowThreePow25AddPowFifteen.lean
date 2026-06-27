import Mathlib

theorem gself_pow_three_pow_25_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^25 + n^15) := by
  exact ⟨n^22 + n^12, by ring⟩
