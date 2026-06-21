import Mathlib

theorem gself_pow_four_add_pow_three (n : ℤ) : (n) ∣ (n^4 + n^3) := by
  exact ⟨n^3 + n^2, by ring⟩
