import Mathlib

theorem gself_pow_three_pow_22_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^22 + n^16) := by
  exact ⟨n^19 + n^13, by ring⟩
