import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_nine (n : ℤ) : (n^3) ∣ (n^13 + n^9) := by
  exact ⟨n^10 + n^6, by ring⟩
