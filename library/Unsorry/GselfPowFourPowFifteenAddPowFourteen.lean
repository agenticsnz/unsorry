import Mathlib

theorem gself_pow_four_pow_fifteen_add_pow_fourteen (n : ℤ) : (n^4) ∣ (n^15 + n^14) := by
  exact ⟨n^11 + n^10, by ring⟩
