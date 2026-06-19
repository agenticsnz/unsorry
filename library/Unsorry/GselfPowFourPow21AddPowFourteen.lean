import Mathlib

theorem gself_pow_four_pow_21_add_pow_fourteen (n : ℤ) : (n^4) ∣ (n^21 + n^14) := by
  exact ⟨n^17 + n^10, by ring⟩
