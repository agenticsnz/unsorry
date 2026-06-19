import Mathlib

theorem gself_pow_26_add_pow_fourteen (n : ℤ) : (n) ∣ (n^26 + n^14) := by
  exact ⟨n^25 + n^13, by ring⟩
