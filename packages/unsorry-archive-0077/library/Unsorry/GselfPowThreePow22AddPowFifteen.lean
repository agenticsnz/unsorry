import Mathlib

theorem gself_pow_three_pow_22_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^22 + n^15) := by
  exact ⟨n^19 + n^12, by ring⟩
