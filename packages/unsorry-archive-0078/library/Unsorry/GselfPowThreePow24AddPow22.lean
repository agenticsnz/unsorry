import Mathlib

theorem gself_pow_three_pow_24_add_pow_22 (n : ℤ) : (n^3) ∣ (n^24 + n^22) := by
  exact ⟨n^21 + n^19, by ring⟩
