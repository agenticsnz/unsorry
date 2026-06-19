import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^19 + n^4) := by
  exact ⟨n^15 + 1, by ring⟩
