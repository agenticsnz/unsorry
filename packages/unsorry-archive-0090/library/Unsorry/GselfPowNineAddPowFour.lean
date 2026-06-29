import Mathlib

theorem gself_pow_nine_add_pow_four (n : ℤ) : (n) ∣ (n^9 + n^4) := by
  exact ⟨n^8 + n^3, by ring⟩
