import Mathlib

theorem gself_pow_two_pow_29_add_pow_nineteen (n : ℤ) : (n^2) ∣ (n^29 + n^19) := by
  exact ⟨n^27 + n^17, by ring⟩
