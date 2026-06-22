import Mathlib

theorem gself_pow_twelve_add_pow_three (n : ℤ) : (n) ∣ (n^12 + n^3) := by
  exact ⟨n^11 + n^2, by ring⟩
