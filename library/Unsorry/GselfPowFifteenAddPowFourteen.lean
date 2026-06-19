import Mathlib

theorem gself_pow_fifteen_add_pow_fourteen (n : ℤ) : (n) ∣ (n^15 + n^14) := by
  exact ⟨n^14 + n^13, by ring⟩
