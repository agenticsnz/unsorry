import Mathlib

theorem gself_pow_three_pow_fifteen_add_pow_six (n : ℤ) : (n^3) ∣ (n^15 + n^6) := by
  exact ⟨n^12 + n^3, by ring⟩
