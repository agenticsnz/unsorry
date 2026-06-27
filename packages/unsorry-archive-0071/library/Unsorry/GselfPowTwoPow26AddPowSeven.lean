import Mathlib

theorem gself_pow_two_pow_26_add_pow_seven (n : ℤ) : (n^2) ∣ (n^26 + n^7) := by
  exact ⟨n^24 + n^5, by ring⟩
