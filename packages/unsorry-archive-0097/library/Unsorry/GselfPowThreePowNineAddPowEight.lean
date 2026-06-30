import Mathlib

theorem gself_pow_three_pow_nine_add_pow_eight (n : ℤ) : (n^3) ∣ (n^9 + n^8) := by
  exact ⟨n^6 + n^5, by ring⟩
