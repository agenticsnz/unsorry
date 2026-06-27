import Mathlib

theorem gself_pow_three_pow_22_add_pow_21 (n : ℤ) : (n^3) ∣ (n^22 + n^21) := by
  exact ⟨n^19 + n^18, by ring⟩
