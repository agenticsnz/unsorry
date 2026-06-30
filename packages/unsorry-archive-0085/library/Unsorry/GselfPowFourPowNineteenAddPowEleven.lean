import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_eleven (n : ℤ) : (n^4) ∣ (n^19 + n^11) := by
  exact ⟨n^15 + n^7, by ring⟩
