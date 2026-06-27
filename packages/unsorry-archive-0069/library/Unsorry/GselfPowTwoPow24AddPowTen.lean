import Mathlib

theorem gself_pow_two_pow_24_add_pow_ten (n : ℤ) : (n^2) ∣ (n^24 + n^10) := by
  exact ⟨n^22 + n^8, by ring⟩
