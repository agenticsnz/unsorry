import Mathlib

theorem gself_pow_twenty_add_pow_five (n : ℤ) : (n) ∣ (n^20 + n^5) := by
  exact ⟨n^19 + n^4, by ring⟩
