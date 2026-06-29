import Mathlib

theorem gself_pow_two_pow_27_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^27 + n^15) := by
  exact ⟨n^25 + n^13, by ring⟩
