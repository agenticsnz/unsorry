import Mathlib

theorem gself_pow_thirteen_add_pow_three (n : ℤ) : (n) ∣ (n^13 + n^3) := by
  exact ⟨n^12 + n^2, by ring⟩
