import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_eleven (n : ℤ) : (n^2) ∣ (n^13 + n^11) := by
  exact ⟨n^11 + n^9, by ring⟩
