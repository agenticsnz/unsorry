import Mathlib

theorem gself_pow_four_pow_ten_add_pow_nine (n : ℤ) : (n^4) ∣ (n^10 + n^9) := by
  exact ⟨n^6 + n^5, by ring⟩
