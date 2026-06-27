import Mathlib

theorem gself_pow_two_pow_24_add_pow_fourteen (n : ℤ) : (n^2) ∣ (n^24 + n^14) := by
  exact ⟨n^22 + n^12, by ring⟩
