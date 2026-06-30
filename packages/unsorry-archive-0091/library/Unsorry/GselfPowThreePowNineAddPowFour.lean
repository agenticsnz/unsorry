import Mathlib

theorem gself_pow_three_pow_nine_add_pow_four (n : ℤ) : (n^3) ∣ (n^9 + n^4) := by
  exact ⟨n^6 + n, by ring⟩
