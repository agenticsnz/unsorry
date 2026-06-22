import Mathlib

theorem gself_pow_21_add_pow_twenty (n : ℤ) : (n) ∣ (n^21 + n^20) := by
  exact ⟨n^20 + n^19, by ring⟩
