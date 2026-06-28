import Mathlib

theorem gself_pow_three_pow_27_add_pow_seven (n : ℤ) : (n^3) ∣ (n^27 + n^7) := by
  exact ⟨n^24 + n^4, by ring⟩
