import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_four (n : ℤ) : (n^2) ∣ (n^19 + n^4) := by
  exact ⟨n^17 + n^2, by ring⟩
