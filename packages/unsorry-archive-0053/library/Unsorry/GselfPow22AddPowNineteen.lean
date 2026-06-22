import Mathlib

theorem gself_pow_22_add_pow_nineteen (n : ℤ) : (n) ∣ (n^22 + n^19) := by
  exact ⟨n^21 + n^18, by ring⟩
