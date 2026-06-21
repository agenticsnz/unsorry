import Mathlib

theorem gself_pow_thirteen_add_pow_ten (n : ℤ) : (n) ∣ (n^13 + n^10) := by
  exact ⟨n^12 + n^9, by ring⟩
