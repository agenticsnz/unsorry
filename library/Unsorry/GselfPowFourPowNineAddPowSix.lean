import Mathlib

theorem gself_pow_four_pow_nine_add_pow_six (n : ℤ) : (n^4) ∣ (n^9 + n^6) := by
  exact ⟨n^5 + n^2, by ring⟩
