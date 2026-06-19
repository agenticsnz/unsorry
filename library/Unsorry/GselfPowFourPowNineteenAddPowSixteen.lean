import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_sixteen (n : ℤ) : (n^4) ∣ (n^19 + n^16) := by
  exact ⟨n^15 + n^12, by ring⟩
