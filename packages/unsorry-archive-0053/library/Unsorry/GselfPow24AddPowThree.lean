import Mathlib

theorem gself_pow_24_add_pow_three (n : ℤ) : (n) ∣ (n^24 + n^3) := by
  exact ⟨n^23 + n^2, by ring⟩
