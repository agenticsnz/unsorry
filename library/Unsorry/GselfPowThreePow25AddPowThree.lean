import Mathlib

theorem gself_pow_three_pow_25_add_pow_three (n : ℤ) : (n^3) ∣ (n^25 + n^3) := by
  exact ⟨n^22 + 1, by ring⟩
