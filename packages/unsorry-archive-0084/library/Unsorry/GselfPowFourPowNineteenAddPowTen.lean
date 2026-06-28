import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_ten (n : ℤ) : (n^4) ∣ (n^19 + n^10) := by
  exact ⟨n^15 + n^6, by ring⟩
