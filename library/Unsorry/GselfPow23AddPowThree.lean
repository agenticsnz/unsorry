import Mathlib

theorem gself_pow_23_add_pow_three (n : ℤ) : (n) ∣ (n^23 + n^3) := by
  exact ⟨n^22 + n^2, by ring⟩
