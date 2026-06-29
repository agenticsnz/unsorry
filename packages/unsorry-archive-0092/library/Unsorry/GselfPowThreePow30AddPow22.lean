import Mathlib

theorem gself_pow_three_pow_30_add_pow_22 (n : ℤ) : (n^3) ∣ (n^30 + n^22) := by
  exact ⟨n^27 + n^19, by ring⟩
