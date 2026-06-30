import Mathlib

theorem gself_pow_two_pow_26_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^26 + n^15) := by
  exact ⟨n^24 + n^13, by ring⟩
