import Mathlib

theorem gself_pow_three_pow_22_add_pow_four (n : ℤ) : (n^3) ∣ (n^22 + n^4) := by
  exact ⟨n^19 + n, by ring⟩
