import Mathlib

theorem gself_pow_two_pow_25_add_pow_nineteen (n : ℤ) : (n^2) ∣ (n^25 + n^19) := by
  exact ⟨n^23 + n^17, by ring⟩
