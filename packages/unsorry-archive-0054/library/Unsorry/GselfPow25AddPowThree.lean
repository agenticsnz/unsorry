import Mathlib

theorem gself_pow_25_add_pow_three (n : ℤ) : (n) ∣ (n^25 + n^3) := by
  exact ⟨n^24 + n^2, by ring⟩
