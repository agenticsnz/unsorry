import Mathlib

theorem gself_pow_26_add_pow_twenty (n : ℤ) : (n) ∣ (n^26 + n^20) := by
  exact ⟨n^25 + n^19, by ring⟩
