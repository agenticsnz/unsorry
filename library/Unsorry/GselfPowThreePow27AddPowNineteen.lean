import Mathlib

theorem gself_pow_three_pow_27_add_pow_nineteen (n : ℤ) : (n^3) ∣ (n^27 + n^19) := by
  exact ⟨n^24 + n^16, by ring⟩
