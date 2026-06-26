import Mathlib

theorem gself_pow_three_pow_21_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^21 + n^15) := by
  exact ⟨n^18 + n^12, by ring⟩
