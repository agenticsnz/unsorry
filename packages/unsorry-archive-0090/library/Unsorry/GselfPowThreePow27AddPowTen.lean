import Mathlib

theorem gself_pow_three_pow_27_add_pow_ten (n : ℤ) : (n^3) ∣ (n^27 + n^10) := by
  exact ⟨n^24 + n^7, by ring⟩
