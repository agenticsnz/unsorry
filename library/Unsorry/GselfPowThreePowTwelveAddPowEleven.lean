import Mathlib

theorem gself_pow_three_pow_twelve_add_pow_eleven (n : ℤ) : (n^3) ∣ (n^12 + n^11) := by
  exact ⟨n^9 + n^8, by ring⟩
