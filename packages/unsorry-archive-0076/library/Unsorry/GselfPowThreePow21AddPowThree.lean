import Mathlib

theorem gself_pow_three_pow_21_add_pow_three (n : ℤ) : (n^3) ∣ (n^21 + n^3) := by
  exact ⟨n^18 + 1, by ring⟩
