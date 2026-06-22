import Mathlib

theorem gself_pow_twenty_add_pow_nineteen (n : ℤ) : (n) ∣ (n^20 + n^19) := by
  exact ⟨n^19 + n^18, by ring⟩
