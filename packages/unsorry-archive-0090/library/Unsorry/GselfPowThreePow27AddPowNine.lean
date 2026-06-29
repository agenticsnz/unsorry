import Mathlib

theorem gself_pow_three_pow_27_add_pow_nine (n : ℤ) : (n^3) ∣ (n^27 + n^9) := by
  exact ⟨n^24 + n^6, by ring⟩
