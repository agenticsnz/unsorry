import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^19 + n^11) := by
  exact ⟨n^17 + n^9, by ring⟩
