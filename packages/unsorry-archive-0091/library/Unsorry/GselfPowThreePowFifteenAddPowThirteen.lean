import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_thirteen (n : ℤ) : (n^3) ∣ (n^15 + n^13) := by
  exact ⟨n^12 + n^10, by ring⟩
