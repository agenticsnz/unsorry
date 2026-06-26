import Mathlib

theorem gself_pow_three_pow_26_add_pow_three (n : ℤ) : (n^3) ∣ (n^26 + n^3) := by
  exact ⟨n^23 + 1, by ring⟩
