import Mathlib

theorem gself_pow_twenty_add_pow_twelve (n : ℤ) : (n) ∣ (n^20 + n^12) := by
  exact ⟨n^19 + n^11, by ring⟩
