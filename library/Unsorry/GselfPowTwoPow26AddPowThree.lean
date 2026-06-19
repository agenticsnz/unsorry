import Mathlib

theorem gself_pow_two_pow_26_add_pow_three (n : ℤ) : (n^2) ∣ (n^26 + n^3) := by
  exact ⟨n^24 + n, by ring⟩
