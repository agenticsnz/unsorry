import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_fifteen (n : ℤ) : (n^4) ∣ (n^19 + n^15) := by
  exact ⟨n^15 + n^11, by ring⟩
