import Mathlib

theorem gself_pow_two_pow_27_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^27 + n^14) := by
  exact ⟨n^25 + n^12, by ring⟩
