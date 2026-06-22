import Mathlib

theorem gself_pow_three_pow_24_add_pow_sixteen (n : ℤ) : (n^3) ∣ (n^24 + n^16) := by
  exact ⟨n^21 + n^13, by ring⟩
