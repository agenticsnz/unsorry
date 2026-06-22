import Mathlib

theorem gself_pow_three_pow_30_add_pow_nineteen (n : ℤ) : (n^3) ∣ (n^30 + n^19) := by
  exact ⟨n^27 + n^16, by ring⟩
