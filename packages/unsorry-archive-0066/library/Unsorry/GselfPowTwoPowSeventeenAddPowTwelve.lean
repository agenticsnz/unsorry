import Mathlib

theorem gself_pow_two_pow_seventeen_add_pow_twelve (n : ℤ) : (n^2) ∣ (n^17 + n^12) := by
  exact ⟨n^15 + n^10, by ring⟩
