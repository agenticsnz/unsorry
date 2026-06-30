import Mathlib

theorem gself_pow_three_pow_sixteen_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^16 + n^14) := by
  exact ⟨n^13 + n^11, by ring⟩
