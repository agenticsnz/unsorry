import Mathlib

theorem gself_pow_two_pow_28_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^28 + n^15) := by
  exact ⟨n^26 + n^13, by ring⟩
