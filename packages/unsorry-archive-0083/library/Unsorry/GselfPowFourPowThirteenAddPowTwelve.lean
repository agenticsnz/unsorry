import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_twelve (n : ℤ) : (n^4) ∣ (n^13 + n^12) := by
  exact ⟨n^9 + n^8, by ring⟩
