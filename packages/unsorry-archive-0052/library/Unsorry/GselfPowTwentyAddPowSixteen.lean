import Mathlib

theorem gself_pow_twenty_add_pow_sixteen (n : ℤ) : (n) ∣ (n^20 + n^16) := by
  exact ⟨n^19 + n^15, by ring⟩
