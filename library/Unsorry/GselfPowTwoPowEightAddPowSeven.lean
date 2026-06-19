import Mathlib

theorem gself_pow_two_pow_eight_add_pow_seven (n : ℤ) : (n^2) ∣ (n^8 + n^7) := by
  exact ⟨n^6 + n^5, by ring⟩
