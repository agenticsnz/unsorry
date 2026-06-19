import Mathlib

theorem gself_pow_three_pow_thirteen_add_pow_four (n : ℤ) : (n^3) ∣ (n^13 + n^4) := by
  exact ⟨n^10 + n, by ring⟩
