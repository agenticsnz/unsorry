import Mathlib

theorem gself_pow_two_pow_seven_add_pow_five (n : ℤ) : (n^2) ∣ (n^7 + n^5) := by
  exact ⟨n^5 + n^3, by ring⟩
