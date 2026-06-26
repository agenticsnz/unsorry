import Mathlib

theorem gself_pow_two_pow_fifteen_add_pow_six (n : ℤ) : (n^2) ∣ (n^15 + n^6) := by
  exact ⟨n^13 + n^4, by ring⟩
