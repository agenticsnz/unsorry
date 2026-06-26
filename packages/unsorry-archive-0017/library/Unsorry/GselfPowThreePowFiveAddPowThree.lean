import Mathlib

theorem gself_pow_three_pow_five_add_pow_three (n : ℤ) : (n^3) ∣ (n^5 + n^3) := by
  exact ⟨n^2 + 1, by ring⟩
