import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_eight (n : ℤ) : (n^2) ∣ (n^19 + n^8) := by
  exact ⟨n^17 + n^6, by ring⟩
