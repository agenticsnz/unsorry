import Mathlib

theorem gself_pow_twenty_add_pow_eleven (n : ℤ) : (n) ∣ (n^20 + n^11) := by
  exact ⟨n^19 + n^10, by ring⟩
