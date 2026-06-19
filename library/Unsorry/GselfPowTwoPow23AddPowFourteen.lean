import Mathlib

theorem gself_pow_two_pow_23_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^23 + n^14) := by
  exact ⟨n^21 + n^12, by ring⟩
