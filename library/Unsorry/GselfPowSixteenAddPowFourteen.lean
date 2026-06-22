import Mathlib

theorem gself_pow_sixteen_add_pow_fourteen (n : ℤ) : (n) ∣ (n^16 + n^14) := by
  exact ⟨n^15 + n^13, by ring⟩
