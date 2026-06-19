import Mathlib

theorem gself_pow_two_pow_26_add_pow_21 (n : ℤ) : (n^2) ∣ (n^26 + n^21) := by
  exact ⟨n^24 + n^19, by ring⟩
