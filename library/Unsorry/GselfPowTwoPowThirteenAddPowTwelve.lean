import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^13 + n^12) := by
  exact ⟨n^11 + n^10, by ring⟩
