import Mathlib

theorem gself_pow_three_pow_24_add_pow_five (n : ℤ) : (n^3) ∣ (n^24 + n^5) := by
  exact ⟨n^21 + n^2, by ring⟩
