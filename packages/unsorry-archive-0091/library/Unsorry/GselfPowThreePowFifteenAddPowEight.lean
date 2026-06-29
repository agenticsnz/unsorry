import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_eight (n : ℤ) : (n^3) ∣ (n^15 + n^8) := by
  exact ⟨n^12 + n^5, by ring⟩
