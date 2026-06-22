import Mathlib

theorem gself_pow_three_pow_22_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^22 + n^14) := by
  exact ⟨n^19 + n^11, by ring⟩
