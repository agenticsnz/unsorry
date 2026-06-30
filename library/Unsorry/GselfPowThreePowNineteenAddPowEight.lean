import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_eight (n : ℤ) : (n^3) ∣ (n^19 + n^8) := by
  exact ⟨n^16 + n^5, by ring⟩
