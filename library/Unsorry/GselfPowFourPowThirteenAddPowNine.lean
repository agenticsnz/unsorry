import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_nine (n : ℤ) : (n^4) ∣ (n^13 + n^9) := by
  exact ⟨n^9 + n^5, by ring⟩
