import Mathlib

theorem gself_pow_two_pow_22_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^22 + n^12) := by
  exact ⟨n^20 + n^10, by ring⟩
