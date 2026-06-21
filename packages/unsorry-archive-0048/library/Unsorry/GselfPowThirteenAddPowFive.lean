import Mathlib

theorem gself_pow_thirteen_add_pow_five (n : ℤ) : (n) ∣ (n^13 + n^5) := by
  exact ⟨n^12 + n^4, by ring⟩
