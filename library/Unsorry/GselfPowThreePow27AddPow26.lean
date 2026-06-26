import Mathlib

theorem gself_pow_three_pow_27_add_pow_26 (n : ℤ) : (n^3) ∣ (n^27 + n^26) := by
  exact ⟨n^24 + n^23, by ring⟩
