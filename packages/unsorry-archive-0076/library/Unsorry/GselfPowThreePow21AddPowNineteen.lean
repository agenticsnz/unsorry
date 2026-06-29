import Mathlib

theorem gself_pow_three_pow_21_add_pow_nineteen (n : ℤ) : (n^3) ∣ (n^21 + n^19) := by
  exact ⟨n^18 + n^16, by ring⟩
