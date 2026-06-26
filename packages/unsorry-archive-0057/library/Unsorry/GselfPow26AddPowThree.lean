import Mathlib

theorem gself_pow_26_add_pow_three (n : ℤ) : (n) ∣ (n^26 + n^3) := by
  exact ⟨n^25 + n^2, by ring⟩
