import Mathlib

theorem gself_pow_three_pow_nine_add_pow_three (n : ℤ) : (n^3) ∣ (n^9 + n^3) := by
  exact ⟨n^6 + 1, by ring⟩
