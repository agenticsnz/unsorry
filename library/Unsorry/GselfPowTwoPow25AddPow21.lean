import Mathlib

theorem gself_pow_two_pow_25_add_pow_21 (n : ℤ) : (n^2) ∣ (n^25 + n^21) := by
  exact ⟨n^23 + n^19, by ring⟩
