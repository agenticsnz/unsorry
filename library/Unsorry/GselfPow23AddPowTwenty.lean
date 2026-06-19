import Mathlib

theorem gself_pow_23_add_pow_twenty (n : ℤ) : (n) ∣ (n^23 + n^20) := by
  exact ⟨n^22 + n^19, by ring⟩
