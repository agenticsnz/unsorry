import Mathlib

theorem gself_pow_nine_add_pow_three (n : ℤ) : (n) ∣ (n^9 + n^3) := by
  exact ⟨n^8 + n^2, by ring⟩
