import Mathlib

theorem gself_pow_22_add_pow_three (n : ℤ) : (n) ∣ (n^22 + n^3) := by
  exact ⟨n^21 + n^2, by ring⟩
