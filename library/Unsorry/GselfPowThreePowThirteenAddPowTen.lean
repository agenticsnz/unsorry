import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_ten (n : ℤ) : (n^3) ∣ (n^13 + n^10) := by
  exact ⟨n^10 + n^7, by ring⟩
