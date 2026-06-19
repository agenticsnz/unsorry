import Mathlib

theorem gself_pow_three_pow_24_add_pow_eleven (n : ℤ) : (n^3) ∣ (n^24 + n^11) := by
  exact ⟨n^21 + n^8, by ring⟩
