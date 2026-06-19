import Mathlib

theorem gself_pow_twenty_add_pow_fifteen (n : ℤ) : (n) ∣ (n^20 + n^15) := by
  exact ⟨n^19 + n^14, by ring⟩
