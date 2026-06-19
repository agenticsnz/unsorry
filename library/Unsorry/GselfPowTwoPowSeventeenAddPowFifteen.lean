import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^17 + n^15) := by
  exact ⟨n^15 + n^13, by ring⟩
