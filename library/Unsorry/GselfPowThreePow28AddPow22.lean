import Mathlib

theorem gself_pow_three_pow_28_add_pow_22 (n : ℤ) : (n^3) ∣ (n^28 + n^22) := by
  exact ⟨n^25 + n^19, by ring⟩
