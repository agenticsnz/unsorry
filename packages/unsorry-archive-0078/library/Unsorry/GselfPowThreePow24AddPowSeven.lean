import Mathlib

theorem gself_pow_three_pow_24_add_pow_seven (n : ℤ) : (n^3) ∣ (n^24 + n^7) := by
  exact ⟨n^21 + n^4, by ring⟩
