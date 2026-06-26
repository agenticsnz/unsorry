import Mathlib

theorem gself_pow_two_pow_21_add_pow_two (n : ℤ) : (n^2) ∣ (n^21 + n^2) := by
  exact ⟨n^19 + 1, by ring⟩
