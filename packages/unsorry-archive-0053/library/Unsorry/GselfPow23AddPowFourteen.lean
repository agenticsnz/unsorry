import Mathlib

theorem gself_pow_23_add_pow_fourteen (n : ℤ) : (n) ∣ (n^23 + n^14) := by
  exact ⟨n^22 + n^13, by ring⟩
