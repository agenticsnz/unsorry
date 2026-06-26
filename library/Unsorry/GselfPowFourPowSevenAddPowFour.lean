import Mathlib

theorem gself_pow_four_pow_seven_add_pow_four (n : ℤ) : (n^4) ∣ (n^7 + n^4) := by
  exact ⟨n^3 + 1, by ring⟩
