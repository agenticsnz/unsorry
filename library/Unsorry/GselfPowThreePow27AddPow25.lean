import Mathlib

theorem gself_pow_three_pow_27_add_pow_25 (n : ℤ) : (n^3) ∣ (n^27 + n^25) := by
  exact ⟨n^24 + n^22, by ring⟩
