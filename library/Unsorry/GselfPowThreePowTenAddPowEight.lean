import Mathlib

theorem gself_pow_three_pow_ten_add_pow_eight (n : ℤ) : (n^3) ∣ (n^10 + n^8) := by
  exact ⟨n^7 + n^5, by ring⟩
