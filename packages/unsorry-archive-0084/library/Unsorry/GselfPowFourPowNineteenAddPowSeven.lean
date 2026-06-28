import Mathlib

theorem gself_pow_four_pow_nineteen_add_pow_seven (n : ℤ) : (n^4) ∣ (n^19 + n^7) := by
  exact ⟨n^15 + n^3, by ring⟩
