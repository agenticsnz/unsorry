import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_two (n : ℤ) : (n^2) ∣ (n^19 + n^2) := by
  exact ⟨n^17 + 1, by ring⟩
