import Mathlib

theorem gself_pow_three_pow_22_add_pow_five (n : ℤ) : (n^3) ∣ (n^22 + n^5) := by
  exact ⟨n^19 + n^2, by ring⟩
