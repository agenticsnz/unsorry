import Mathlib

theorem gself_pow_four_pow_23_add_pow_ten (n : ℤ) : (n^4) ∣ (n^23 + n^10) := by
  exact ⟨n^19 + n^6, by ring⟩
