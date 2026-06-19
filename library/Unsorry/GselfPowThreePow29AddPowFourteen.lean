import Mathlib

theorem gself_pow_three_pow_29_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^29 + n^14) := by
  exact ⟨n^26 + n^11, by ring⟩
