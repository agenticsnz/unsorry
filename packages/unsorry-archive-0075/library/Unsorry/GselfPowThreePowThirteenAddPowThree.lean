import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_three (n : ℤ) : (n^3) ∣ (n^13 + n^3) := by
  exact ⟨n^10 + 1, by ring⟩
