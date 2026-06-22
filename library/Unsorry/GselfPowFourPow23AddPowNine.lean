import Mathlib

theorem gself_pow_four_pow_23_add_pow_nine (n : ℤ) : (n^4) ∣ (n^23 + n^9) := by
  exact ⟨n^19 + n^5, by ring⟩
