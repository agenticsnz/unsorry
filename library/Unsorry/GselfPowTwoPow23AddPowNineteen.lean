import Mathlib

theorem gself_pow_two_pow_23_add_pow_nineteen (n : ℤ) : (n^2) ∣ (n^23 + n^19) := by
  exact ⟨n^21 + n^17, by ring⟩
