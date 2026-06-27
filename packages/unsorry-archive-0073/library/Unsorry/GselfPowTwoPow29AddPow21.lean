import Mathlib

theorem gself_pow_two_pow_29_add_pow_21 (n : ℤ) : (n^2) ∣ (n^29 + n^21) := by
  exact ⟨n^27 + n^19, by ring⟩
