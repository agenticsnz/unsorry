import Mathlib

theorem gself_pow_two_pow_26_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^26 + n^14) := by
  exact ⟨n^24 + n^12, by ring⟩
