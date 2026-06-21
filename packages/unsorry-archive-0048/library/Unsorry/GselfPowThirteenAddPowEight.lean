import Mathlib

theorem gself_pow_thirteen_add_pow_eight (n : ℤ) : (n) ∣ (n^13 + n^8) := by
  exact ⟨n^12 + n^7, by ring⟩
