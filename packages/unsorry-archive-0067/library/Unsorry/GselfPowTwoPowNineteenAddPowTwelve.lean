import Mathlib

theorem gself_pow_two_pow_nineteen_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^19 + n^12) := by
  exact ⟨n^17 + n^10, by ring⟩
