import Mathlib

theorem gself_pow_four_pow_nine_add_pow_four (n : ℤ) : (n^4) ∣ (n^9 + n^4) := by
  exact ⟨n^5 + 1, by ring⟩
