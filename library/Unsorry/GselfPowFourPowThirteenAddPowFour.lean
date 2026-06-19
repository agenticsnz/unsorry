import Mathlib

theorem gself_pow_four_pow_thirteen_add_pow_four (n : ℤ) : (n^4) ∣ (n^13 + n^4) := by
  exact ⟨n^9 + 1, by ring⟩
