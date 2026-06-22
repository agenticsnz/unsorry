import Mathlib

theorem gself_pow_twenty_add_pow_eight (n : ℤ) : (n) ∣ (n^20 + n^8) := by
  exact ⟨n^19 + n^7, by ring⟩
