import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^19 + n^16) := by
  exact ⟨n^16 + n^13, by ring⟩
