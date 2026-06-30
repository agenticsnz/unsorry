import Mathlib

theorem gself_pow_three_pow_nineteen_add_pow_six (n : ℤ) : (n^3) ∣ (n^19 + n^6) := by
  exact ⟨n^16 + n^3, by ring⟩
