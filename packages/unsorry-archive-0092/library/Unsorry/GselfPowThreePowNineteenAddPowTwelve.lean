import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^19 + n^12) := by
  exact ⟨n^16 + n^9, by ring⟩
