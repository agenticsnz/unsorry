import Mathlib

theorem gself_pow_four_pow_fifteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^15 + n^4) := by
  exact ⟨n^11 + 1, by ring⟩
