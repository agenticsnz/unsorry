import Mathlib

theorem gself_pow_two_pow_nine_add_pow_two (n : ℤ) : (n^2) ∣ (n^9 + n^2) := by
  exact ⟨n^7 + 1, by ring⟩
