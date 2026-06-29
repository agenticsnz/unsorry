import Mathlib

theorem gself_pow_two_pow_seven_add_pow_three (n : ℤ) : (n^2) ∣ (n^7 + n^3) := by
  exact ⟨n^5 + n, by ring⟩
