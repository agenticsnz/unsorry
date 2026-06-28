import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^19 + n^12) := by
  exact ⟨n^15 + n^8, by ring⟩
