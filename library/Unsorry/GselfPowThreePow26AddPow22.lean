import Mathlib

theorem gself_pow_three_pow_26_add_pow_22 (n : ℤ) : (n^3) ∣ (n^26 + n^22) := by
  exact ⟨n^23 + n^19, by ring⟩
