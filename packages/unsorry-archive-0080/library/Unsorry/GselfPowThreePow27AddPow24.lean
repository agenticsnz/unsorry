import Mathlib

theorem gself_pow_three_pow_27_add_pow_24 (n : ℤ) : (n^3) ∣ (n^27 + n^24) := by
  exact ⟨n^24 + n^21, by ring⟩
