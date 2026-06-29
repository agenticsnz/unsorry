import Mathlib

theorem gself_pow_three_pow_22_add_pow_eight (n : ℤ) : (n^3) ∣ (n^22 + n^8) := by
  exact ⟨n^19 + n^5, by ring⟩
