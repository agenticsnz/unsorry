import Mathlib

theorem gself_pow_three_pow_24_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^24 + n^14) := by
  exact ⟨n^21 + n^11, by ring⟩
