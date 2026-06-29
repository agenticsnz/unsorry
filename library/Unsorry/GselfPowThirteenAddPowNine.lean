import Mathlib

theorem gself_pow_thirteen_add_pow_nine (n : ℤ) : (n) ∣ (n^13 + n^9) := by
  exact ⟨n^12 + n^8, by ring⟩
