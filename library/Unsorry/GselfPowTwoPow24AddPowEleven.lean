import Mathlib

theorem gself_pow_two_pow_24_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^24 + n^11) := by
  exact ⟨n^22 + n^9, by ring⟩
