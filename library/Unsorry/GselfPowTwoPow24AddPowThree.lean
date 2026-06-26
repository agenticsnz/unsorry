import Mathlib

theorem gself_pow_two_pow_24_add_pow_three (n : ℤ) : (n^2) ∣ (n^24 + n^3) := by
  exact ⟨n^22 + n, by ring⟩
