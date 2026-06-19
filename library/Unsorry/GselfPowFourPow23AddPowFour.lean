import Mathlib

theorem gself_pow_four_pow_23_add_pow_four (n : ℤ) : (n^4) ∣ (n^23 + n^4) := by
  exact ⟨n^19 + 1, by ring⟩
