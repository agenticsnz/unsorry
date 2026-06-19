import Mathlib

theorem gself_pow_three_pow_26_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^26 + n^15) := by
  exact ⟨n^23 + n^12, by ring⟩
