import Mathlib

theorem gself_pow_three_pow_27_add_pow_22 (n : ℤ) : (n^3) ∣ (n^27 + n^22) := by
  exact ⟨n^24 + n^19, by ring⟩
