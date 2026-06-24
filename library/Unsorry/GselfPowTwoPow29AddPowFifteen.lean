import Mathlib

theorem gself_pow_two_pow_29_add_pow_fifteen (n : ℤ) : (n^2) ∣ (n^29 + n^15) := by
  exact ⟨n^27 + n^13, by ring⟩
