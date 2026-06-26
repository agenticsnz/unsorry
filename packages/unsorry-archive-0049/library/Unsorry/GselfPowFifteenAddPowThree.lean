import Mathlib

theorem gself_pow_fifteen_add_pow_three (n : ℤ) : (n) ∣ (n^15 + n^3) := by
  exact ⟨n^14 + n^2, by ring⟩
