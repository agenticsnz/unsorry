import Mathlib

theorem gself_pow_27_add_pow_twenty (n : ℤ) : (n) ∣ (n^27 + n^20) := by
  exact ⟨n^26 + n^19, by ring⟩
