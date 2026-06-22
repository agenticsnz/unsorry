import Mathlib

theorem gself_pow_21_add_pow_fourteen (n : ℤ) : (n) ∣ (n^21 + n^14) := by
  exact ⟨n^20 + n^13, by ring⟩
