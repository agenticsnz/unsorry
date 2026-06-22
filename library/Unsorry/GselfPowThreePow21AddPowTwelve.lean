import Mathlib

theorem gself_pow_three_pow_21_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^21 + n^12) := by
  exact ⟨n^18 + n^9, by ring⟩
