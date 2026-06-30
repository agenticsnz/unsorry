import Mathlib

theorem gself_pow_three_pow_29_add_pow_twelve (n : ℤ) : (n^3) ∣ (n^29 + n^12) := by
  exact ⟨n^26 + n^9, by ring⟩
