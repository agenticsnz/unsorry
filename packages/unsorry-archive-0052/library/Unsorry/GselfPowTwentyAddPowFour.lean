import Mathlib

theorem gself_pow_twenty_add_pow_four (n : ℤ) : (n) ∣ (n^20 + n^4) := by
  exact ⟨n^19 + n^3, by ring⟩
