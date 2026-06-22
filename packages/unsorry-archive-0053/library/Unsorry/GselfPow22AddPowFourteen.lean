import Mathlib

theorem gself_pow_22_add_pow_fourteen (n : ℤ) : (n) ∣ (n^22 + n^14) := by
  exact ⟨n^21 + n^13, by ring⟩
