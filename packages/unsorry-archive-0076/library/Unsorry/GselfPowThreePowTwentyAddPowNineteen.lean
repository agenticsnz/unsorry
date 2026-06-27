import Mathlib

theorem gself_pow_three_pow_twenty_add_pow_nineteen (n : ℤ) : (n^3) ∣ (n^20 + n^19) := by
  exact ⟨n^17 + n^16, by ring⟩
