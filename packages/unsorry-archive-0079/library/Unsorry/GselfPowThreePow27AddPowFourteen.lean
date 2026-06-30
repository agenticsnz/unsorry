import Mathlib

theorem gself_pow_three_pow_27_add_pow_fourteen (n : ℤ) : (n^3) ∣ (n^27 + n^14) := by
  exact ⟨n^24 + n^11, by ring⟩
