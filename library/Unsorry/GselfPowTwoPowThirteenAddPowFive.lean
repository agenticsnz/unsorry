import Mathlib

theorem gself_pow_two_pow_thirteen_add_pow_five (n : ℤ) : (n^2) ∣ (n^13 + n^5) := by
  exact ⟨n^11 + n^3, by ring⟩
