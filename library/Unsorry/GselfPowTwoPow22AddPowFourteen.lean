import Mathlib

theorem gself_pow_two_pow_22_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^22 + n^14) := by
  exact ⟨n^20 + n^12, by ring⟩
