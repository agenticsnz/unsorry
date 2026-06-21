import Mathlib

theorem gself_pow_22_add_pow_twenty (n : ℤ) : (n) ∣ (n^22 + n^20) := by
  exact ⟨n^21 + n^19, by ring⟩
