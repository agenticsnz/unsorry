import Mathlib

theorem gself_pow_three_pow_four_add_pow_three (n : ℤ) : (n^3) ∣ (n^4 + n^3) := by
  exact ⟨n + 1, by ring⟩
