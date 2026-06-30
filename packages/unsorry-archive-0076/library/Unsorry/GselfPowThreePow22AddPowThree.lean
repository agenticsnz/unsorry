import Mathlib

theorem gself_pow_three_pow_22_add_pow_three (n : ℤ) : (n^3) ∣ (n^22 + n^3) := by
  exact ⟨n^19 + 1, by ring⟩
