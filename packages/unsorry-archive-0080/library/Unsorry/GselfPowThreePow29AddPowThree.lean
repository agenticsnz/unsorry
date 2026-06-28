import Mathlib

theorem gself_pow_three_pow_29_add_pow_three (n : ℤ) : (n^3) ∣ (n^29 + n^3) := by
  exact ⟨n^26 + 1, by ring⟩
