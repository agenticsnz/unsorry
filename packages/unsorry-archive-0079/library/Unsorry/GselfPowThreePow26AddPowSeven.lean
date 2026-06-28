import Mathlib

theorem gself_pow_three_pow_26_add_pow_seven (n : ℤ) : (n^3) ∣ (n^26 + n^7) := by
  exact ⟨n^23 + n^4, by ring⟩
