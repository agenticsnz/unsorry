import Mathlib

theorem gself_pow_twenty_add_pow_ten (n : ℤ) : (n) ∣ (n^20 + n^10) := by
  exact ⟨n^19 + n^9, by ring⟩
