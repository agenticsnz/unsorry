import Mathlib

theorem gself_pow_three_pow_27_add_pow_fifteen (n : ℤ) : (n^3) ∣ (n^27 + n^15) := by
  exact ⟨n^24 + n^12, by ring⟩
