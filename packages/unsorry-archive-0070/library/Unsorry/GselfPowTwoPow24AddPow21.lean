import Mathlib

theorem gself_pow_two_pow_24_add_pow_21 (n : ℤ) : (n^2) ∣ (n^24 + n^21) := by
  exact ⟨n^22 + n^19, by ring⟩
