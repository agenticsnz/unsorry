import Mathlib

theorem gself_pow_two_pow_22_add_pow_21 (n : ℤ) : (n^2) ∣ (n^22 + n^21) := by
  exact ⟨n^20 + n^19, by ring⟩
