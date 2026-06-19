import Mathlib

theorem gself_pow_two_pow_seven_add_pow_two (n : ℤ) : (n^2) ∣ (n^7 + n^2) := by
  exact ⟨n^5 + 1, by ring⟩
