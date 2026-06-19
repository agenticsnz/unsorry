import Mathlib

theorem gself_pow_three_pow_26_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^26 + n^14) := by
  exact ⟨n^23 + n^11, by ring⟩
