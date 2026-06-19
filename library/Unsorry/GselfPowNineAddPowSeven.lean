import Mathlib

theorem gself_pow_nine_add_pow_seven (n : ℤ) : (n) ∣ (n^9 + n^7) := by
  exact ⟨n^8 + n^6, by ring⟩
