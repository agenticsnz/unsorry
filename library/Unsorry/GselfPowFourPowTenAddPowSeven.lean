import Mathlib

theorem gself_pow_four_pow_ten_add_pow_seven (n : ℤ) : (n^4) ∣ (n^10 + n^7) := by
  exact ⟨n^6 + n^3, by ring⟩
