import Mathlib

theorem gself_pow_four_pow_eight_add_pow_seven (n : ℤ) : (n^4) ∣ (n^8 + n^7) := by
  exact ⟨n^4 + n^3, by ring⟩
