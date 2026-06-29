import Mathlib

theorem gself_pow_four_pow_22_add_pow_nineteen (n : ℤ) : (n^4) ∣ (n^22 + n^19) := by
  exact ⟨n^18 + n^15, by ring⟩
