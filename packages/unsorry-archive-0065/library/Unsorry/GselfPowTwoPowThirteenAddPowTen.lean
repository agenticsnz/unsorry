import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_ten (n : ℤ) : (n^2) ∣ (n^13 + n^10) := by
  exact ⟨n^11 + n^8, by ring⟩
