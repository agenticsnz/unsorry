import Mathlib

theorem gself_pow_two_pow_22_add_pow_nine (n : ℤ) : (n^2) ∣ (n^22 + n^9) := by
  exact ⟨n^20 + n^7, by ring⟩
