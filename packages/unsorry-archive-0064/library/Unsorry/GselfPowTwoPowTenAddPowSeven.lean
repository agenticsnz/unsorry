import Mathlib

theorem gself_pow_two_pow_ten_add_pow_seven (n : ℤ) : (n^2) ∣ (n^10 + n^7) := by
  exact ⟨n^8 + n^5, by ring⟩
