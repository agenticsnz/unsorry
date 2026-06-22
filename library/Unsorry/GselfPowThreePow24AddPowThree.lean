import Mathlib

theorem gself_pow_three_pow_24_add_pow_three (n : ℤ) : (n^3) ∣ (n^24 + n^3) := by
  exact ⟨n^21 + 1, by ring⟩
