import Mathlib

theorem gself_pow_seven_add_pow_four (n : ℤ) : (n) ∣ (n^7 + n^4) := by
  exact ⟨n^6 + n^3, by ring⟩
