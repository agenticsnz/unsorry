import Mathlib

theorem gself_pow_thirteen_add_pow_twelve (n : ℤ) : (n) ∣ (n^13 + n^12) := by
  exact ⟨n^12 + n^11, by ring⟩
