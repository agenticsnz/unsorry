import Mathlib

theorem gself_pow_21_add_pow_three (n : ℤ) : (n) ∣ (n^21 + n^3) := by
  exact ⟨n^20 + n^2, by ring⟩
