import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_four (n : ℤ) : (n^3) ∣ (n^19 + n^4) := by
  exact ⟨n^16 + n, by ring⟩
