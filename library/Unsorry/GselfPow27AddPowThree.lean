import Mathlib

theorem gself_pow_27_add_pow_three (n : ℤ) : (n) ∣ (n^27 + n^3) := by
  exact ⟨n^26 + n^2, by ring⟩
