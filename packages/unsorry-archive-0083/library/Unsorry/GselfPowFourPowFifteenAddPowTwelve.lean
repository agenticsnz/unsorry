import Mathlib

theorem gself_pow_four_pow_fifteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^15 + n^12) := by
  exact ⟨n^11 + n^8, by ring⟩
