import Mathlib

theorem gself_pow_twenty_add_pow_fourteen (n : ℤ) : (n) ∣ (n^20 + n^14) := by
  exact ⟨n^19 + n^13, by ring⟩
