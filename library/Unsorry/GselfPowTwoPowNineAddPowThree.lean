import Mathlib

theorem gself_pow_two_pow_nine_add_pow_three (n : ℤ) : (n^2) ∣ (n^9 + n^3) := by
  exact ⟨n^7 + n, by ring⟩
