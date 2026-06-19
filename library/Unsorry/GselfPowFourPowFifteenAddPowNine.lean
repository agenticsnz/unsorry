import Mathlib

theorem gself_pow_four_pow_fifteen_add_pow_nine (n : ℤ) : (n^4) ∣ (n^15 + n^9) := by
  exact ⟨n^11 + n^5, by ring⟩
