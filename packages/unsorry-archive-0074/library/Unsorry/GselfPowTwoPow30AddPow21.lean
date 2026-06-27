import Mathlib

theorem gself_pow_two_pow_30_add_pow_21 (n : ℤ) : (n^2) ∣ (n^30 + n^21) := by
  exact ⟨n^28 + n^19, by ring⟩
