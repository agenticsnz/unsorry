import Mathlib

theorem gself_pow_three_pow_28_add_pow_nineteen (n : ℤ) : (n^3) ∣ (n^28 + n^19) := by
  exact ⟨n^25 + n^16, by ring⟩
