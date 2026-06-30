import Mathlib

theorem gself_pow_two_pow_29_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^29 + n^14) := by
  exact ⟨n^27 + n^12, by ring⟩
