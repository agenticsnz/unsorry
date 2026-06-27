import Mathlib

theorem gself_pow_three_pow_ten_add_pow_seven (n : ℤ) : (n^3) ∣ (n^10 + n^7) := by
  exact ⟨n^7 + n^4, by ring⟩
