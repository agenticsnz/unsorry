import Mathlib

theorem gself_pow_two_pow_24_add_pow_five (n : ℤ) : (n^2) ∣ (n^24 + n^5) := by
  exact ⟨n^22 + n^3, by ring⟩
