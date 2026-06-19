import Mathlib

theorem gself_pow_four_pow_nine_add_pow_seven (n : ℤ) : (n^4) ∣ (n^9 + n^7) := by
  exact ⟨n^5 + n^3, by ring⟩
