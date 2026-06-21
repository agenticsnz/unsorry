import Mathlib

theorem gself_pow_ten_add_pow_seven (n : ℤ) : (n) ∣ (n^10 + n^7) := by
  exact ⟨n^9 + n^6, by ring⟩
