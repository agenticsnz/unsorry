import Mathlib

theorem gself_pow_three_pow_sixteen_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^16 + n^15) := by
  exact ⟨n^13 + n^12, by ring⟩
