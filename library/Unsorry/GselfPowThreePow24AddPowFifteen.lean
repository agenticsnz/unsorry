import Mathlib

theorem gself_pow_three_pow_24_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^24 + n^15) := by
  exact ⟨n^21 + n^12, by ring⟩
