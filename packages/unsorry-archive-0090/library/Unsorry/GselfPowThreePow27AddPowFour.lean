import Mathlib

theorem gself_pow_three_pow_27_add_pow_four (n : ℤ) : (n^3) ∣ (n^27 + n^4) := by
  exact ⟨n^24 + n, by ring⟩
